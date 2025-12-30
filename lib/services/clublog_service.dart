import 'package:http/http.dart' as http;

class ClublogService {
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

  static const String _apiKey = '60af181c673d565408e30fe216c74961aa791954';
  static const String _uploadUrl = 'https://clublog.org/realtime.php';

  /// Upload a QSO to ClubLog
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
    required String clublogEmail,
    required String clublogPassword,
    String? notes,
    String? gridsquare,
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
      notes: notes,
      gridsquare: gridsquare,
    );

    // POST to ClubLog
    final response = await http.post(
      Uri.parse(_uploadUrl),
      body: {
        'email': clublogEmail.trim(),
        'password': clublogPassword.trim(),
        'callsign': myCallsign.trim(),
        'api': _apiKey,
        'adif': adif,
      },
    );

    if (response.statusCode == 200) {
      return true;
    }

    throw Exception('ClubLog upload failed: HTTP ${response.statusCode}');
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
    String? notes,
    String? gridsquare,
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

    // Optional fields
    if (notes != null && notes.isNotEmpty) {
      buffer.write('<NOTES:${notes.length}>$notes');
    }
    if (gridsquare != null && gridsquare.isNotEmpty) {
      buffer.write('<GRIDSQUARE:${gridsquare.length}>$gridsquare');
    }

    buffer.write('<EOR>');
    return buffer.toString();
  }
}
