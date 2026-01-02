class CallsignModel {
  int? id;
  String callsign;
  String clublogemail;
  String clublogpw;
  int useclublog;
  String eqsluser;
  String eqslpassword;
  int useeqsl;
  String lotwlogin;
  String lotwpw;
  String lotwcert;
  String lotwkey;
  int uselotw;
  String itu;
  String cqzone;
  String modes;
  String bands;
  int useCounter;
  int zeroIsT;
  int nineIsN;
  int sendK;
  int sendBK;
  int? singleRst;
  int useSpacebarToggle;
  int toggleSecondField;
  int useCqzones;
  int useItuzones;
  int hideDateTime;
  int showSatellite;
  String cwPre;
  String cwPost;
  int contestMode;
  String cwCustomText;
  String cwButtonLayout;

  static const String defaultButtonLayout = 'CQ,MY,CALL,RPT,CUSTOM|SEND,CLR,SAVE|';
  static const List<String> allButtons = ['CQ', 'MY', 'CALL', 'RPT', 'CUSTOM', 'SEND', 'CLR', 'SAVE'];

  static const List<String> allModes = ['CW', 'SSB', 'FM', 'FT8', 'FT4', 'AM', 'RTTY', 'PSK', 'DIGI'];
  static const List<String> allBands = ['1.8', '3.5', '5', '7', '10', '14', '18', '21', '24', '28', '50', '144', '440'];
  static const String defaultBands = '3.5,7,10,14,21,28';

  static int _parseIntOrZero(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  CallsignModel({
    this.id,
    this.callsign = '',
    this.clublogemail = '',
    this.clublogpw = '',
    this.useclublog = 0,
    this.eqsluser = '',
    this.eqslpassword = '',
    this.useeqsl = 0,
    this.lotwlogin = '',
    this.lotwpw = '',
    this.lotwcert = '',
    this.lotwkey = '',
    this.uselotw = 0,
    this.itu = '',
    this.cqzone = '',
    this.modes = 'CW,SSB',
    this.bands = defaultBands,
    this.useCounter = 0,
    this.zeroIsT = 0,
    this.nineIsN = 0,
    this.sendK = 0,
    this.sendBK = 0,
    this.singleRst = 0,
    this.useSpacebarToggle = 0,
    this.toggleSecondField = 0,
    this.useCqzones = 0,
    this.useItuzones = 0,
    this.hideDateTime = 0,
    this.showSatellite = 0,
    this.cwPre = '',
    this.cwPost = '',
    this.contestMode = 0,
    this.cwCustomText = '',
    this.cwButtonLayout = defaultButtonLayout,
  });

  List<String> get modesList => modes.isEmpty ? [] : modes.split(',');
  set modesList(List<String> list) => modes = list.join(',');

  List<String> get bandsList => bands.isEmpty ? [] : bands.split(',');
  set bandsList(List<String> list) => bands = list.join(',');

  /// Get button layout as list of rows (each row is a list of button IDs)
  List<List<String>> get buttonLayoutRows {
    if (cwButtonLayout.isEmpty) return [[], [], []];
    final rows = cwButtonLayout.split('|');
    return [
      rows.isNotEmpty && rows[0].isNotEmpty ? rows[0].split(',') : <String>[],
      rows.length > 1 && rows[1].isNotEmpty ? rows[1].split(',') : <String>[],
      rows.length > 2 && rows[2].isNotEmpty ? rows[2].split(',') : <String>[],
    ];
  }

  set buttonLayoutRows(List<List<String>> rows) {
    cwButtonLayout = rows.map((r) => r.join(',')).join('|');
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'callsign': callsign,
      'clublogemail': clublogemail,
      'clublogpw': clublogpw,
      'useclublog': useclublog,
      'eqsluser': eqsluser,
      'eqslpassword': eqslpassword,
      'useeqsl': useeqsl,
      'lotwlogin': lotwlogin,
      'lotwpw': lotwpw,
      'lotwcert': lotwcert,
      'lotwkey': lotwkey,
      'uselotw': uselotw,
      'itu': itu,
      'cqzone': cqzone,
      'modes': modes,
      'bands': bands,
      'useCounter': useCounter,
      'zeroIsT': zeroIsT,
      'nineIsN': nineIsN,
      'sendK': sendK,
      'sendBK': sendBK,
      'singleRst': singleRst ?? 0,
      'useSpacebarToggle': useSpacebarToggle,
      'toggleSecondField': toggleSecondField,
      'useCqzones': useCqzones,
      'useItuzones': useItuzones,
      'hideDateTime': hideDateTime,
      'showSatellite': showSatellite,
      'cwPre': cwPre,
      'cwPost': cwPost,
      'contestMode': contestMode,
      'cwCustomText': cwCustomText,
      'cwButtonLayout': cwButtonLayout,
    };
  }

  factory CallsignModel.fromMap(Map<String, dynamic> map) {
    return CallsignModel(
      id: map['id'] as int?,
      callsign: map['callsign'] as String? ?? '',
      clublogemail: map['clublogemail'] as String? ?? '',
      clublogpw: map['clublogpw'] as String? ?? '',
      useclublog: map['useclublog'] as int? ?? 0,
      eqsluser: map['eqsluser'] as String? ?? '',
      eqslpassword: map['eqslpassword'] as String? ?? '',
      useeqsl: map['useeqsl'] as int? ?? 0,
      lotwlogin: map['lotwlogin'] as String? ?? '',
      lotwpw: map['lotwpw'] as String? ?? '',
      lotwcert: map['lotwcert'] as String? ?? '',
      lotwkey: map['lotwkey'] as String? ?? '',
      uselotw: map['uselotw'] as int? ?? 0,
      itu: map['itu'] as String? ?? '',
      cqzone: map['cqzone'] as String? ?? '',
      modes: map['modes'] as String? ?? 'CW,SSB',
      bands: map['bands'] as String? ?? defaultBands,
      useCounter: _parseIntOrZero(map['useCounter']),
      zeroIsT: _parseIntOrZero(map['zeroIsT']),
      nineIsN: _parseIntOrZero(map['nineIsN']),
      sendK: _parseIntOrZero(map['sendK']),
      sendBK: _parseIntOrZero(map['sendBK']),
      singleRst: _parseIntOrZero(map['singleRst']),
      useSpacebarToggle: _parseIntOrZero(map['useSpacebarToggle']),
      toggleSecondField: _parseIntOrZero(map['toggleSecondField']),
      useCqzones: _parseIntOrZero(map['useCqzones']),
      useItuzones: _parseIntOrZero(map['useItuzones']),
      hideDateTime: _parseIntOrZero(map['hideDateTime']),
      showSatellite: _parseIntOrZero(map['showSatellite']),
      cwPre: map['cwPre'] as String? ?? '',
      cwPost: map['cwPost'] as String? ?? '',
      contestMode: _parseIntOrZero(map['contestMode']),
      cwCustomText: map['cwCustomText'] as String? ?? '',
      cwButtonLayout: map['cwButtonLayout'] as String? ?? defaultButtonLayout,
    );
  }

  CallsignModel copyWith({
    int? id,
    String? callsign,
    String? clublogemail,
    String? clublogpw,
    int? useclublog,
    String? eqsluser,
    String? eqslpassword,
    int? useeqsl,
    String? lotwlogin,
    String? lotwpw,
    String? lotwcert,
    String? lotwkey,
    int? uselotw,
    String? itu,
    String? cqzone,
    String? modes,
    String? bands,
    int? useCounter,
    int? zeroIsT,
    int? nineIsN,
    int? sendK,
    int? sendBK,
    int? singleRst,
    int? useSpacebarToggle,
    int? toggleSecondField,
    int? useCqzones,
    int? useItuzones,
    int? hideDateTime,
    int? showSatellite,
    String? cwPre,
    String? cwPost,
    int? contestMode,
    String? cwCustomText,
    String? cwButtonLayout,
  }) {
    return CallsignModel(
      id: id ?? this.id,
      callsign: callsign ?? this.callsign,
      clublogemail: clublogemail ?? this.clublogemail,
      clublogpw: clublogpw ?? this.clublogpw,
      useclublog: useclublog ?? this.useclublog,
      eqsluser: eqsluser ?? this.eqsluser,
      eqslpassword: eqslpassword ?? this.eqslpassword,
      useeqsl: useeqsl ?? this.useeqsl,
      lotwlogin: lotwlogin ?? this.lotwlogin,
      lotwpw: lotwpw ?? this.lotwpw,
      lotwcert: lotwcert ?? this.lotwcert,
      lotwkey: lotwkey ?? this.lotwkey,
      uselotw: uselotw ?? this.uselotw,
      itu: itu ?? this.itu,
      cqzone: cqzone ?? this.cqzone,
      modes: modes ?? this.modes,
      bands: bands ?? this.bands,
      useCounter: useCounter ?? this.useCounter,
      zeroIsT: zeroIsT ?? this.zeroIsT,
      nineIsN: nineIsN ?? this.nineIsN,
      sendK: sendK ?? this.sendK,
      sendBK: sendBK ?? this.sendBK,
      singleRst: singleRst ?? this.singleRst,
      useSpacebarToggle: useSpacebarToggle ?? this.useSpacebarToggle,
      toggleSecondField: toggleSecondField ?? this.toggleSecondField,
      useCqzones: useCqzones ?? this.useCqzones,
      useItuzones: useItuzones ?? this.useItuzones,
      hideDateTime: hideDateTime ?? this.hideDateTime,
      showSatellite: showSatellite ?? this.showSatellite,
      cwPre: cwPre ?? this.cwPre,
      cwPost: cwPost ?? this.cwPost,
      contestMode: contestMode ?? this.contestMode,
      cwCustomText: cwCustomText ?? this.cwCustomText,
      cwButtonLayout: cwButtonLayout ?? this.cwButtonLayout,
    );
  }
}
