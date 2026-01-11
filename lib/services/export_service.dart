import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/database_controller.dart';
import '../data/models/qso_model.dart';
import '../data/models/export_setting_model.dart';
import '../data/models/activation_model.dart';

class ExportService {
  // Band conversion from MHz to ADIF format
  static const Map<String, String> _bandToAdif = {
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
    '440': '70CM',
  };

  // Band conversion from MHz to frequency in kHz for Cabrillo
  static const Map<String, String> _bandToFreqKhz = {
    '1.8': '1800',
    '3.5': '3500',
    '5': '5300',
    '7': '7000',
    '10': '10100',
    '14': '14000',
    '18': '18100',
    '21': '21000',
    '24': '24900',
    '28': '28000',
    '50': '50000',
    '144': '144000',
    '440': '440000',
  };

  // Band conversion to decimal MHz for ADIF FREQ tag
  static const Map<String, String> _bandToFreqMhz = {
    '1.8': '1.84000',
    '3.5': '3.57300',
    '5': '5.35150',
    '7': '7.03500',
    '10': '10.12500',
    '14': '14.07400',
    '18': '18.10000',
    '21': '21.07400',
    '24': '24.91500',
    '28': '28.07400',
    '50': '50.31300',
    '144': '144.3000',
    '440': '432.2000',
  };

  // Field name to ADIF tag mapping
  static const Map<String, String> _fieldToAdif = {
    'callsign': 'CALL',
    'qsodate': 'QSO_DATE',
    'qsotime': 'TIME_ON',
    'band': 'BAND',
    'mymode': 'MODE',
    'rstout': 'RST_SENT',
    'rstin': 'RST_RCVD',
    'gridsquare': 'GRIDSQUARE',
    'myiota': 'MY_IOTA',
    'mysota': 'MY_SOTA_REF',
    'mypota': 'MY_POTA_REF',
    'received': 'SRX_STRING',
    'xtra': 'COMMENT',
    'qsonr': 'STX',
    'clublogEqslCall': 'STATION_CALLSIGN',
    'distance': 'DISTANCE',
    'clublogstatus': 'APP_QLOGGER_STATUS',
    'activationId': 'APP_QLOGGER_ACTIVATION',
  };

  /// Generate ADIF format string from QSOs
  static String generateAdif(
    List<QsoModel> qsos,
    ExportSettingModel setting,
  ) {
    final buffer = StringBuffer();

    // Get activations for lookup
    final dbController = Get.find<DatabaseController>();
    final activations = dbController.activationList;

    // ADIF header
    buffer.writeln('<ADIF_VER:5>3.1.4');
    buffer.writeln('<PROGRAMID:7>QLogger');
    buffer.writeln('<EOH>');
    buffer.writeln();

    final selectedFields = setting.fieldsList;
    final fieldAliases = setting.fieldAliasesMap;

    for (final qso in qsos) {
      final qsoMap = qso.toMap();

      // Get activation for this QSO if it has one
      ActivationModel? qsoActivation;
      if (qso.activationId != null) {
        qsoActivation = activations.firstWhereOrNull((a) => a.id == qso.activationId);
      }

      for (final field in selectedFields) {
        // Handle activationId specially - use proper ADIF tag based on type
        if (field == 'activationId') {
          final activationAdif = _getActivationAdif(qso.activationId, activations);
          if (activationAdif.isNotEmpty) {
            buffer.write(activationAdif);
          }
          continue;
        }

        // Use custom alias if defined, otherwise use default ADIF tag
        final customAlias = fieldAliases[field];
        final adifTag = (customAlias != null && customAlias.isNotEmpty)
            ? customAlias
            : _fieldToAdif[field];
        if (adifTag == null) continue;

        String value = _getFieldValue(qsoMap, field, setting.dateFormat);

        // If myiota/mysota/mypota is empty, check activation
        if (value.isEmpty && qsoActivation != null) {
          if (field == 'myiota' && qsoActivation.type == 'iota') {
            value = qsoActivation.reference;
          } else if (field == 'mysota' && qsoActivation.type == 'sota') {
            value = qsoActivation.reference;
          } else if (field == 'mypota' && qsoActivation.type == 'pota') {
            value = qsoActivation.reference;
          }
        }

        if (value.isEmpty) continue;

        // Convert band based on bandFormat setting
        if (field == 'band') {
          if (setting.bandFormat == 'freq') {
            // Use frequency format in decimal MHz - change tag to FREQ
            value = _bandToFreqMhz[value] ?? '$value.00000';
            buffer.write('<FREQ:${value.length}>$value');
            continue;
          } else {
            // Use band format (default)
            value = _bandToAdif[value] ?? '${value}M';
          }
        }

        buffer.write('<$adifTag:${value.length}>$value');
      }

      buffer.writeln('<EOR>');
    }

    return buffer.toString();
  }

  /// Get ADIF string for activation based on type
  static String _getActivationAdif(int? activationId, List<ActivationModel> activations) {
    if (activationId == null) return '';

    final activation = activations.firstWhereOrNull((a) => a.id == activationId);
    if (activation == null) return '';

    final activationType = activation.type;
    final activationReference = activation.reference;

    if (activationReference.isEmpty) return '';

    switch (activationType) {
      case 'iota':
        return '<MY_IOTA:${activationReference.length}>$activationReference';
      case 'sota':
        return '<MY_SOTA_REF:${activationReference.length}>$activationReference';
      case 'gma':
        return '<GMA_REF:${activationReference.length}>$activationReference';
      case 'pota':
        return '<MY_POTA_REF:${activationReference.length}>$activationReference';
      case 'cota':
        return '<MY_COTA_REF:${activationReference.length}>$activationReference';
      case 'custom':
        return '<COMMENT:${activationReference.length}>$activationReference';
      default:
        return '';
    }
  }

  /// Generate Cabrillo format string from QSOs
  static String generateCabrillo(
    List<QsoModel> qsos,
    ExportSettingModel setting,
  ) {
    final buffer = StringBuffer();

    // Get station callsign from first QSO
    String stationCall = '';
    if (qsos.isNotEmpty) {
      stationCall = qsos.first.clublogEqslCall;
    }

    // Cabrillo header
    buffer.writeln('START-OF-LOG: 3.0');
    buffer.writeln('CALLSIGN: $stationCall');
    buffer.writeln('CONTEST: ');
    buffer.writeln('CATEGORY-OPERATOR: SINGLE-OP');
    buffer.writeln('CATEGORY-BAND: ALL');
    buffer.writeln('CATEGORY-MODE: MIXED');
    buffer.writeln('CREATED-BY: QLogger');

    for (final qso in qsos) {
      // Format: QSO: freq mode date time mycall rst exch theircall rst exch
      final freq = _bandToFreqKhz[qso.band] ?? '14000';
      final mode = qso.mymode;

      // Format date based on setting
      String date;
      if (setting.dateFormat == 'YYYY-MM-DD' && qso.qsodate.length == 8) {
        date =
            '${qso.qsodate.substring(0, 4)}-${qso.qsodate.substring(4, 6)}-${qso.qsodate.substring(6, 8)}';
      } else {
        date = qso.qsodate;
      }

      final time = qso.qsotime;
      final myCall = qso.clublogEqslCall.padRight(13);
      final rstSent = qso.rstout.padRight(3);
      final exSent = qso.qsonr.padRight(6);
      final theirCall = qso.callsign.padRight(13);
      final rstRcvd = qso.rstin.padRight(3);
      final exRcvd = qso.received.padRight(6);

      buffer.writeln(
        'QSO: $freq $mode $date $time $myCall $rstSent $exSent $theirCall $rstRcvd $exRcvd',
      );
    }

    buffer.writeln('END-OF-LOG:');

    return buffer.toString();
  }

  /// Get field value from QSO map with date formatting
  static String _getFieldValue(
    Map<String, dynamic> qsoMap,
    String field,
    String dateFormat,
  ) {
    final value = qsoMap[field == 'clublogEqslCall' ? 'clublog_eqsl_call' : field];
    if (value == null) return '';

    String strValue = value.toString();

    // Format date if needed
    if (field == 'qsodate' &&
        dateFormat == 'YYYY-MM-DD' &&
        strValue.length == 8) {
      strValue =
          '${strValue.substring(0, 4)}-${strValue.substring(4, 6)}-${strValue.substring(6, 8)}';
    }

    return strValue;
  }

  /// Mode code mapping for EDI format
  static const Map<String, String> _modeToEdi = {
    'CW': '2',
    'SSB': '1',
    'FM': '6',
    'AM': '5',
    'RTTY': '7',
    'FT8': '7',
    'FT4': '7',
    'PSK': '7',
    'DIGI': '7',
  };

  /// Generate REG1TEST/EDI format string from QSOs
  static String generateEdi(
    List<QsoModel> qsos,
    ExportSettingModel setting, {
    String contestName = '',
    String contestExchange = '',
    String locator = '',
    String operatorName = '',
    String operatorCall = '',
    String section = '',
  }) {
    final buffer = StringBuffer();

    if (qsos.isEmpty) return '';

    // Get station callsign and dates from QSOs
    final stationCall = qsos.first.clublogEqslCall;
    final dates = qsos.map((q) => q.qsodate).toSet().toList()..sort();
    final startDate = dates.isNotEmpty ? dates.first : '';
    final endDate = dates.isNotEmpty ? dates.last : '';

    // Get locator from first QSO if not provided
    final wwl = locator.isNotEmpty
        ? locator
        : (qsos.first.gridsquare.isNotEmpty ? qsos.first.gridsquare : 'JO00AA');

    // Determine band from first QSO
    final band = qsos.first.band;
    String pBand = '';
    switch (band) {
      case '50': pBand = '50 MHz'; break;
      case '144': pBand = '144 MHz'; break;
      case '440': pBand = '432 MHz'; break;
      case '1.3': pBand = '1,3 GHz'; break;
      case '2.3': pBand = '2,3 GHz'; break;
      case '5.7': pBand = '5,7 GHz'; break;
      case '10': pBand = '10 GHz'; break;
      default: pBand = '$band MHz';
    }

    // REG1TEST header
    buffer.writeln('[REG1TEST;1]');
    buffer.writeln('TName=$contestName');
    buffer.writeln('TDate=$startDate;$endDate');
    buffer.writeln('PCall=$stationCall');
    buffer.writeln('PWWLo=$wwl');
    buffer.writeln('PExch=$contestExchange');
    buffer.writeln('PAdr1=');
    buffer.writeln('PAdr2=');
    buffer.writeln('PSect=$section');
    buffer.writeln('PBand=$pBand');
    buffer.writeln('PClub=');
    buffer.writeln('RName=$operatorName');
    buffer.writeln('RCall=$operatorCall');
    buffer.writeln('RAdr1=');
    buffer.writeln('RAdr2=');
    buffer.writeln('RPoCo=');
    buffer.writeln('RCity=');
    buffer.writeln('RCoun=');
    buffer.writeln('RPhon=');
    buffer.writeln('RHBBS=');
    buffer.writeln('MOpts1=0;0;0;0;0;0');
    buffer.writeln('MOpts2=0;0;0;0;0;0');
    buffer.writeln('STXEq=');
    buffer.writeln('SPowe=');
    buffer.writeln('SRXEq=');
    buffer.writeln('SApts=');
    buffer.writeln('SApts=');
    buffer.writeln('SAnth=');
    buffer.writeln('SAntl=');
    buffer.writeln('CQSOs=${qsos.length};1');
    buffer.writeln('CQSOP=');
    buffer.writeln('CWWLs=');
    buffer.writeln('CWWLB=');
    buffer.writeln('CExcs=');
    buffer.writeln('CExcB=');
    buffer.writeln('CDXCs=');
    buffer.writeln('CDXCB=');
    buffer.writeln('CToSc=');
    buffer.writeln('CODXC=');
    buffer.writeln('[Remarks]');
    buffer.writeln('Generated by QLogger');
    buffer.writeln('');

    // QSO Records section
    buffer.writeln('[QSORecords;${qsos.length}]');

    for (final qso in qsos) {
      // Format: YYMMDD;HHMM;Call;Mode;RSTs;NrS;RSTr;NrR;Exch;WWL;Points;;New WWL;New DXCC;Dup

      // Date: YYMMDD
      String date = qso.qsodate;
      if (date.length == 8) {
        date = date.substring(2); // Remove century, keep YYMMDD
      }

      // Time: HHMM
      final time = qso.qsotime.replaceAll(':', '').padRight(4, '0').substring(0, 4);

      // Callsign
      final call = qso.callsign;

      // Mode code
      final mode = _modeToEdi[qso.mymode] ?? '1';

      // RST sent/received
      final rstS = qso.rstout.isEmpty ? '59' : qso.rstout;
      final rstR = qso.rstin.isEmpty ? '59' : qso.rstin;

      // Numbers sent/received
      final nrS = qso.qsonr.isNotEmpty ? qso.qsonr : '001';
      final nrR = qso.received.isNotEmpty ? qso.received : '001';

      // Exchange (from xtra field or locator)
      final exch = qso.xtra.isNotEmpty ? qso.xtra : '';

      // WWL (locator from gridsquare)
      final qsoWwl = qso.gridsquare.isNotEmpty ? qso.gridsquare : '';

      // Points (placeholder)
      final points = '1';

      // New exchange, new WWL, new DXCC, Dup (placeholders)
      final newExch = '';
      final newWwl = '';
      final newDxcc = '';
      final dup = '';

      buffer.writeln('$date;$time;$call;$mode;$rstS;$nrS;$rstR;$nrR;$exch;$qsoWwl;$points;$newExch;$newWwl;$newDxcc;$dup');
    }

    return buffer.toString();
  }

  /// Export QSOs and share the file
  static Future<void> exportAndShare(
    List<QsoModel> qsos,
    ExportSettingModel setting, {
    String contestName = '',
    String contestExchange = '',
    String locator = '',
  }) async {
    // Generate content based on format
    String content;
    String extension;

    if (setting.format == 'cabrillo') {
      content = generateCabrillo(qsos, setting);
      extension = 'cbr';
    } else if (setting.format == 'edi') {
      content = generateEdi(
        qsos,
        setting,
        contestName: contestName,
        contestExchange: contestExchange,
        locator: locator,
      );
      extension = 'edi';
    } else {
      content = generateAdif(qsos, setting);
      extension = 'adi';
    }

    // Create temp file
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'qlogger_export_$timestamp.$extension';
    final file = File('${tempDir.path}/$fileName');

    await file.writeAsString(content);

    // Share the file
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'QLogger Export - ${setting.name}',
    );
  }
}
