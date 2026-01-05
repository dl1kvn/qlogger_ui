import 'package:get/get.dart';
import '../data/database/database_helper.dart';
import '../data/models/qso_model.dart';
import '../data/models/callsign_model.dart';
import '../data/models/activation_model.dart';
import '../data/models/export_setting_model.dart';
import '../data/models/satellite_model.dart';
import '../data/models/activation_image_model.dart';

class DatabaseController extends GetxController {
  final DatabaseHelper _db = DatabaseHelper();

  final RxList<QsoModel> qsoList = <QsoModel>[].obs;
  final RxList<CallsignModel> callsignList = <CallsignModel>[].obs;
  final RxList<ActivationModel> activationList = <ActivationModel>[].obs;
  final RxList<ExportSettingModel> exportSettingList = <ExportSettingModel>[].obs;
  final RxList<SatelliteModel> satelliteList = <SatelliteModel>[].obs;
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
      loadSatellites(),
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

  /// Add QSO and return the saved model with ID
  Future<QsoModel?> addQsoAndReturn(QsoModel qso) async {
    try {
      isLoading.value = true;
      error.value = '';
      final id = await _db.insertQso(qso);
      final newQso = qso.copyWith(id: id);
      qsoList.insert(0, newQso);
      return newQso;
    } catch (e) {
      error.value = 'Failed to add QSO: $e';
      return null;
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

  /// Delete multiple QSOs by ID in batch (no UI updates during operation)
  Future<int> deleteQsosBatch(List<int> ids) async {
    try {
      error.value = '';
      final deleted = await _db.deleteQsosBatch(ids);
      // Update list once at the end
      qsoList.removeWhere((q) => ids.contains(q.id));
      return deleted;
    } catch (e) {
      error.value = 'Failed to delete QSOs: $e';
      return 0;
    }
  }

  /// Add multiple QSOs in batch (no UI updates during operation)
  Future<int> addQsosBatch(List<QsoModel> qsos) async {
    try {
      error.value = '';
      final ids = await _db.insertQsosBatch(qsos);
      // Create QSOs with their new IDs and add to list once at end
      final newQsos = <QsoModel>[];
      for (int i = 0; i < qsos.length; i++) {
        newQsos.add(qsos[i].copyWith(id: ids[i]));
      }
      qsoList.insertAll(0, newQsos);
      return ids.length;
    } catch (e) {
      error.value = 'Failed to add QSOs: $e';
      return 0;
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

  // ==================== SATELLITE OPERATIONS ====================

  Future<void> loadSatellites() async {
    try {
      isLoading.value = true;
      error.value = '';
      final satellites = await _db.getAllSatellites();
      satelliteList.assignAll(satellites);
    } catch (e) {
      error.value = 'Failed to load satellites: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addSatellite(SatelliteModel satellite) async {
    try {
      isLoading.value = true;
      error.value = '';
      final id = await _db.insertSatellite(satellite);
      final newSatellite = satellite.copyWith(id: id);
      satelliteList.add(newSatellite);
      return true;
    } catch (e) {
      error.value = 'Failed to add satellite: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateSatellite(SatelliteModel satellite) async {
    try {
      isLoading.value = true;
      error.value = '';
      await _db.updateSatellite(satellite);
      final index = satelliteList.indexWhere((s) => s.id == satellite.id);
      if (index != -1) {
        satelliteList[index] = satellite;
      }
      return true;
    } catch (e) {
      error.value = 'Failed to update satellite: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteSatellite(int id) async {
    try {
      isLoading.value = true;
      error.value = '';
      await _db.deleteSatellite(id);
      satelliteList.removeWhere((s) => s.id == id);
      return true;
    } catch (e) {
      error.value = 'Failed to delete satellite: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== ACTIVATION IMAGE OPERATIONS ====================

  Future<List<ActivationImageModel>> getActivationImages(int activationId) async {
    try {
      return await _db.getActivationImages(activationId);
    } catch (e) {
      error.value = 'Failed to load activation images: $e';
      return [];
    }
  }

  Future<int> getActivationImageCount(int activationId) async {
    try {
      return await _db.getActivationImageCount(activationId);
    } catch (e) {
      return 0;
    }
  }

  Future<ActivationImageModel?> addActivationImage(ActivationImageModel image) async {
    try {
      final id = await _db.insertActivationImage(image);
      return image.copyWith(id: id);
    } catch (e) {
      error.value = 'Failed to add activation image: $e';
      return null;
    }
  }

  Future<bool> updateActivationImage(ActivationImageModel image) async {
    try {
      await _db.updateActivationImage(image);
      return true;
    } catch (e) {
      error.value = 'Failed to update activation image: $e';
      return false;
    }
  }

  Future<bool> deleteActivationImage(int id) async {
    try {
      await _db.deleteActivationImage(id);
      return true;
    } catch (e) {
      error.value = 'Failed to delete activation image: $e';
      return false;
    }
  }

  Future<bool> deleteActivationImages(int activationId) async {
    try {
      await _db.deleteActivationImages(activationId);
      return true;
    } catch (e) {
      error.value = 'Failed to delete activation images: $e';
      return false;
    }
  }
}
