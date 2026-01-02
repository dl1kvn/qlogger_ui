import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/qso_model.dart';
import '../models/callsign_model.dart';
import '../models/activation_model.dart';
import '../models/iota_group_model.dart';
import '../models/iota_island_model.dart';
import '../models/pota_park_model.dart';
import '../models/export_setting_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  static const String _dbName = 'qlogger.db';
  static const int _dbVersion = 23;

  static const String qsoTable = 'qsoTable';
  static const String allsignTable = 'allsignTable';
  static const String activationTable = 'activationTable';
  static const String iotaGroupTable = 'iotaGroupTable';
  static const String iotaIslandTable = 'iotaIslandTable';
  static const String potaParkTable = 'potaParkTable';
  static const String exportSettingTable = 'exportSettingTable';

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $qsoTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        callsign TEXT,
        received TEXT,
        xtra TEXT,
        qsonr TEXT,
        qsodate TEXT,
        qsotime TEXT,
        rstout TEXT,
        rstin TEXT,
        band TEXT,
        mymode TEXT,
        myiota TEXT,
        mysota TEXT,
        mypota TEXT,
        gridsquare TEXT,
        distance TEXT,
        clublog_eqsl_call TEXT,
        clublogstatus TEXT,
        activation_id INTEGER,
        lotw_failed INTEGER DEFAULT 0,
        eqsl_failed INTEGER DEFAULT 0,
        clublog_failed INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE $allsignTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        callsign TEXT,
        clublogemail TEXT,
        clublogpw TEXT,
        useclublog INTEGER DEFAULT 0,
        eqsluser TEXT,
        eqslpassword TEXT,
        useeqsl INTEGER DEFAULT 0,
        lotwlogin TEXT,
        lotwpw TEXT,
        uselotw INTEGER DEFAULT 0,
        lotwcert TEXT,
        lotwkey TEXT,
        itu TEXT,
        cqzone TEXT,
        modes TEXT DEFAULT 'CW,SSB',
        bands TEXT DEFAULT '3.5,7,10,14,21,28',
        useCounter INTEGER DEFAULT 0,
        zeroIsT INTEGER DEFAULT 0,
        nineIsN INTEGER DEFAULT 0,
        sendK INTEGER DEFAULT 0,
        sendBK INTEGER DEFAULT 0,
        singleRst INTEGER DEFAULT 0,
        useSpacebarToggle INTEGER DEFAULT 0,
        toggleSecondField INTEGER DEFAULT 0,
        useCqzones INTEGER DEFAULT 0,
        useItuzones INTEGER DEFAULT 0,
        hideDateTime INTEGER DEFAULT 0,
        showSatellite INTEGER DEFAULT 0,
        cwPre TEXT DEFAULT '',
        cwPost TEXT DEFAULT '',
        contestMode INTEGER DEFAULT 0,
        cwCustomText TEXT DEFAULT '',
        cwButtonLayout TEXT DEFAULT 'CQ,MY,CALL,RPT,CUSTOM|SEND,CLR,SAVE|'
      )
    ''');

    await db.execute('''
      CREATE TABLE $activationTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT,
        reference TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $iotaGroupTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ref TEXT UNIQUE,
        name TEXT,
        continent TEXT,
        dxcc TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $iotaIslandTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_ref TEXT,
        subgroup_ref TEXT,
        name TEXT,
        alt_names TEXT,
        lat REAL,
        lon REAL,
        active INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE $potaParkTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reference TEXT UNIQUE,
        name TEXT,
        active INTEGER DEFAULT 1,
        entity_id INTEGER,
        location_desc TEXT,
        latitude REAL,
        longitude REAL,
        grid TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $exportSettingTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        format TEXT,
        date_format TEXT,
        band_format TEXT DEFAULT 'band',
        fields TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE $allsignTable ADD COLUMN modes TEXT DEFAULT 'CW,SSB'");
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE $allsignTable ADD COLUMN bands TEXT DEFAULT '3.5,7,10,14,21,28'");
    }
    if (oldVersion < 4) {
      await db.execute("ALTER TABLE $allsignTable ADD COLUMN useCounter INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE $allsignTable ADD COLUMN zeroIsT INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE $allsignTable ADD COLUMN nineIsN INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE $allsignTable ADD COLUMN sendK INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE $allsignTable ADD COLUMN sendBK INTEGER DEFAULT 0");
    }
    if (oldVersion < 5) {
      await db.execute("ALTER TABLE $allsignTable ADD COLUMN singleRst INTEGER DEFAULT 0");
    }
    if (oldVersion < 6) {
      // Ensure singleRst column exists (in case migration 5 failed)
      try {
        await db.execute("ALTER TABLE $allsignTable ADD COLUMN singleRst INTEGER DEFAULT 0");
      } catch (_) {
        // Column already exists, ignore
      }
    }
    if (oldVersion < 7) {
      await db.execute("ALTER TABLE $allsignTable ADD COLUMN useSpacebarToggle INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE $allsignTable ADD COLUMN toggleSecondField INTEGER DEFAULT 0");
    }
    if (oldVersion < 8) {
      await db.execute("ALTER TABLE $allsignTable ADD COLUMN useCqzones INTEGER DEFAULT 0");
    }
    if (oldVersion < 9) {
      await db.execute("ALTER TABLE $allsignTable ADD COLUMN useItuzones INTEGER DEFAULT 0");
    }
    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE $activationTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT
        )
      ''');
    }
    if (oldVersion < 11) {
      await db.execute("ALTER TABLE $qsoTable ADD COLUMN activation_id INTEGER");
    }
    if (oldVersion < 12) {
      await db.execute("ALTER TABLE $activationTable ADD COLUMN reference TEXT");
    }
    if (oldVersion < 13) {
      await db.execute('''
        CREATE TABLE $iotaGroupTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ref TEXT UNIQUE,
          name TEXT,
          continent TEXT,
          dxcc TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE $iotaIslandTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          group_ref TEXT,
          subgroup_ref TEXT,
          name TEXT,
          alt_names TEXT,
          lat REAL,
          lon REAL,
          active INTEGER DEFAULT 1
        )
      ''');
    }
    if (oldVersion < 14) {
      await db.execute('''
        CREATE TABLE $potaParkTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          reference TEXT UNIQUE,
          name TEXT,
          active INTEGER DEFAULT 1,
          entity_id INTEGER,
          location_desc TEXT,
          latitude REAL,
          longitude REAL,
          grid TEXT
        )
      ''');
    }
    if (oldVersion < 15) {
      await db.execute("ALTER TABLE $allsignTable ADD COLUMN hideDateTime INTEGER DEFAULT 0");
    }
    if (oldVersion < 16) {
      await db.execute("ALTER TABLE $allsignTable ADD COLUMN showSatellite INTEGER DEFAULT 0");
    }
    if (oldVersion < 17) {
      await db.execute("ALTER TABLE $allsignTable ADD COLUMN cwPre TEXT DEFAULT ''");
      await db.execute("ALTER TABLE $allsignTable ADD COLUMN cwPost TEXT DEFAULT ''");
    }
    if (oldVersion < 18) {
      await db.execute('''
        CREATE TABLE $exportSettingTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          format TEXT,
          date_format TEXT,
          fields TEXT
        )
      ''');
    }
    if (oldVersion < 19) {
      await db.execute("ALTER TABLE $exportSettingTable ADD COLUMN band_format TEXT DEFAULT 'band'");
    }
    if (oldVersion < 20) {
      await db.execute("ALTER TABLE $qsoTable ADD COLUMN lotw_failed INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE $qsoTable ADD COLUMN eqsl_failed INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE $qsoTable ADD COLUMN clublog_failed INTEGER DEFAULT 0");
    }
    if (oldVersion < 21) {
      await db.execute("ALTER TABLE $allsignTable ADD COLUMN contestMode INTEGER DEFAULT 0");
    }
    if (oldVersion < 22) {
      await db.execute("ALTER TABLE $allsignTable ADD COLUMN cwCustomText TEXT DEFAULT ''");
    }
    if (oldVersion < 23) {
      await db.execute("ALTER TABLE $allsignTable ADD COLUMN cwButtonLayout TEXT DEFAULT 'CQ,MY,CALL,RPT,CUSTOM|SEND,CLR,SAVE|'");
    }
  }

  // ==================== QSO CRUD ====================

  Future<int> insertQso(QsoModel qso) async {
    final db = await database;
    return await db.insert(qsoTable, qso.toMap());
  }

  Future<List<QsoModel>> getAllQsos() async {
    final db = await database;
    final maps = await db.query(
      qsoTable,
      orderBy: 'qsodate DESC, qsotime DESC',
    );
    return maps.map((map) => QsoModel.fromMap(map)).toList();
  }

  Future<QsoModel?> getQsoById(int id) async {
    final db = await database;
    final maps = await db.query(
      qsoTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return QsoModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateQso(QsoModel qso) async {
    final db = await database;
    return await db.update(
      qsoTable,
      qso.toMap(),
      where: 'id = ?',
      whereArgs: [qso.id],
    );
  }

  Future<int> deleteQso(int id) async {
    final db = await database;
    return await db.delete(
      qsoTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllQsos() async {
    final db = await database;
    return await db.delete(qsoTable);
  }

  Future<List<QsoModel>> searchQsos(String callsign) async {
    final db = await database;
    final maps = await db.query(
      qsoTable,
      where: 'callsign LIKE ?',
      whereArgs: ['%$callsign%'],
      orderBy: 'qsodate DESC, qsotime DESC',
    );
    return maps.map((map) => QsoModel.fromMap(map)).toList();
  }

  Future<bool> qsoExists(String callsign, String band, String mode) async {
    final db = await database;
    final maps = await db.query(
      qsoTable,
      where: 'callsign = ? AND band = ? AND mymode = ?',
      whereArgs: [callsign, band, mode],
    );
    return maps.isNotEmpty;
  }

  Future<bool> qsoExistsForMyCallsign(
    String callsign,
    String band,
    String mode,
    String myCallsign,
  ) async {
    final db = await database;
    final maps = await db.query(
      qsoTable,
      where: 'callsign = ? AND band = ? AND mymode = ? AND clublog_eqsl_call = ?',
      whereArgs: [callsign, band, mode, myCallsign],
    );
    return maps.isNotEmpty;
  }

  Future<List<QsoModel>> searchQsosByCallsignPart(
    String searchPart,
    String myCallsign,
  ) async {
    final db = await database;
    final maps = await db.query(
      qsoTable,
      where: 'callsign LIKE ? AND clublog_eqsl_call = ?',
      whereArgs: ['%$searchPart%', myCallsign],
      orderBy: 'qsodate DESC, qsotime DESC',
      limit: 20,
    );
    return maps.map((map) => QsoModel.fromMap(map)).toList();
  }

  Future<int> getQsoCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $qsoTable');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<String?> getLastQsoNr() async {
    final db = await database;
    final maps = await db.query(
      qsoTable,
      orderBy: 'id DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first['qsonr'] as String?;
    }
    return null;
  }

  // ==================== CALLSIGN CRUD ====================

  Future<int> insertCallsign(CallsignModel callsign) async {
    final db = await database;
    return await db.insert(allsignTable, callsign.toMap());
  }

  Future<List<CallsignModel>> getAllCallsigns() async {
    final db = await database;
    final maps = await db.query(allsignTable);
    return maps.map((map) => CallsignModel.fromMap(map)).toList();
  }

  Future<CallsignModel?> getCallsignById(int id) async {
    final db = await database;
    final maps = await db.query(
      allsignTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return CallsignModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCallsign(CallsignModel callsign) async {
    final db = await database;
    return await db.update(
      allsignTable,
      callsign.toMap(),
      where: 'id = ?',
      whereArgs: [callsign.id],
    );
  }

  Future<int> deleteCallsign(int id) async {
    final db = await database;
    return await db.delete(
      allsignTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<String>> getCallsignList() async {
    final db = await database;
    final maps = await db.query(allsignTable, columns: ['callsign']);
    return maps.map((map) => map['callsign'] as String).toList();
  }

  // ==================== ACTIVATION CRUD ====================

  Future<int> insertActivation(ActivationModel activation) async {
    final db = await database;
    return await db.insert(activationTable, activation.toMap());
  }

  Future<List<ActivationModel>> getAllActivations() async {
    final db = await database;
    final maps = await db.query(activationTable);
    return maps.map((map) => ActivationModel.fromMap(map)).toList();
  }

  Future<ActivationModel?> getActivationById(int id) async {
    final db = await database;
    final maps = await db.query(
      activationTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ActivationModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateActivation(ActivationModel activation) async {
    final db = await database;
    return await db.update(
      activationTable,
      activation.toMap(),
      where: 'id = ?',
      whereArgs: [activation.id],
    );
  }

  Future<int> deleteActivation(int id) async {
    final db = await database;
    return await db.delete(
      activationTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== IOTA GROUP CRUD ====================

  Future<int> insertIotaGroup(IotaGroupModel group) async {
    final db = await database;
    return await db.insert(
      iotaGroupTable,
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertIotaGroups(List<IotaGroupModel> groups) async {
    final db = await database;
    final batch = db.batch();
    for (final group in groups) {
      batch.insert(
        iotaGroupTable,
        group.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<IotaGroupModel>> getAllIotaGroups() async {
    final db = await database;
    final maps = await db.query(iotaGroupTable, orderBy: 'ref');
    return maps.map((map) => IotaGroupModel.fromMap(map)).toList();
  }

  Future<IotaGroupModel?> getIotaGroupByRef(String ref) async {
    final db = await database;
    final maps = await db.query(
      iotaGroupTable,
      where: 'ref = ?',
      whereArgs: [ref],
    );
    if (maps.isNotEmpty) {
      return IotaGroupModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteAllIotaGroups() async {
    final db = await database;
    return await db.delete(iotaGroupTable);
  }

  Future<int> getIotaGroupCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $iotaGroupTable');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ==================== IOTA ISLAND CRUD ====================

  Future<int> insertIotaIsland(IotaIslandModel island) async {
    final db = await database;
    return await db.insert(iotaIslandTable, island.toMap());
  }

  Future<void> insertIotaIslands(List<IotaIslandModel> islands) async {
    final db = await database;
    final batch = db.batch();
    for (final island in islands) {
      batch.insert(iotaIslandTable, island.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<IotaIslandModel>> getAllIotaIslands() async {
    final db = await database;
    final maps = await db.query(iotaIslandTable, orderBy: 'group_ref, name');
    return maps.map((map) => IotaIslandModel.fromMap(map)).toList();
  }

  Future<List<IotaIslandModel>> getIotaIslandsByGroupRef(String groupRef) async {
    final db = await database;
    final maps = await db.query(
      iotaIslandTable,
      where: 'group_ref = ?',
      whereArgs: [groupRef],
      orderBy: 'name',
    );
    return maps.map((map) => IotaIslandModel.fromMap(map)).toList();
  }

  Future<int> deleteAllIotaIslands() async {
    final db = await database;
    return await db.delete(iotaIslandTable);
  }

  Future<int> getIotaIslandCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $iotaIslandTable');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ==================== POTA PARK CRUD ====================

  Future<int> insertPotaPark(PotaParkModel park) async {
    final db = await database;
    return await db.insert(
      potaParkTable,
      park.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertPotaParks(List<PotaParkModel> parks) async {
    final db = await database;
    final batch = db.batch();
    for (final park in parks) {
      batch.insert(
        potaParkTable,
        park.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<PotaParkModel>> getAllPotaParks() async {
    final db = await database;
    final maps = await db.query(potaParkTable, orderBy: 'reference');
    return maps.map((map) => PotaParkModel.fromMap(map)).toList();
  }

  Future<PotaParkModel?> getPotaParkByReference(String reference) async {
    final db = await database;
    final maps = await db.query(
      potaParkTable,
      where: 'reference = ?',
      whereArgs: [reference],
    );
    if (maps.isNotEmpty) {
      return PotaParkModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<PotaParkModel>> searchPotaParks(String query) async {
    final db = await database;
    final maps = await db.query(
      potaParkTable,
      where: 'reference LIKE ? OR name LIKE ? OR location_desc LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'reference',
      limit: 100,
    );
    return maps.map((map) => PotaParkModel.fromMap(map)).toList();
  }

  Future<int> deleteAllPotaParks() async {
    final db = await database;
    return await db.delete(potaParkTable);
  }

  Future<int> getPotaParkCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $potaParkTable');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ==================== EXPORT SETTING CRUD ====================

  Future<int> insertExportSetting(ExportSettingModel setting) async {
    final db = await database;
    return await db.insert(exportSettingTable, setting.toMap());
  }

  Future<List<ExportSettingModel>> getAllExportSettings() async {
    final db = await database;
    final maps = await db.query(exportSettingTable, orderBy: 'name');
    return maps.map((map) => ExportSettingModel.fromMap(map)).toList();
  }

  Future<ExportSettingModel?> getExportSettingById(int id) async {
    final db = await database;
    final maps = await db.query(
      exportSettingTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ExportSettingModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateExportSetting(ExportSettingModel setting) async {
    final db = await database;
    return await db.update(
      exportSettingTable,
      setting.toMap(),
      where: 'id = ?',
      whereArgs: [setting.id],
    );
  }

  Future<int> deleteExportSetting(int id) async {
    final db = await database;
    return await db.delete(
      exportSettingTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== DATABASE MANAGEMENT ====================

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
