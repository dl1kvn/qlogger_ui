import 'package:get/get.dart';
import '../data/database/database_helper.dart';
import '../data/models/qso_model.dart';
import '../data/models/callsign_model.dart';
import '../data/models/activation_model.dart';
import '../data/models/export_setting_model.dart';

class DatabaseController extends GetxController {
  final DatabaseHelper _db = DatabaseHelper();

  final RxList<QsoModel> qsoList = <QsoModel>[].obs;
  final RxList<CallsignModel> callsignList = <CallsignModel>[].obs;
  final RxList<ActivationModel> activationList = <ActivationModel>[].obs;
  final RxList<ExportSettingModel> exportSettingList = <ExportSettingModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  Future<void> loadAllData() async {
    await Future.wait([
      loadQsos(),
      loadCallsigns(),
      loadActivations(),
      loadExportSettings(),
    ]);
  }

  // ==================== QSO OPERATIONS ====================

  Future<void> loadQsos() async {
    try {
      isLoading.value = true;
      error.value = '';
      final qsos = await _db.getAllQsos();
      qsoList.assignAll(qsos);
    } catch (e) {
      error.value = 'Failed to load QSOs: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addQso(QsoModel qso) async {
    try {
      isLoading.value = true;
      error.value = '';
      final id = await _db.insertQso(qso);
      final newQso = qso.copyWith(id: id);
      qsoList.insert(0, newQso);
      return true;
    } catch (e) {
      error.value = 'Failed to add QSO: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateQso(QsoModel qso) async {
    try {
      isLoading.value = true;
      error.value = '';
      await _db.updateQso(qso);
      final index = qsoList.indexWhere((q) => q.id == qso.id);
      if (index != -1) {
        qsoList[index] = qso;
      }
      return true;
    } catch (e) {
      error.value = 'Failed to update QSO: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteQso(int id) async {
    try {
      isLoading.value = true;
      error.value = '';
      await _db.deleteQso(id);
      qsoList.removeWhere((q) => q.id == id);
      return true;
    } catch (e) {
      error.value = 'Failed to delete QSO: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAllQsos() async {
    try {
      isLoading.value = true;
      error.value = '';
      await _db.deleteAllQsos();
      qsoList.clear();
    } catch (e) {
      error.value = 'Failed to delete all QSOs: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchQsos(String callsign) async {
    try {
      isLoading.value = true;
      error.value = '';
      final qsos = await _db.searchQsos(callsign);
      qsoList.assignAll(qsos);
    } catch (e) {
      error.value = 'Failed to search QSOs: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> qsoExists(String callsign, String band, String mode) async {
    return await _db.qsoExists(callsign, band, mode);
  }

  Future<bool> qsoExistsForMyCallsign(
    String callsign,
    String band,
    String mode,
    String myCallsign,
  ) async {
    return await _db.qsoExistsForMyCallsign(callsign, band, mode, myCallsign);
  }

  Future<List<QsoModel>> searchQsosByCallsignPart(
    String searchPart,
    String myCallsign,
  ) async {
    return await _db.searchQsosByCallsignPart(searchPart, myCallsign);
  }

  Future<String?> getLastQsoNr() async {
    return await _db.getLastQsoNr();
  }

  int get qsoCount => qsoList.length;

  // ==================== CALLSIGN OPERATIONS ====================

  Future<void> loadCallsigns() async {
    try {
      isLoading.value = true;
      error.value = '';
      final callsigns = await _db.getAllCallsigns();
      callsignList.assignAll(callsigns);
    } catch (e) {
      error.value = 'Failed to load callsigns: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addCallsign(CallsignModel callsign) async {
    try {
      isLoading.value = true;
      error.value = '';
      final id = await _db.insertCallsign(callsign);
      final newCallsign = callsign.copyWith(id: id);
      callsignList.add(newCallsign);
      return true;
    } catch (e) {
      error.value = 'Failed to add callsign: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateCallsign(CallsignModel callsign) async {
    try {
      isLoading.value = true;
      error.value = '';
      await _db.updateCallsign(callsign);
      final index = callsignList.indexWhere((c) => c.id == callsign.id);
      if (index != -1) {
        callsignList[index] = callsign;
      }
      return true;
    } catch (e) {
      error.value = 'Failed to update callsign: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteCallsign(int id) async {
    try {
      isLoading.value = true;
      error.value = '';
      await _db.deleteCallsign(id);
      callsignList.removeWhere((c) => c.id == id);
      return true;
    } catch (e) {
      error.value = 'Failed to delete callsign: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<String>> getCallsignNames() async {
    return await _db.getCallsignList();
  }

  CallsignModel? getCallsignById(int id) {
    try {
      return callsignList.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ==================== ACTIVATION OPERATIONS ====================

  Future<void> loadActivations() async {
    try {
      isLoading.value = true;
      error.value = '';
      final activations = await _db.getAllActivations();
      activationList.assignAll(activations);
    } catch (e) {
      error.value = 'Failed to load activations: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addActivation(ActivationModel activation) async {
    try {
      isLoading.value = true;
      error.value = '';
      final id = await _db.insertActivation(activation);
      final newActivation = activation.copyWith(id: id);
      activationList.add(newActivation);
      return true;
    } catch (e) {
      error.value = 'Failed to add activation: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateActivation(ActivationModel activation) async {
    try {
      isLoading.value = true;
      error.value = '';
      await _db.updateActivation(activation);
      final index = activationList.indexWhere((a) => a.id == activation.id);
      if (index != -1) {
        activationList[index] = activation;
      }
      return true;
    } catch (e) {
      error.value = 'Failed to update activation: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteActivation(int id) async {
    try {
      isLoading.value = true;
      error.value = '';
      await _db.deleteActivation(id);
      activationList.removeWhere((a) => a.id == id);
      return true;
    } catch (e) {
      error.value = 'Failed to delete activation: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== EXPORT SETTING OPERATIONS ====================

  Future<void> loadExportSettings() async {
    try {
      isLoading.value = true;
      error.value = '';
      final settings = await _db.getAllExportSettings();
      exportSettingList.assignAll(settings);
    } catch (e) {
      error.value = 'Failed to load export settings: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addExportSetting(ExportSettingModel setting) async {
    try {
      isLoading.value = true;
      error.value = '';
      final id = await _db.insertExportSetting(setting);
      final newSetting = setting.copyWith(id: id);
      exportSettingList.add(newSetting);
      return true;
    } catch (e) {
      error.value = 'Failed to add export setting: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateExportSetting(ExportSettingModel setting) async {
    try {
      isLoading.value = true;
      error.value = '';
      await _db.updateExportSetting(setting);
      final index = exportSettingList.indexWhere((s) => s.id == setting.id);
      if (index != -1) {
        exportSettingList[index] = setting;
      }
      return true;
    } catch (e) {
      error.value = 'Failed to update export setting: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteExportSetting(int id) async {
    try {
      isLoading.value = true;
      error.value = '';
      await _db.deleteExportSetting(id);
      exportSettingList.removeWhere((s) => s.id == id);
      return true;
    } catch (e) {
      error.value = 'Failed to delete export setting: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
