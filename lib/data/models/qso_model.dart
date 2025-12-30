class QsoModel {
  int? id;
  String callsign;
  String received;
  String xtra;
  String qsonr;
  String qsodate;
  String qsotime;
  String rstout;
  String rstin;
  String band;
  String mymode;
  String myiota;
  String mysota;
  String mypota;
  String gridsquare;
  String distance;
  String clublogEqslCall;
  String clublogstatus;
  int? activationId;

  QsoModel({
    this.id,
    this.callsign = '',
    this.received = '',
    this.xtra = '',
    this.qsonr = '',
    this.qsodate = '',
    this.qsotime = '',
    this.rstout = '59',
    this.rstin = '59',
    this.band = '',
    this.mymode = '',
    this.myiota = '',
    this.mysota = '',
    this.mypota = '',
    this.gridsquare = '',
    this.distance = '',
    this.clublogEqslCall = '',
    this.clublogstatus = '',
    this.activationId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'callsign': callsign,
      'received': received,
      'xtra': xtra,
      'qsonr': qsonr,
      'qsodate': qsodate,
      'qsotime': qsotime,
      'rstout': rstout,
      'rstin': rstin,
      'band': band,
      'mymode': mymode,
      'myiota': myiota,
      'mysota': mysota,
      'mypota': mypota,
      'gridsquare': gridsquare,
      'distance': distance,
      'clublog_eqsl_call': clublogEqslCall,
      'clublogstatus': clublogstatus,
      'activation_id': activationId,
    };
  }

  factory QsoModel.fromMap(Map<String, dynamic> map) {
    return QsoModel(
      id: map['id'] as int?,
      callsign: map['callsign'] as String? ?? '',
      received: map['received'] as String? ?? '',
      xtra: map['xtra'] as String? ?? '',
      qsonr: map['qsonr'] as String? ?? '',
      qsodate: map['qsodate'] as String? ?? '',
      qsotime: map['qsotime'] as String? ?? '',
      rstout: map['rstout'] as String? ?? '59',
      rstin: map['rstin'] as String? ?? '59',
      band: map['band'] as String? ?? '',
      mymode: map['mymode'] as String? ?? '',
      myiota: map['myiota'] as String? ?? '',
      mysota: map['mysota'] as String? ?? '',
      mypota: map['mypota'] as String? ?? '',
      gridsquare: map['gridsquare'] as String? ?? '',
      distance: map['distance'] as String? ?? '',
      clublogEqslCall: map['clublog_eqsl_call'] as String? ?? '',
      clublogstatus: map['clublogstatus'] as String? ?? '',
      activationId: map['activation_id'] as int?,
    );
  }

  QsoModel copyWith({
    int? id,
    String? callsign,
    String? received,
    String? xtra,
    String? qsonr,
    String? qsodate,
    String? qsotime,
    String? rstout,
    String? rstin,
    String? band,
    String? mymode,
    String? myiota,
    String? mysota,
    String? mypota,
    String? gridsquare,
    String? distance,
    String? clublogEqslCall,
    String? clublogstatus,
    int? activationId,
  }) {
    return QsoModel(
      id: id ?? this.id,
      callsign: callsign ?? this.callsign,
      received: received ?? this.received,
      xtra: xtra ?? this.xtra,
      qsonr: qsonr ?? this.qsonr,
      qsodate: qsodate ?? this.qsodate,
      qsotime: qsotime ?? this.qsotime,
      rstout: rstout ?? this.rstout,
      rstin: rstin ?? this.rstin,
      band: band ?? this.band,
      mymode: mymode ?? this.mymode,
      myiota: myiota ?? this.myiota,
      mysota: mysota ?? this.mysota,
      mypota: mypota ?? this.mypota,
      gridsquare: gridsquare ?? this.gridsquare,
      distance: distance ?? this.distance,
      clublogEqslCall: clublogEqslCall ?? this.clublogEqslCall,
      clublogstatus: clublogstatus ?? this.clublogstatus,
      activationId: activationId ?? this.activationId,
    );
  }
}
