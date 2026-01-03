import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/database_controller.dart';
import '../controllers/qso_form_controller.dart';
import '../data/models/qso_model.dart';
import '../data/models/export_setting_model.dart';
import '../services/export_service.dart';
import 'export_settings_screen.dart';

class LogEntryScreen extends StatefulWidget {
  final int? initialActivationId;

  const LogEntryScreen({super.key, this.initialActivationId});

  @override
  State<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends State<LogEntryScreen> {
  final _dbController = Get.find<DatabaseController>();
  final _qsoFormController = Get.find<QsoFormController>();

  // Filter state
  String _selectedMyCallsign = 'All';
  String _selectedMode = 'All';
  String _selectedBand = 'All';
  int? _selectedActivationId; // null means "All"
  DateTime? _dateFrom;
  DateTime? _dateTo;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Pagination
  int _currentPage = 0;
  static const int _itemsPerPage = 20;

  static const List<String> _allModes = [
    'All',
    'CW',
    'SSB',
    'FM',
    'FT8',
    'FT4',
    'AM',
    'RTTY',
    'PSK',
    'DIGI',
  ];
  static const List<String> _allBands = [
    'All',
    '1.8',
    '3.5',
    '5',
    '7',
    '10',
    '14',
    '18',
    '21',
    '24',
    '28',
    '50',
    '144',
    '440',
  ];

  @override
  void initState() {
    super.initState();
    final currentCallsign = _qsoFormController.selectedMyCallsign.value;
    if (currentCallsign != null &&
        _dbController.callsignList.any((c) => c.callsign == currentCallsign)) {
      _selectedMyCallsign = currentCallsign;
    }
    if (widget.initialActivationId != null) {
      _selectedActivationId = widget.initialActivationId;
    }
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toUpperCase();
        _currentPage = 0;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<QsoModel> get _filteredQsos {
    var qsos = _dbController.qsoList.toList();

    // Filter by my callsign
    if (_selectedMyCallsign != 'All') {
      qsos = qsos
          .where((qso) => qso.clublogEqslCall == _selectedMyCallsign)
          .toList();
    }

    // Filter by mode
    if (_selectedMode != 'All') {
      qsos = qsos.where((qso) => qso.mymode == _selectedMode).toList();
    }

    // Filter by band
    if (_selectedBand != 'All') {
      qsos = qsos.where((qso) => qso.band == _selectedBand).toList();
    }

    // Filter by activation
    if (_selectedActivationId != null) {
      qsos = qsos.where((qso) => qso.activationId == _selectedActivationId).toList();
    }

    // Filter by callsign search
    if (_searchQuery.isNotEmpty) {
      qsos = qsos
          .where((qso) => qso.callsign.toUpperCase().contains(_searchQuery))
          .toList();
    }

    // Filter by date range
    if (_dateFrom != null) {
      final fromStr =
          '${_dateFrom!.year}${_dateFrom!.month.toString().padLeft(2, '0')}${_dateFrom!.day.toString().padLeft(2, '0')}';
      qsos = qsos.where((qso) => qso.qsodate.compareTo(fromStr) >= 0).toList();
    }
    if (_dateTo != null) {
      final toStr =
          '${_dateTo!.year}${_dateTo!.month.toString().padLeft(2, '0')}${_dateTo!.day.toString().padLeft(2, '0')}';
      qsos = qsos.where((qso) => qso.qsodate.compareTo(toStr) <= 0).toList();
    }

    return qsos;
  }

  int get _totalPages => (_filteredQsos.length / _itemsPerPage).ceil();

  List<QsoModel> get _paginatedQsos {
    final qsos = _filteredQsos;
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, qsos.length);
    if (start >= qsos.length) return [];
    return qsos.sublist(start, end);
  }

  Future<void> _pickDateFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFrom ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateFrom = picked;
        _currentPage = 0;
      });
    }
  }

  Future<void> _pickDateTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTo ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateTo = picked;
        _currentPage = 0;
      });
    }
  }

  String _formatDateButton(DateTime? date, String label) {
    if (date == null) return label;
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _clearFilters() {
    setState(() {
      _selectedMyCallsign = 'All';
      _selectedMode = 'All';
      _selectedBand = 'All';
      _selectedActivationId = null;
      _dateFrom = null;
      _dateTo = null;
      _searchController.clear();
      _searchQuery = '';
      _currentPage = 0;
    });
  }

  void _showExportDialog() {
    final exportSettings = _dbController.exportSettingList;
    final qsosToExport = _filteredQsos;

    if (exportSettings.isEmpty) {
      Get.snackbar(
        'No Export Settings',
        'Create an export setting first',
        snackPosition: SnackPosition.BOTTOM,
        mainButton: TextButton(
          onPressed: () => Get.to(() => const ExportSettingsScreen()),
          child: const Text('Create', style: TextStyle(color: Colors.white)),
        ),
      );
      return;
    }

    ExportSettingModel? selectedSetting = exportSettings.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Export QSOs'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${qsosToExport.length} QSOs will be exported'),
              const SizedBox(height: 16),
              const Text('Select export format:'),
              const SizedBox(height: 8),
              ...exportSettings.map((setting) {
                return RadioListTile<ExportSettingModel>(
                  title: Text(setting.name),
                  subtitle: Text(
                    '${setting.format.toUpperCase()} • ${setting.fieldsList.length} fields',
                  ),
                  value: setting,
                  groupValue: selectedSetting,
                  onChanged: (value) {
                    setDialogState(() => selectedSetting = value);
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add new setting'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                onTap: () {
                  Navigator.pop(context);
                  Get.to(() => const ExportSettingsScreen());
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: qsosToExport.isEmpty || selectedSetting == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      try {
                        await ExportService.exportAndShare(
                          qsosToExport,
                          selectedSetting!,
                        );
                      } catch (e) {
                        Get.snackbar(
                          'Export Error',
                          e.toString(),
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    },
              child: const Text('Export'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qlogger – Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export',
            onPressed: _showExportDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Export Settings',
            onPressed: () => Get.to(() => const ExportSettingsScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear filters',
            onPressed: _clearFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Row 1: Callsign search and My Callsign dropdown
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search Callsign',
                          prefixIcon: Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: Obx(() {
                        final callsigns = [
                          'All',
                          ..._dbController.callsignList.map((c) => c.callsign),
                        ];
                        if (!callsigns.contains(_selectedMyCallsign)) {
                          _selectedMyCallsign = 'All';
                        }
                        return DropdownButtonFormField<String>(
                          value: _selectedMyCallsign,
                          decoration: const InputDecoration(
                            labelText: 'My Call',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: callsigns.map((call) {
                            return DropdownMenuItem(
                              value: call,
                              child: Text(
                                call,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedMyCallsign = value;
                                _currentPage = 0;
                              });
                            }
                          },
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 2: Mode and Band dropdowns
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedMode,
                        decoration: const InputDecoration(
                          labelText: 'Mode',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: _allModes.map((mode) {
                          return DropdownMenuItem(
                            value: mode,
                            child: Text(mode),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedMode = value;
                              _currentPage = 0;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedBand,
                        decoration: const InputDecoration(
                          labelText: 'Band',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: _allBands.map((band) {
                          return DropdownMenuItem(
                            value: band,
                            child: Text(band == 'All' ? 'All' : '${band} MHz'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedBand = value;
                              _currentPage = 0;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Activation dropdown
                    Expanded(
                      child: Obx(() {
                        final activations = _dbController.activationList;
                        return DropdownButtonFormField<int?>(
                          value: _selectedActivationId,
                          decoration: const InputDecoration(
                            labelText: 'Activation',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('All'),
                            ),
                            ...activations.map((a) {
                              return DropdownMenuItem<int?>(
                                value: a.id,
                                child: Text(
                                  '${a.reference} ${a.type.toUpperCase()}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedActivationId = value;
                              _currentPage = 0;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.filter_alt_off),
                      tooltip: 'Reset filters',
                      onPressed: _clearFilters,
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 3: Date range
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDateFrom,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _formatDateButton(_dateFrom, 'From'),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDateTo,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _formatDateButton(_dateTo, 'To'),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    if (_dateFrom != null || _dateTo != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          setState(() {
                            _dateFrom = null;
                            _dateTo = null;
                            _currentPage = 0;
                          });
                        },
                        tooltip: 'Clear dates',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Obx(() {
              // Trigger rebuild when qsoList changes
              _dbController.qsoList.length;
              final total = _filteredQsos.length;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$total QSOs found',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_totalPages > 1)
                    Text(
                      'Page ${_currentPage + 1} of $_totalPages',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              );
            }),
          ),
          const Divider(height: 1),
          // QSO List
          Expanded(
            child: Obx(() {
              if (_dbController.isLoading.value &&
                  _dbController.qsoList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final qsos = _paginatedQsos;

              if (_filteredQsos.isEmpty) {
                return const Center(child: Text('No QSOs found'));
              }

              return ListView.builder(
                itemCount: qsos.length,
                itemBuilder: (context, index) {
                  final qso = qsos[index];
                  return _QsoListTile(
                    qso: qso,
                    onDelete: () => _dbController.deleteQso(qso.id!),
                    onEdit: (updated) => _dbController.updateQso(updated),
                  );
                },
              );
            }),
          ),
          // Legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Activation',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Failed upload',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // Pagination controls
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.first_page, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 28),
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage = 0)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 28),
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${_currentPage + 1} / $_totalPages',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 28),
                    onPressed: _currentPage < _totalPages - 1
                        ? () => setState(() => _currentPage++)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.last_page, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 28),
                    onPressed: _currentPage < _totalPages - 1
                        ? () => setState(() => _currentPage = _totalPages - 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QsoListTile extends StatelessWidget {
  final QsoModel qso;
  final VoidCallback onDelete;
  final Function(QsoModel) onEdit;

  const _QsoListTile({
    required this.qso,
    required this.onDelete,
    required this.onEdit,
  });

  String? _getActivationText() {
    if (qso.activationId == null) return null;
    final dbController = Get.find<DatabaseController>();
    final activation = dbController.activationList
        .firstWhereOrNull((a) => a.id == qso.activationId);
    if (activation == null) return null;
    return '${activation.reference} ${activation.type.toUpperCase()}';
  }

  List<String> _getFailedUploads() {
    final failed = <String>[];
    if (qso.lotwFailed == 1) failed.add('LoTW');
    if (qso.eqslFailed == 1) failed.add('eQSL');
    if (qso.clublogFailed == 1) failed.add('ClubLog');
    return failed;
  }

  @override
  Widget build(BuildContext context) {
    final activationText = _getActivationText();
    final failedUploads = _getFailedUploads();

    return Dismissible(
      key: Key(qso.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 5),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: qso.callsign,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '  '),
              TextSpan(
                text: '${qso.band} MHz ',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text: qso.mymode,
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text:
                    '  ${_formatDate(qso.qsodate)} ${_formatTime(qso.qsotime)}',
              ),
            ],
          ),
        ),
        subtitle: (activationText != null || failedUploads.isNotEmpty)
            ? Text.rich(
                TextSpan(
                  children: [
                    if (activationText != null)
                      TextSpan(
                        text: activationText,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    if (activationText != null && failedUploads.isNotEmpty)
                      const TextSpan(text: '  '),
                    if (failedUploads.isNotEmpty)
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 14,
                        ),
                      ),
                    if (failedUploads.isNotEmpty)
                      TextSpan(
                        text: ' ${failedUploads.join(', ')}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              )
            : null,
        trailing: GestureDetector(
          onTap: () => _showDeleteDialog(context),
          child: const Icon(Icons.delete_outline, size: 18),
        ),
        dense: true,
        visualDensity: const VisualDensity(vertical: -4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        onTap: () => _showEditDialog(context),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete QSO'),
        content: Text('Delete QSO with ${qso.callsign}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              onDelete();
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final callsignCtrl = TextEditingController(text: qso.callsign);
    final receivedCtrl = TextEditingController(text: qso.received);
    final xtraCtrl = TextEditingController(text: qso.xtra);
    final qsonrCtrl = TextEditingController(text: qso.qsonr);
    final rstinCtrl = TextEditingController(text: qso.rstin);
    final rstoutCtrl = TextEditingController(text: qso.rstout);

    String selectedBand = qso.band;
    String selectedMode = qso.mymode;
    DateTime? selectedDate;
    if (qso.qsodate.length == 8) {
      selectedDate = DateTime.tryParse(
        '${qso.qsodate.substring(0, 4)}-${qso.qsodate.substring(4, 6)}-${qso.qsodate.substring(6, 8)}',
      );
    }
    String timeStr = qso.qsotime;

    const bands = [
      '1.8',
      '3.5',
      '5',
      '7',
      '10',
      '14',
      '18',
      '21',
      '24',
      '28',
      '50',
      '144',
      '440',
    ];
    const modes = [
      'CW',
      'SSB',
      'FM',
      'FT8',
      'FT4',
      'AM',
      'RTTY',
      'PSK',
      'DIGI',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit QSO'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: callsignCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Callsign',
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: receivedCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nr/Info',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: xtraCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Xtra',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: bands.contains(selectedBand)
                            ? selectedBand
                            : bands.first,
                        decoration: const InputDecoration(
                          labelText: 'Band',
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: bands
                            .map(
                              (b) => DropdownMenuItem(
                                value: b,
                                child: Text('$b MHz'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setDialogState(
                          () => selectedBand = v ?? selectedBand,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: modes.contains(selectedMode)
                            ? selectedMode
                            : modes.first,
                        decoration: const InputDecoration(
                          labelText: 'Mode',
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: modes
                            .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)),
                            )
                            .toList(),
                        onChanged: (v) => setDialogState(
                          () => selectedMode = v ?? selectedMode,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        child: Text(
                          selectedDate != null
                              ? '${selectedDate!.day.toString().padLeft(2, '0')}.${selectedDate!.month.toString().padLeft(2, '0')}.${selectedDate!.year}'
                              : 'Date',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final initialTime = TimeOfDay(
                            hour: timeStr.length >= 2
                                ? int.tryParse(timeStr.substring(0, 2)) ?? 0
                                : 0,
                            minute: timeStr.length >= 4
                                ? int.tryParse(timeStr.substring(2, 4)) ?? 0
                                : 0,
                          );
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: initialTime,
                          );
                          if (picked != null) {
                            setDialogState(() {
                              timeStr =
                                  '${picked.hour.toString().padLeft(2, '0')}${picked.minute.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                        child: Text(
                          timeStr.length == 4
                              ? '${timeStr.substring(0, 2)}:${timeStr.substring(2, 4)}'
                              : 'Time',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qsonrCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Count',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: rstinCtrl,
                        decoration: const InputDecoration(
                          labelText: 'RST In',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: rstoutCtrl,
                        decoration: const InputDecoration(
                          labelText: 'RST Out',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final dateStr = selectedDate != null
                    ? '${selectedDate!.year}${selectedDate!.month.toString().padLeft(2, '0')}${selectedDate!.day.toString().padLeft(2, '0')}'
                    : qso.qsodate;
                final updated = qso.copyWith(
                  callsign: callsignCtrl.text.toUpperCase(),
                  received: receivedCtrl.text,
                  xtra: xtraCtrl.text,
                  qsonr: qsonrCtrl.text,
                  qsodate: dateStr,
                  qsotime: timeStr,
                  band: selectedBand,
                  mymode: selectedMode,
                  rstin: rstinCtrl.text,
                  rstout: rstoutCtrl.text,
                );
                onEdit(updated);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    if (date.length == 8) {
      return '${date.substring(6, 8)}.${date.substring(4, 6)}.${date.substring(2, 4)}';
    }
    return date;
  }

  String _formatTime(String time) {
    if (time.length == 4) {
      return '${time.substring(0, 2)}:${time.substring(2, 4)}';
    }
    return time;
  }
}
