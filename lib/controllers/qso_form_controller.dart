import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../data/cqzones.dart';
import '../data/ituzones.dart';
import '../data/models/qso_model.dart';
import '../services/clublog_service.dart';
import '../services/connectivity_service.dart';
import '../services/eqsl_service.dart';
import '../services/lotw_service.dart';
import 'database_controller.dart';
import 'bluetooth_controller.dart';

class QsoFormController extends GetxController with WidgetsBindingObserver {
  final formKey = GlobalKey<FormState>();
  final _dbController = Get.find<DatabaseController>();
  final _storage = GetStorage();

  final callsignController = TextEditingController();
  final rstInController = TextEditingController(text: '599');
  final rstOutController = TextEditingController(text: '599');
  final receivedInfoController = TextEditingController();
  final xtra1Controller = TextEditingController();
  final xtra2Controller = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final locatorController = TextEditingController();
  final cwPreController = TextEditingController();
  final cwPostController = TextEditingController();

  final selectedBand = '14'.obs;
  final selectedMode = 'CW'.obs;
  final selectedSatellite = 'no sat'.obs;
  final selectedMyCallsign = Rxn<String>();
  final selectedActivationId = Rxn<int>();

  // Status
  final bluetoothConnected = false.obs;
  final statusText = ''.obs;
  final currentUtcTime = ''.obs;
  final hasInternet = false.obs;
  Timer? _utcTimer;
  Timer? _internetTimer;
  Timer? _workedBeforeDebounce;

  // Worked before indicator
  final workedBefore = false.obs;

  // Matching callsigns from previous QSOs
  final matchingQsos = <QsoModel>[].obs;

  // Location loading state
  final isGettingLocation = false.obs;

  // Checkbox options
  final useCounter = false.obs;
  final zeroIsT = false.obs;
  final nineIsN = false.obs;
  final sendK = false.obs;
  final sendBK = false.obs;
  final singleRst = false.obs;
  bool _isLoadingCheckboxes = false;

  // Flash triggers for upload success animation
  final clublogFlash = false.obs;
  final eqslFlash = false.obs;
  final lotwFlash = false.obs;

  // Custom keyboard
  final useCustomKeyboard = false.obs;
  final activeTextField = Rxn<TextEditingController>();

  void toggleCustomKeyboard() {
    useCustomKeyboard.value = !useCustomKeyboard.value;
  }

  void setActiveTextField(TextEditingController? controller) {
    activeTextField.value = controller;
  }

  void insertCharacter(String char) {
    final controller = activeTextField.value;
    if (controller == null) return;

    final text = controller.text;
    final selection = controller.selection;

    if (selection.isValid && selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, char);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + char.length,
        ),
      );
    } else {
      controller.text = text + char;
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    }

    // Trigger the appropriate onChanged handler to handle spacebar toggle
    if (controller == callsignController) {
      onCallsignChanged(controller.text);
    } else if (controller == receivedInfoController) {
      onInfoChanged(controller.text);
    } else if (controller == xtra1Controller) {
      onXtra1Changed(controller.text);
    }
  }

  void deleteCharacter() {
    final controller = activeTextField.value;
    if (controller == null) return;

    final text = controller.text;
    final selection = controller.selection;

    if (selection.isValid && selection.start > 0) {
      if (selection.start == selection.end) {
        // No selection, delete char before cursor
        final newText = text.replaceRange(
          selection.start - 1,
          selection.start,
          '',
        );
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: selection.start - 1),
        );
      } else {
        // Delete selection
        final newText = text.replaceRange(selection.start, selection.end, '');
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: selection.start),
        );
      }
    }
  }

  static const _defaultBands = ['3.5', '7', '10', '14', '21', '28'];

  List<String> get satellites {
    final dbSatellites = _dbController.satelliteList
        .where((s) => s.isActive)
        .map((s) => s.name)
        .toList();
    return ['no sat', ...dbSatellites];
  }

  List<String> get myCallsigns =>
      _dbController.callsignList.map((c) => c.callsign).toList();

  List<String> get modes {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) {
      return ['CW', 'SSB'];
    }
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      return cs.modesList.isNotEmpty ? List.from(cs.modesList) : ['CW', 'SSB'];
    } catch (_) {
      return ['CW', 'SSB'];
    }
  }

  List<String> get bands {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) {
      return List.from(_defaultBands);
    }
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      return cs.bandsList.isNotEmpty
          ? List.from(cs.bandsList)
          : List.from(_defaultBands);
    } catch (_) {
      return List.from(_defaultBands);
    }
  }

  bool get useClublog {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) return false;
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      return cs.useclublog == 1;
    } catch (_) {
      return false;
    }
  }

  bool get useEqsl {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) return false;
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      return cs.useeqsl == 1;
    } catch (_) {
      return false;
    }
  }

  bool get useLotw {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) return false;
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      return cs.uselotw == 1;
    } catch (_) {
      return false;
    }
  }

  /// Check if LoTW has P12 certificate configured
  bool get hasLotwKey {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) return false;
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      // Only check if certificate exists - password can be empty
      return cs.lotwcert.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Check if ClubLog has email and password configured
  bool get hasClublogCredentials {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) return false;
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      return cs.clublogemail.isNotEmpty && cs.clublogpw.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Check if eQSL has password configured
  bool get hasEqslCredentials {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) return false;
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      return cs.eqslpassword.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Check if spacebar toggle is enabled
  bool get useSpacebarToggle {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) return false;
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      return cs.useSpacebarToggle == 1;
    } catch (_) {
      return false;
    }
  }

  /// Check if toggle second field is enabled
  bool get toggleSecondField {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) return false;
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      return cs.toggleSecondField == 1;
    } catch (_) {
      return false;
    }
  }

  /// Check if CQ zones auto-fill is enabled
  bool get useCqzones {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) return false;
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      return cs.useCqzones == 1;
    } catch (_) {
      return false;
    }
  }

  /// Check if ITU zones auto-fill is enabled
  bool get useItuzones {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) return false;
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      return cs.useItuzones == 1;
    } catch (_) {
      return false;
    }
  }

  /// Check if date/time row should be hidden
  final hideDateTime = false.obs;

  void _loadHideDateTime() {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) {
      hideDateTime.value = false;
      return;
    }
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      hideDateTime.value = cs.hideDateTime == 1;
    } catch (_) {
      hideDateTime.value = false;
    }
  }

  Future<void> toggleHideDateTime() async {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) return;
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      final newValue = cs.hideDateTime == 1 ? 0 : 1;
      final updated = cs.copyWith(hideDateTime: newValue);
      await _dbController.updateCallsign(updated);
      hideDateTime.value = newValue == 1;
    } catch (_) {}
  }

  /// Check if satellite dropdown should be shown
  final showSatellite = false.obs;

  void _loadShowSatellite() {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) {
      showSatellite.value = false;
      return;
    }
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      showSatellite.value = cs.showSatellite == 1;
    } catch (_) {
      showSatellite.value = false;
    }
  }

  Future<void> toggleShowSatellite() async {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) return;
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      final newValue = cs.showSatellite == 1 ? 0 : 1;
      final updated = cs.copyWith(showSatellite: newValue);
      await _dbController.updateCallsign(updated);
      showSatellite.value = newValue == 1;
    } catch (_) {}
  }

  /// Contest mode - hides service indicators and CW options for faster logging
  final contestMode = false.obs;

  /// Custom CW text for user-defined button
  final cwCustomText = ''.obs;

  /// Custom CQ text for CQ button
  final cwCqText = ''.obs;

  /// Use German keyboard layout (Y/Z swapped)
  final useGermanKeyboard = false.obs;

  /// Stay awake / keep screen on
  final stayAwake = false.obs;

  void toggleStayAwake() {
    stayAwake.value = !stayAwake.value;
    if (stayAwake.value) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  void _loadContestMode() {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) {
      contestMode.value = false;
      return;
    }
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      contestMode.value = cs.contestMode == 1;
    } catch (_) {
      contestMode.value = false;
    }
  }

  Future<void> toggleContestMode() async {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) return;
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      final newValue = cs.contestMode == 1 ? 0 : 1;
      final updated = cs.copyWith(contestMode: newValue);
      await _dbController.updateCallsign(updated);
      contestMode.value = newValue == 1;
    } catch (_) {}
  }

  void toggleUseCounter() {
    useCounter.value = !useCounter.value;
  }

  void _loadCwPrePost() {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) {
      cwPreController.text = '';
      cwPostController.text = '';
      return;
    }
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      cwPreController.text = cs.cwPre;
      cwPostController.text = cs.cwPost;
    } catch (_) {
      cwPreController.text = '';
      cwPostController.text = '';
    }
  }

  Future<void> saveCwPre(String value) async {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) return;
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      final updated = cs.copyWith(cwPre: value);
      await _dbController.updateCallsign(updated);
    } catch (_) {}
  }

  Future<void> saveCwPost(String value) async {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) return;
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      final updated = cs.copyWith(cwPost: value);
      await _dbController.updateCallsign(updated);
    } catch (_) {}
  }

  void _loadCwCustomText() {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) {
      cwCustomText.value = '';
      return;
    }
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      cwCustomText.value = cs.cwCustomText;
    } catch (_) {
      cwCustomText.value = '';
    }
  }

  void _loadCwCqText() {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) {
      cwCqText.value = '';
      return;
    }
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      cwCqText.value = cs.cwCqText;
    } catch (_) {
      cwCqText.value = '';
    }
  }

  void _loadGermanKeyboard() {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) {
      useGermanKeyboard.value = false;
      return;
    }
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      useGermanKeyboard.value = cs.useGermanKeyboard == 1;
    } catch (_) {
      useGermanKeyboard.value = false;
    }
  }

  /// Button layout as 3 rows of button IDs
  final buttonLayoutRows = Rx<List<List<String>>>([[], [], []]);

  void _loadButtonLayout() {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) {
      buttonLayoutRows.value = [
        ['CQ', 'MY', 'CALL', 'RPT', 'CUSTOM'],
        ['SEND', 'CLR', 'SAVE'],
        [],
      ];
      return;
    }
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      buttonLayoutRows.value = cs.buttonLayoutRows;
    } catch (_) {
      buttonLayoutRows.value = [
        ['CQ', 'MY', 'CALL', 'RPT', 'CUSTOM'],
        ['SEND', 'CLR', 'SAVE'],
        [],
      ];
    }
  }

  final callsignFocus = FocusNode();
  final rstInFocus = FocusNode();
  final rstOutFocus = FocusNode();
  final infoFocus = FocusNode();
  final xtra1Focus = FocusNode();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _updateDateTime();
    _updateUtcTime();
    _checkInternet();
    _utcTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateUtcTime(),
    );
    _internetTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkInternet(),
    );
    _initSelectedCallsign();
    _loadSavedLocator();
    ever(_dbController.callsignList, (_) => _initSelectedCallsign());
    // Save checkboxes when changed
    ever(useCounter, (_) {
      _saveCheckboxesToCallsign();
      _onUseCounterChanged();
    });
    ever(zeroIsT, (_) => _saveCheckboxesToCallsign());
    ever(nineIsN, (_) => _saveCheckboxesToCallsign());
    ever(sendK, (_) => _saveCheckboxesToCallsign());
    ever(sendBK, (_) => _saveCheckboxesToCallsign());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      callsignController.clear();
      callsignFocus.requestFocus();
    }
  }

  void _onUseCounterChanged() {
    if (useCounter.value) {
      _updateNextCounter();
    } else {
      xtra2Controller.clear();
    }
  }

  Future<void> _updateNextCounter() async {
    final lastNr = await _dbController.getLastQsoNr();
    if (lastNr == null || lastNr.isEmpty) {
      xtra2Controller.text = '001';
    } else {
      // Parse the number, increment, and format with leading zeros
      final parsed = int.tryParse(lastNr) ?? 0;
      final next = parsed + 1;
      xtra2Controller.text = next.toString().padLeft(3, '0');
    }
  }

  void _updateUtcTime() {
    final now = DateTime.now().toUtc();
    currentUtcTime.value =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _checkInternet() async {
    hasInternet.value = await ConnectivityService.hasInternetConnection();
  }

  void _loadSavedLocator() {
    final saved = _storage.read<String>('qth_locator');
    if (saved != null && saved.isNotEmpty) {
      locatorController.text = saved;
    }
  }

  void _saveLocator(String locator) {
    _storage.write('qth_locator', locator);
  }

  void _initSelectedCallsign() {
    if (myCallsigns.isNotEmpty) {
      if (selectedMyCallsign.value == null ||
          !myCallsigns.contains(selectedMyCallsign.value)) {
        selectedMyCallsign.value = myCallsigns.first;
      }
      // Ensure selected mode is valid for current callsign
      if (!modes.contains(selectedMode.value) && modes.isNotEmpty) {
        selectedMode.value = modes.first;
      }
      // Ensure selected band is valid for current callsign
      if (!bands.contains(selectedBand.value) && bands.isNotEmpty) {
        selectedBand.value = bands.first;
      }
      // Load checkbox values from callsign
      _loadCheckboxesFromCallsign();
      _loadHideDateTime();
      _loadShowSatellite();
      _loadContestMode();
      _loadCwPrePost();
      _loadCwCustomText();
      _loadCwCqText();
      _loadGermanKeyboard();
      _loadButtonLayout();
    } else {
      selectedMyCallsign.value = null;
    }
  }

  void _loadCheckboxesFromCallsign() {
    final callsign = selectedMyCallsign.value;
    if (callsign == null) return;
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      _isLoadingCheckboxes = true;
      useCounter.value = cs.useCounter == 1;
      zeroIsT.value = cs.zeroIsT == 1;
      nineIsN.value = cs.nineIsN == 1;
      sendK.value = cs.sendK == 1;
      sendBK.value = cs.sendBK == 1;
      singleRst.value = cs.singleRst == 1;
      _isLoadingCheckboxes = false;
      // Initialize counter if enabled
      if (useCounter.value) {
        _updateNextCounter();
      }
    } catch (_) {
      // Keep current values if callsign not found
    }
  }

  Future<void> _saveCheckboxesToCallsign() async {
    if (_isLoadingCheckboxes) return;
    final callsign = selectedMyCallsign.value;
    if (callsign == null) return;
    try {
      final cs = _dbController.callsignList.firstWhere(
        (c) => c.callsign == callsign,
      );
      final updated = cs.copyWith(
        useCounter: useCounter.value ? 1 : 0,
        zeroIsT: zeroIsT.value ? 1 : 0,
        nineIsN: nineIsN.value ? 1 : 0,
        sendK: sendK.value ? 1 : 0,
        sendBK: sendBK.value ? 1 : 0,
        singleRst: singleRst.value ? 1 : 0,
      );
      await _dbController.updateCallsign(updated);
    } catch (_) {
      // Ignore if callsign not found
    }
  }

  void _updateDateTime() {
    final now = DateTime.now().toUtc();
    dateController.text =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    timeController.text =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }

  void onBandChanged(String? value) {
    if (value != null) {
      selectedBand.value = value;
      _checkWorkedBefore();
    }
  }

  // Modes that use 599 rapport (RST with tone report)
  static const _modes599 = {'CW', 'RTTY', 'PSK'};

  void onModeChanged(String? value) {
    if (value != null) {
      selectedMode.value = value;
      if (_modes599.contains(value)) {
        rstInController.text = '599';
        rstOutController.text = '599';
      } else {
        rstInController.text = '59';
        rstOutController.text = '59';
      }
      _checkWorkedBefore();
    }
  }

  void onSatelliteChanged(String? value) {
    if (value != null) {
      selectedSatellite.value = value;
    }
  }

  void onMyCallsignChanged(String? value) {
    if (value != null) {
      selectedMyCallsign.value = value;
      // Reset mode if current mode is not available for new callsign
      if (!modes.contains(selectedMode.value)) {
        selectedMode.value = modes.first;
        onModeChanged(modes.first);
      }
      // Reset band if current band is not available for new callsign
      if (!bands.contains(selectedBand.value)) {
        selectedBand.value = bands.first;
      }
      // Load checkbox values from new callsign
      _loadCheckboxesFromCallsign();
      _loadHideDateTime();
      _loadShowSatellite();
      _loadContestMode();
      _loadCwPrePost();
      _loadCwCustomText();
      _loadCwCqText();
      _loadGermanKeyboard();
      _loadButtonLayout();
      _checkWorkedBefore();
    }
  }

  Future<void> submitQso() async {
    if (formKey.currentState?.validate() ?? false) {
      // Determine which external uploads are needed
      final needsLotw = useLotw && hasLotwKey;
      final needsClublog = useClublog && hasClublogCredentials;
      final needsEqsl = useEqsl && hasEqslCredentials;
      final needsExternalUpload = needsLotw || needsClublog || needsEqsl;

      // Check internet connectivity only if external uploads are needed
      bool hasInternet = true;
      if (needsExternalUpload) {
        hasInternet = await ConnectivityService.hasInternetConnection();
      }

      // Get contestId from selected activation
      String contestId = '';
      if (selectedActivationId.value != null) {
        final activation = _dbController.activationList.firstWhereOrNull(
          (a) => a.id == selectedActivationId.value,
        );
        if (activation != null) {
          contestId = activation.contestId;
        }
      }

      // Create QSO with failed flags set if no internet
      final qso = QsoModel(
        callsign: callsignController.text.toUpperCase(),
        received: receivedInfoController.text,
        xtra: xtra1Controller.text,
        qsonr: xtra2Controller.text,
        qsodate: dateController.text,
        qsotime: timeController.text,
        rstout: rstOutController.text,
        rstin: rstInController.text,
        band: selectedBand.value,
        mymode: selectedMode.value,
        myiota: '',
        mysota: '',
        mypota: '',
        gridsquare: locatorController.text,
        distance: '',
        clublogEqslCall: selectedMyCallsign.value ?? '',
        clublogstatus: '0',
        activationId: selectedActivationId.value,
        contestId: contestId,
        lotwFailed: (!hasInternet && needsLotw) ? 1 : 0,
        eqslFailed: (!hasInternet && needsEqsl) ? 1 : 0,
        clublogFailed: (!hasInternet && needsClublog) ? 1 : 0,
      );

      // Save to local database and get the ID
      final savedQso = await _dbController.addQsoAndReturn(qso);

      // Clear form immediately for fast UX
      clearForm();

      // Update counter after QSO is saved
      if (useCounter.value) {
        _updateNextCounter();
      }

      // Fire-and-forget async uploads (only if internet available)
      if (hasInternet && savedQso != null) {
        if (needsLotw) {
          _uploadToLotwAsync(savedQso);
        }
        if (needsClublog) {
          _uploadToClublogAsync(savedQso);
        }
        if (needsEqsl) {
          _uploadToEqslAsync(savedQso);
        }
      }
    }
  }

  (String, String) _getActivationData() {
    final activationId = selectedActivationId.value;
    if (activationId == null) return ('', '');

    try {
      final activation = _dbController.activationList.firstWhere(
        (a) => a.id == activationId,
      );
      return (activation.type, activation.reference);
    } catch (_) {
      return ('', '');
    }
  }

  /// Async LoTW upload - runs in background, updates failed flag on error
  void _uploadToLotwAsync(QsoModel qso) async {
    try {
      final myCall = selectedMyCallsign.value;
      if (myCall == null || myCall.isEmpty) return;

      final cs = _dbController.callsignList
          .where((c) => c.callsign == myCall)
          .firstOrNull;
      if (cs == null) return;

      final (activationType, activationReference) = _getActivationData();

      await LotwService.uploadQso(
        myCallsign: cs.callsign,
        dxCallsign: qso.callsign,
        band: qso.band,
        mode: qso.mymode,
        date: qso.qsodate,
        time: qso.qsotime,
        satellite: selectedSatellite.value,
        p12Base64: cs.lotwcert,
        p12Password: cs.lotwkey,
        lotwLogin: cs.lotwlogin,
        lotwPassword: cs.lotwpw,
        dxcc: '230',
        itu: cs.itu.isNotEmpty ? cs.itu : '28',
        cqzone: cs.cqzone.isNotEmpty ? cs.cqzone : '14',
        gridsquare: qso.gridsquare,
        rstSent: qso.rstout,
        rstRcvd: qso.rstin,
        activationType: activationType,
        activationReference: activationReference,
      );
      _triggerFlash(lotwFlash);
    } catch (e) {
      // Update failed flag in database
      if (qso.id != null) {
        final updatedQso = qso.copyWith(lotwFailed: 1);
        await _dbController.updateQso(updatedQso);
      }
      Get.snackbar(
        'LoTW Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Async ClubLog upload - runs in background, updates failed flag on error
  void _uploadToClublogAsync(QsoModel qso) async {
    try {
      final myCall = selectedMyCallsign.value;
      if (myCall == null || myCall.isEmpty) return;

      final cs = _dbController.callsignList
          .where((c) => c.callsign == myCall)
          .firstOrNull;
      if (cs == null) return;

      await ClublogService.uploadQso(
        myCallsign: cs.callsign,
        dxCallsign: qso.callsign,
        band: qso.band,
        mode: qso.mymode,
        date: qso.qsodate,
        time: qso.qsotime,
        rstSent: qso.rstout,
        rstRcvd: qso.rstin,
        clublogEmail: cs.clublogemail,
        clublogPassword: cs.clublogpw,
        notes: qso.xtra,
      );
      _triggerFlash(clublogFlash);
    } catch (e) {
      // Update failed flag in database
      if (qso.id != null) {
        final updatedQso = qso.copyWith(clublogFailed: 1);
        await _dbController.updateQso(updatedQso);
      }
      Get.snackbar(
        'ClubLog Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Async eQSL upload - runs in background, updates failed flag on error
  void _uploadToEqslAsync(QsoModel qso) async {
    try {
      final myCall = selectedMyCallsign.value;
      if (myCall == null || myCall.isEmpty) return;

      final cs = _dbController.callsignList
          .where((c) => c.callsign == myCall)
          .firstOrNull;
      if (cs == null) return;

      final (activationType, activationReference) = _getActivationData();

      await EqslService.uploadQso(
        myCallsign: cs.callsign,
        dxCallsign: qso.callsign,
        band: qso.band,
        mode: qso.mymode,
        date: qso.qsodate,
        time: qso.qsotime,
        rstSent: qso.rstout,
        rstRcvd: qso.rstin,
        eqslUser: cs.eqsluser,
        eqslPassword: cs.eqslpassword,
        qslMsg: qso.xtra,
        activationType: activationType,
        activationReference: activationReference,
      );
      _triggerFlash(eqslFlash);
    } catch (e) {
      // Update failed flag in database
      if (qso.id != null) {
        final updatedQso = qso.copyWith(eqslFailed: 1);
        await _dbController.updateQso(updatedQso);
      }
      Get.snackbar(
        'eQSL Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  void _triggerFlash(RxBool flashTrigger) {
    flashTrigger.value = true;
    Future.delayed(const Duration(milliseconds: 600), () {
      flashTrigger.value = false;
    });
  }

  void _checkWorkedBefore() {
    _workedBeforeDebounce?.cancel();
    _workedBeforeDebounce = Timer(const Duration(milliseconds: 300), () async {
      final callsign = callsignController.text.trim().toUpperCase();
      final myCall = selectedMyCallsign.value;
      if (callsign.isEmpty || myCall == null || myCall.isEmpty) {
        workedBefore.value = false;
        matchingQsos.clear();
        return;
      }

      // Check exact match for worked before (same band/mode)
      final exists = await _dbController.qsoExistsForMyCallsign(
        callsign,
        selectedBand.value,
        selectedMode.value,
        myCall,
      );
      workedBefore.value = exists;

      // Search for matching callsigns if 3+ characters
      if (callsign.length >= 3) {
        final matches = await _dbController.searchQsosByCallsignPart(
          callsign,
          myCall,
        );
        matchingQsos.assignAll(matches);
      } else {
        matchingQsos.clear();
      }
    });
  }

  /// Handle spacebar and comma in callsign field
  void onCallsignChanged(String value) {
    // Replace comma with slash
    if (value.contains(',')) {
      callsignController.text = value.replaceAll(',', '/');
      callsignController.selection = TextSelection.fromPosition(
        TextPosition(offset: callsignController.text.length),
      );
    }
    // Handle spacebar toggle
    if (useSpacebarToggle && value.contains(' ')) {
      callsignController.text = callsignController.text.replaceAll(' ', '');
      callsignController.selection = TextSelection.fromPosition(
        TextPosition(offset: callsignController.text.length),
      );
      infoFocus.requestFocus();
      setActiveTextField(receivedInfoController);
    }
    // CQ zone or ITU zone lookup
    if (useCqzones) {
      _lookupCqZone(callsignController.text);
    } else if (useItuzones) {
      _lookupItuZone(callsignController.text);
    }
    _checkWorkedBefore();
  }

  /// Look up CQ zone from callsign prefix
  void _lookupCqZone(String text) {
    if (text.isEmpty) {
      receivedInfoController.text = '';
      return;
    }
    // Regex to extract prefix from callsign (handles prefixes like DL1KVN/P)
    final reg = RegExp(
      r'([A-Z0-9]+[\/])?([A-Z][0-9]|[A-Z]{1,2}|[0-9][A-Z])([0-9]|[0-9]+)([A-Z]+)([\/][A-Z0-9]+)?',
    );
    final matches = reg.allMatches(text.toUpperCase());
    if (matches.isNotEmpty) {
      final match = matches.first;
      final prefix = match.group(2);
      if (prefix != null && prefix.isNotEmpty) {
        final cqzones = getCQZones();
        for (final zone in cqzones) {
          if (zone[1] == prefix) {
            receivedInfoController.text = zone[0].toString();
            return;
          }
        }
      }
    }
    receivedInfoController.text = '';
  }

  /// Look up ITU zone from callsign
  void _lookupItuZone(String text) {
    if (text.isEmpty) {
      receivedInfoController.text = '';
      return;
    }
    final ituZone = AmateurRadioCountryList.getItuZone(
      text.toUpperCase().trim(),
    );
    if (ituZone != null) {
      receivedInfoController.text = ituZone;
    } else {
      receivedInfoController.text = '';
    }
  }

  /// Handle spacebar in NR/INFO field
  void onInfoChanged(String value) {
    if (useSpacebarToggle && value.contains(' ')) {
      receivedInfoController.text = value.replaceAll(' ', '');
      receivedInfoController.selection = TextSelection.fromPosition(
        TextPosition(offset: receivedInfoController.text.length),
      );
      if (toggleSecondField) {
        xtra1Focus.requestFocus();
        setActiveTextField(xtra1Controller);
      } else {
        callsignFocus.requestFocus();
        setActiveTextField(callsignController);
      }
    }
  }

  /// Handle spacebar in Xtra1 field
  void onXtra1Changed(String value) {
    if (useSpacebarToggle && value.contains(' ')) {
      xtra1Controller.text = value.replaceAll(' ', '');
      xtra1Controller.selection = TextSelection.fromPosition(
        TextPosition(offset: xtra1Controller.text.length),
      );
      callsignFocus.requestFocus();
      setActiveTextField(callsignController);
    }
  }

  /// Get current GPS location and calculate Maidenhead locator
  Future<void> getLocator() async {
    isGettingLocation.value = true;
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'Location Error',
          'Location services are disabled',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        isGettingLocation.value = false;
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Location Error',
            'Location permission denied',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          isGettingLocation.value = false;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Location Error',
          'Location permission permanently denied',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        isGettingLocation.value = false;
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Calculate Maidenhead locator
      final locator = _calculateMaidenhead(
        position.latitude,
        position.longitude,
      );
      locatorController.text = locator;
      _saveLocator(locator);
    } catch (e) {
      Get.snackbar(
        'Location Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    isGettingLocation.value = false;
  }

  /// Calculate Maidenhead grid locator from latitude and longitude
  String _calculateMaidenhead(double lat, double lon) {
    // Normalize coordinates
    lon = lon + 180;
    lat = lat + 90;

    // First pair (field)
    final lonField = (lon / 20).floor();
    final latField = (lat / 10).floor();
    final field1 = String.fromCharCode(65 + lonField);
    final field2 = String.fromCharCode(65 + latField);

    // Second pair (square)
    lon = lon - (lonField * 20);
    lat = lat - (latField * 10);
    final lonSquare = (lon / 2).floor();
    final latSquare = lat.floor();

    // Third pair (subsquare)
    lon = lon - (lonSquare * 2);
    lat = lat - latSquare;
    final lonSub = (lon * 12).floor();
    final latSub = (lat * 24).floor();
    final sub1 = String.fromCharCode(97 + lonSub);
    final sub2 = String.fromCharCode(97 + latSub);

    return '$field1$field2$lonSquare$latSquare$sub1$sub2';
  }

  void clearForm() {
    formKey.currentState?.reset();
    callsignController.clear();
    receivedInfoController.clear();
    xtra1Controller.clear();
    // Don't clear locator - it's saved with GetStorage
    // Don't clear counter if useCounter is active
    if (!useCounter.value) {
      xtra2Controller.clear();
    }
    _updateDateTime();
    if (_modes599.contains(selectedMode.value)) {
      rstInController.text = '599';
      rstOutController.text = '599';
    } else {
      rstInController.text = '59';
      rstOutController.text = '59';
    }
    workedBefore.value = false;
    matchingQsos.clear();
    callsignFocus.requestFocus();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _utcTimer?.cancel();
    _internetTimer?.cancel();
    _workedBeforeDebounce?.cancel();
    callsignController.dispose();
    rstInController.dispose();
    rstOutController.dispose();
    receivedInfoController.dispose();
    xtra1Controller.dispose();
    xtra2Controller.dispose();
    dateController.dispose();
    timeController.dispose();
    locatorController.dispose();
    callsignFocus.dispose();
    rstInFocus.dispose();
    rstOutFocus.dispose();
    infoFocus.dispose();
    xtra1Focus.dispose();
    super.onClose();
  }

  // ========== CW Bluetooth Send Functions ==========

  /// Check if CW buttons should be visible (CW mode + Bluetooth connected)
  bool get showCwButtons {
    final btController = Get.find<BluetoothController>();
    return selectedMode.value == 'CW' && btController.isConnected.value;
  }

  /// Build the CW message string based on current form values
  String _buildCwMessage({required bool includeCallsign}) {
    final parts = <String>[];

    // Callsign (if included)
    if (includeCallsign && callsignController.text.isNotEmpty) {
      parts.add(callsignController.text.trim().toUpperCase());
    }

    // Pre text
    if (cwPreController.text.isNotEmpty) {
      parts.add(cwPreController.text.trim());
    }

    // RST out
    String rst = rstOutController.text;
    if (nineIsN.value) {
      rst = rst.replaceAll('9', 'N');
    }
    parts.add(rst);

    // Counter (qso nr)
    if (useCounter.value && xtra2Controller.text.isNotEmpty) {
      String count = xtra2Controller.text;
      if (zeroIsT.value) {
        count = count.replaceAll('0', 'T');
      }
      parts.add(count);
    }

    // Activation reference
    final activationId = selectedActivationId.value;
    if (activationId != null) {
      try {
        final activation = _dbController.activationList.firstWhere(
          (a) => a.id == activationId,
        );
        if (activation.reference.isNotEmpty) {
          final showRefPrefix = _storage.read<bool>('show_ref_prefix') ?? false;
          if (showRefPrefix) {
            parts.add(
              '${activation.type.toUpperCase()} ${activation.reference.replaceAll('-', '')}',
            );
          } else {
            parts.add(activation.reference.replaceAll('-', ''));
          }
        }
      } catch (_) {}
    }

    // Post text
    if (cwPostController.text.isNotEmpty) {
      parts.add(cwPostController.text.trim());
    }

    // BK suffix
    if (sendBK.value) {
      parts.add('BK');
    }

    return parts.join(' ');
  }

  /// Send callsign + RST + count via Bluetooth (SEND button)
  void sendCallPlusRprt() {
    if (callsignController.text.isEmpty) return;

    final btController = Get.find<BluetoothController>();
    final message = _buildCwMessage(includeCallsign: true);
    btController.sendMorseString(message);
    infoFocus.requestFocus();
  }

  /// Send RST + count without callsign via Bluetooth (RPT*# button)
  void sendRprtOnly() {
    if (callsignController.text.isEmpty) return;

    final btController = Get.find<BluetoothController>();
    final message = _buildCwMessage(includeCallsign: false);
    btController.sendMorseString(message);
    infoFocus.requestFocus();
  }

  /// Send my callsign via Bluetooth (MY button)
  void sendMyCall() {
    final myCall = selectedMyCallsign.value;
    if (myCall == null || myCall.isEmpty) return;

    final btController = Get.find<BluetoothController>();
    btController.sendMorseString(myCall);
    callsignFocus.requestFocus();
  }

  /// Send DX callsign or "?" via Bluetooth (CALL*? button)
  void sendHisCall() {
    final btController = Get.find<BluetoothController>();
    if (callsignController.text.isNotEmpty) {
      btController.sendMorseString(
        callsignController.text.trim().toUpperCase(),
      );
    } else {
      btController.sendMorseString('?');
    }
    callsignFocus.requestFocus();
  }

  // CQ double-click tracking
  DateTime _lastCqTime = DateTime.now();
  bool _wasLastCq = false;

  /// Send CQ via Bluetooth (CQ button)
  /// First click: "<cwCqText> <mycallsign>" or "CQ <mycallsign>" if cwCqText is empty
  /// Double click within 1 second: just "<mycallsign>"
  void sendCq() {
    final myCall = selectedMyCallsign.value;
    if (myCall == null || myCall.isEmpty) return;

    // Clear callsign field
    callsignController.clear();

    final btController = Get.find<BluetoothController>();
    final now = DateTime.now();

    String message;
    if (_wasLastCq && now.difference(_lastCqTime).inSeconds <= 1) {
      // Double click - send just callsign
      message = myCall;
      _wasLastCq = false;
    } else {
      // First click - send CQ text + callsign
      final cqText = cwCqText.value.isNotEmpty ? cwCqText.value : 'CQ';
      message = '$cqText $myCall';
      _wasLastCq = true;
    }
    _lastCqTime = now;

    btController.sendMorseString(message);
    callsignFocus.requestFocus();
  }

  /// Send custom CW text via Bluetooth
  void sendCwCustomText() {
    if (cwCustomText.value.isEmpty) return;

    final btController = Get.find<BluetoothController>();
    btController.sendMorseString(cwCustomText.value);
  }
}
