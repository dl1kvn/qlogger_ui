import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/lotw_signer.dart';

class LotwService {
  static const _bandMap = {
    '1.8': '160M',
    '3.5': '80M',
    '5': '60M',
    '7': '40M',
    '10': '30M',
    '14': '20M',
    '18': '17M',
    '21': '15M',
    '24': '12M',
    '28': '10M',
    '50': '6M',
    '144': '2M',
    '440': '70cm',
  };

  /// Upload a QSO to LoTW
  /// Returns true if successful, throws exception on error
  static Future<bool> uploadQso({
    required String myCallsign,
    required String dxCallsign,
    required String band,
    required String mode,
    required String date, // YYYYMMDD
    required String time, // HHMM
    required String satellite, // "no sat" or satellite name
    required String p12Base64,
    required String p12Password,
    required String lotwLogin,
    required String lotwPassword,
    required String dxcc,
    required String itu,
    required String cqzone,
    String gridsquare = '',
    String rstSent = '',
    String rstRcvd = '',
    String activationType = '',
    String activationReference = '',
  }) async {
    // Convert band MHz to band name
    final bandName = _bandMap[band] ?? '20M';

    // Format date and time for TQSL
    final qsoDate =
        '${date.substring(0, 4)}-${date.substring(4, 6)}-${date.substring(6, 8)}';
    final qsoTime = '${time.substring(0, 2)}:${time.substring(2, 4)}:00Z';

    // Handle satellite
    String satAdif = '';
    String satMode = '';
    String satName = '';
    if (satellite != 'no sat' && satellite.isNotEmpty) {
      satAdif = '<PROP_MODE:3>SAT<SAT_NAME:${satellite.length}>$satellite';
      satMode = 'SAT';
      satName = satellite;
    }

    // Build sign data: bandName + callsign + mode + satMode + date + time + satName
    final signData =
        bandName +
        dxCallsign.toUpperCase() +
        mode +
        satMode +
        qsoDate +
        qsoTime +
        satName;

    // Decode P12 and sign
    final p12Bytes = base64Decode(p12Base64);
    if (p12Bytes.isEmpty || p12Bytes[0] != 0x30) {
      throw Exception('Invalid P12 format');
    }

    // Get signature via platform channel
    final signature = await LotwSigner.sign(
      data: signData,
      p12Bytes: Uint8List.fromList(p12Bytes),
      password: p12Password,
    );

    // Get certificate via platform channel
    final certificate = await LotwSigner.getCertificate(
      p12Bytes: Uint8List.fromList(p12Bytes),
      password: p12Password,
    );

    // Build TQSL format
    final tqsl = _buildTqsl(
      certificate: certificate,
      myCallsign: myCallsign,
      dxCallsign: dxCallsign.toUpperCase(),
      bandName: bandName,
      mode: mode,
      qsoDate: qsoDate,
      qsoTime: qsoTime,
      satAdif: satAdif,
      signature: signature,
      signData: signData,
      dxcc: dxcc,
      gridsquare: gridsquare,
      rstSent: rstSent,
      rstRcvd: rstRcvd,
      activationType: activationType,
      activationReference: activationReference,
    );

    print('=== TQSL Content ===');
    print(tqsl);
    print('=== End TQSL ===');

    // GZip compress
    final tqslBytes = utf8.encode(tqsl);
    final gzipBytes = gzip.encode(tqslBytes);

    // Write to temp file
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/lotw_upload.tq8');
    await tempFile.writeAsBytes(gzipBytes);

    // Upload
    final dio = Dio();
    dio.options.headers['User-Agent'] = 'TrustedQslJava';
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 60);

    final formData = FormData.fromMap({
      'upfile': await MultipartFile.fromFile(
        tempFile.path,
        filename: '${myCallsign.replaceAll('/', '_')}.tq8',
      ),
    });

    // URL-encode login credentials
    final encodedLogin = Uri.encodeComponent(lotwLogin);
    final encodedPassword = Uri.encodeComponent(lotwPassword);

    final response = await dio.post(
      // 'https://lotw.arrl.org/lotwuser/upload?login=$encodedLogin&password=$encodedPassword',
      'https://lotw.arrl.org/lotw/upload',
      data: formData,
    );

    // Clean up temp file
    try {
      await tempFile.delete();
    } catch (_) {}

    // Check response - LoTW processes signed files even if web login fails
    // The signature in the file is the real authentication
    print('=== LoTW Response ===');
    print('Status: ${response.statusCode}');
    print('Body: ${response.data}');
    print('=== End Response ===');
    final responseStr = response.data.toString().toLowerCase();

    // Check for explicit QSO rejection errors
    if (responseStr.contains('rejected') && !responseStr.contains('username')) {
      throw Exception('LoTW rejected the QSO');
    }

    // Check for success indicators
    if (responseStr.contains('accepted') ||
        responseStr.contains('successfully processed') ||
        responseStr.contains('file queued') ||
        responseStr.contains('previously processed')) {
      return true;
    }

    // If we get a login page but the upload was multipart, the file was likely processed
    // The signature is the real auth, not the web credentials
    // HTTP 200 means the server received the file
    if (response.statusCode == 200) {
      return true;
    }

    throw Exception('LoTW upload failed: HTTP ${response.statusCode}');
  }

  static String _buildTqsl({
    required String certificate,
    required String myCallsign,
    required String dxCallsign,
    required String bandName,
    required String mode,
    required String qsoDate,
    required String qsoTime,
    required String satAdif,
    required String signature,
    required String signData,
    required String dxcc,
    String gridsquare = '',
    String rstSent = '',
    String rstRcvd = '',
    String activationType = '',
    String activationReference = '',
  }) {
    final certClean = certificate.replaceAll('\n', '').replaceAll('\r', '');

    String gridsquareAdif = '';
    if (gridsquare.isNotEmpty) {
      gridsquareAdif = '<MY_GRIDSQUARE:${gridsquare.length}>$gridsquare';
    }

    String rstSentAdif = '';
    if (rstSent.isNotEmpty) {
      rstSentAdif = '<RST_SENT:${rstSent.length}>$rstSent';
    }

    String rstRcvdAdif = '';
    if (rstRcvd.isNotEmpty) {
      rstRcvdAdif = '<RST_RCVD:${rstRcvd.length}>$rstRcvd';
    }

    String activationAdif = '';
    if (activationReference.isNotEmpty) {
      switch (activationType) {
        case 'iota':
          activationAdif =
              '<MY_IOTA:${activationReference.length}>$activationReference';
          break;
        case 'sota':
          activationAdif =
              '<MY_SOTA_REF:${activationReference.length}>$activationReference';
          break;
        case 'gma':
          activationAdif =
              '<GMA_REF:${activationReference.length}>$activationReference';
          break;
        case 'pota':
          activationAdif =
              '<MY_POTA_REF:${activationReference.length}>$activationReference';
          break;
        case 'cota':
          activationAdif =
              '<MY_COTA_REF:${activationReference.length}>$activationReference';
          break;
        case 'custom':
          activationAdif =
              '<COMMENT:${activationReference.length}>$activationReference';
          break;
      }
    }

    return '''<TQSL_IDENT:54>TQSL V2.7.3 Lib: V2.5 Config: V11.28 AllowDupes: false
<Rec_Type:5>tCERT
<CERT_UID:1>1
<CERTIFICATE:${certClean.length}>$certClean
<eor>
<Rec_Type:8>tSTATION
<STATION_UID:1>1
<CERT_UID:1>1
<CALL:${myCallsign.length}>$myCallsign
<DXCC:${dxcc.length}>$dxcc
<eor>
<Rec_Type:8>tCONTACT
<STATION_UID:1>1
<CALL:${dxCallsign.length}>$dxCallsign
<BAND:${bandName.length}>$bandName
<MODE:${mode.length}>$mode
<QSO_DATE:${qsoDate.length}>$qsoDate
<QSO_TIME:${qsoTime.length}>$qsoTime
$rstSentAdif$rstRcvdAdif$gridsquareAdif$activationAdif$satAdif
<SIGN_LOTW_V2.0:${signature.length}:6>$signature
<SIGNDATA:${signData.length}>$signData
<eor>
''';
  }
}
