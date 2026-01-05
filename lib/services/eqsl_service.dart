import 'package:http/http.dart' as http;

class EqslService {
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

  static const String _baseUrl = 'https://www.eQSL.cc/qslcard/importADIF.cfm';

  /// Upload a QSO to eQSL
  /// Returns true if successful, throws exception on error
  static Future<bool> uploadQso({
    required String myCallsign,
    required String dxCallsign,
    required String band,
    required String mode,
    required String date, // YYYYMMDD
    required String time, // HHMM
    required String rstSent,
    required String rstRcvd,
    required String eqslUser,
    required String eqslPassword,
    String? qslMsg,
    String activationType = '',
    String activationReference = '',
  }) async {
    // Convert band MHz to band name
    final bandName = _bandMap[band] ?? '20M';

    // Build ADIF string
    final adif = _buildAdif(
      dxCallsign: dxCallsign,
      date: date,
      time: time,
      bandName: bandName,
      bandMhz: band,
      mode: mode,
      rstSent: rstSent,
      rstRcvd: rstRcvd,
      qslMsg: qslMsg,
      activationType: activationType,
      activationReference: activationReference,
    );

    // POST to eQSL with form fields
    // Use callsign as username (eQSL typically uses callsign for login)
    final response = await http.post(
      Uri.parse(_baseUrl),
      body: {
        'eQSL_User': myCallsign.trim(),
        'eQSL_Pswd': eqslPassword.trim(),
        'ADIFData': adif,
      },
    ).timeout(const Duration(seconds: 30));

    // Check response for success
    if (response.body.contains('records added')) {
      return true;
    }

    // Check for common error messages
    if (response.body.contains('Error')) {
      throw Exception('eQSL error: ${_extractError(response.body)}');
    }

    throw Exception('eQSL upload failed');
  }

  static String _buildAdif({
    required String dxCallsign,
    required String date,
    required String time,
    required String bandName,
    required String bandMhz,
    required String mode,
    required String rstSent,
    required String rstRcvd,
    String? qslMsg,
    String activationType = '',
    String activationReference = '',
  }) {
    final buffer = StringBuffer('<EOH>');

    // Required fields
    buffer.write('<CALL:${dxCallsign.length}>$dxCallsign');
    buffer.write('<QSO_DATE:${date.length}>$date');
    buffer.write('<TIME_ON:${time.length}>$time');
    buffer.write('<BAND:${bandName.length}>$bandName');
    buffer.write('<FREQ:${bandMhz.length}>$bandMhz');
    buffer.write('<MODE:${mode.length}>$mode');

    // RST - replace 'n' with '9' for CW abbreviation
    final rstSentClean = rstSent.replaceAll('n', '9');
    buffer.write('<RST_SENT:${rstSentClean.length}>$rstSentClean');
    buffer.write('<RST_RCVD:${rstRcvd.length}>$rstRcvd');

    // Optional QSL message
    if (qslMsg != null && qslMsg.isNotEmpty) {
      buffer.write('<QSLMSG:${qslMsg.length}>$qslMsg');
    }

    // Activation reference based on type
    if (activationReference.isNotEmpty) {
      switch (activationType) {
        case 'iota':
          buffer.write('<MY_IOTA:${activationReference.length}>$activationReference');
          break;
        case 'sota':
          buffer.write('<MY_SOTA_REF:${activationReference.length}>$activationReference');
          break;
        case 'gma':
          buffer.write('<GMA_REF:${activationReference.length}>$activationReference');
          break;
        case 'pota':
          buffer.write('<MY_POTA_REF:${activationReference.length}>$activationReference');
          break;
        case 'cota':
          buffer.write('<MY_COTA_REF:${activationReference.length}>$activationReference');
          break;
        case 'custom':
          buffer.write('<COMMENT:${activationReference.length}>$activationReference');
          break;
      }
    }

    buffer.write('<EOR>');
    return buffer.toString();
  }

  static String _extractError(String body) {
    // Try to extract meaningful error message from HTML response
    final errorMatch = RegExp(r'Error[:\s]+([^<]+)').firstMatch(body);
    if (errorMatch != null) {
      return errorMatch.group(1)?.trim() ?? 'Unknown error';
    }
    return 'Unknown error';
  }
}
