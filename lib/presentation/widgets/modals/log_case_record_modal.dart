import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../data/database/database_providers.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';
import '../buttons/buttons.dart';
import '../dentera_snackbar.dart';
import '../inputs/inputs.dart';

/// Modal bottom sheet allowing dental students to log a new clinical [CaseRecord] for a specific patient.
///
/// ### Relational Chaining Logic:
/// 1. **Clinic Department Selection:**
///    Watches [clinicListProvider] to display active dental departments (e.g., Prosthodontics, Endodontics).
/// 2. **Dynamic Requirement Cascading:**
///    When the user chooses a clinic, the requirement selector dynamically watches
///    [requirementsByClinicProvider] for that specific clinic ID, ensuring foreign key references
///    (`requirementId` and `clinicId`) adhere strictly to schema integrity without orphaned records.
/// 3. **Status & Procedural Notes:**
///    Captures the initial case status ('In Progress', 'Evaluated', or 'Completed') and clinical evaluation notes.
///
/// ### State Mutation & Invalidation:
/// Persists the new [CaseRecord] to SQLite via [caseRecordRepositoryProvider.addCaseRecord].
/// Invalidates [casesByPatientProvider], [casesByRequirementProvider], and [allCasesProvider]
/// so all clinical case sheets and quota calculations refresh reactively across the entire application.
class LogCaseRecordModal extends ConsumerStatefulWidget {
  const LogCaseRecordModal({
    super.key,
    required this.patientId,
    this.patientName,
    this.caseRecord,
    this.initialClinicId,
    this.initialNotes,
    this.onCaseLogged,
  });

  final String patientId;
  final String? patientName;
  final CaseRecord? caseRecord;
  final String? initialClinicId;
  final String? initialNotes;
  final ValueChanged<CaseRecord>? onCaseLogged;

  /// Convenience static helper to display the [LogCaseRecordModal].
  static Future<CaseRecord?> show(
    BuildContext context, {
    required String patientId,
    String? patientName,
    CaseRecord? caseRecord,
    String? initialClinicId,
    String? initialNotes,
    ValueChanged<CaseRecord>? onCaseLogged,
  }) {
    AppLogger.info('Opened LogCaseRecordModal for patient: $patientId (editing: ${caseRecord != null})');
    return showModalBottomSheet<CaseRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LogCaseRecordModal(
        patientId: patientId,
        patientName: patientName,
        caseRecord: caseRecord,
        initialClinicId: initialClinicId,
        initialNotes: initialNotes,
        onCaseLogged: onCaseLogged,
      ),
    );
  }

  @override
  ConsumerState<LogCaseRecordModal> createState() => _LogCaseRecordModalState();
}

class _LogCaseRecordModalState extends ConsumerState<LogCaseRecordModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _notesController;

  String? _selectedClinicId;
  String? _selectedRequirementId;
  String _selectedStatus = 'In Progress';
  bool _isSubmitting = false;

  int _plannedVisitsCount = 1;
  final List<TextEditingController> _visitLabelControllers = [];
  List<CaseVisit> _existingVisits = [];

  static const List<String> _statuses = <String>[
    'In Progress',
    'Evaluated',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.caseRecord?.notes ?? widget.initialNotes ?? '',
    );
    _selectedClinicId = widget.initialClinicId;
    if (widget.caseRecord != null) {
      _selectedRequirementId = widget.caseRecord!.requirementId;
      _selectedStatus = widget.caseRecord!.status;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingData());
    } else {
      _visitLabelControllers.add(TextEditingController(text: 'Visit 1'));
    }
  }

  Future<void> _loadExistingData() async {
    if (widget.caseRecord == null) return;
    try {
      final reqs = await ref.read(allRequirementsProvider.future);
      final req = reqs.where((r) => r.id == widget.caseRecord!.requirementId).firstOrNull;
      if (req != null && mounted) {
        setState(() {
          _selectedClinicId = req.clinicId;
        });
      }

      final visits = await ref.read(caseVisitRepositoryProvider).getVisitsByCaseRecordId(widget.caseRecord!.id);
      if (mounted) {
        setState(() {
          _existingVisits = visits;
          if (visits.isNotEmpty) {
            _plannedVisitsCount = visits.length.clamp(1, 10);
            for (final c in _visitLabelControllers) {
              c.dispose();
            }
            _visitLabelControllers.clear();
            for (final v in visits) {
              _visitLabelControllers.add(TextEditingController(text: v.title));
            }
          } else {
            if (_visitLabelControllers.isEmpty) {
              _visitLabelControllers.add(TextEditingController(text: 'Visit 1'));
            }
          }
        });
      }
    } catch (_) {}
  }

  void _onPlannedVisitsChanged(int count) {
    setState(() {
      _plannedVisitsCount = count;
      while (_visitLabelControllers.length < count) {
        final num = _visitLabelControllers.length + 1;
        _visitLabelControllers.add(TextEditingController(text: 'Visit $num'));
      }
      while (_visitLabelControllers.length > count) {
        _visitLabelControllers.removeLast().dispose();
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final c in _visitLabelControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Persists the new clinical [CaseRecord] to SQLite.
  ///
  /// **Imperative Action Errors vs. Reactive Stream Error Boundaries:**
  /// Logging a case record is an imperative mutation action. If SQLite encounters
  /// an edge case failure (such as [DatabaseLockedException] or [DataWriteException]),
  /// replacing the input form with a full error screen would destroy uncommitted user inputs.
  /// Instead, catching the exception within this `try/catch` block surfaces a transient
  /// [DenteraSnackBar.showError], keeping the modal open and preserving entered clinical notes
  /// for immediate retry while recording diagnostic details through [AppLogger.error].
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRequirementId == null || _selectedRequirementId!.isEmpty) {
      DenteraSnackBar.showError(
        context,
        message: 'Please select a procedural requirement',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final notesText = _notesController.text.trim();
    final isDone = _selectedStatus == 'Completed' || _selectedStatus == 'Evaluated';
    final isEditing = widget.caseRecord != null;

    final caseId = isEditing ? widget.caseRecord!.id : const Uuid().v4();
    AppLogger.debug('Processing clinical case record [$caseId] (editing: $isEditing)');

    final caseRecord = CaseRecord(
      id: caseId,
      patientId: widget.patientId,
      requirementId: _selectedRequirementId!,
      status: _selectedStatus,
      notes: notesText.isNotEmpty ? notesText : null,
      dateStarted: isEditing ? widget.caseRecord!.dateStarted : DateTime.now(),
      dateCompleted: isDone
          ? (isEditing ? (widget.caseRecord!.dateCompleted ?? DateTime.now()) : DateTime.now())
          : null,
    );

    try {
      if (isEditing) {
        AppLogger.info('Updating case record: $caseId (status: $_selectedStatus)');
        await ref.read(caseRecordRepositoryProvider).updateCaseRecord(caseRecord);
      } else {
        AppLogger.info(
          'Logged new case record for patient ${widget.patientId} under requirement: ${_selectedRequirementId!} (status: $_selectedStatus)',
        );
        await ref.read(caseRecordRepositoryProvider).addCaseRecord(caseRecord);
      }

      // Persist planned visits
      final visitsToPersist = <CaseVisit>[];
      for (int i = 0; i < _plannedVisitsCount; i++) {
        final title = _visitLabelControllers[i].text.trim().isNotEmpty
            ? _visitLabelControllers[i].text.trim()
            : 'Visit ${i + 1}';
        final existing = i < _existingVisits.length ? _existingVisits[i] : null;
        final isFirstDone = !isEditing && i == 0 && isDone;

        visitsToPersist.add(CaseVisit(
          id: existing?.id ?? const Uuid().v4(),
          caseRecordId: caseId,
          visitNumber: i + 1,
          title: title,
          status: existing?.status ?? (isFirstDone ? 'Completed' : 'Pending'),
          notes: existing?.notes ?? (isFirstDone && notesText.isNotEmpty ? notesText : null),
          dateScheduled: existing?.dateScheduled,
          dateCompleted: existing?.dateCompleted ?? (isFirstDone ? DateTime.now() : null),
        ));
      }

      // If editing and visits shrank, delete removed visits
      for (int i = _plannedVisitsCount; i < _existingVisits.length; i++) {
        await ref.read(caseVisitRepositoryProvider).deleteCaseVisit(_existingVisits[i].id);
      }

      await ref.read(caseVisitRepositoryProvider).addCaseVisits(visitsToPersist);

      ref.invalidate(casesByPatientProvider(widget.patientId));
      ref.invalidate(casesByRequirementProvider(_selectedRequirementId!));
      ref.invalidate(allCasesProvider);
      ref.invalidate(caseVisitsByCaseRecordProvider(caseId));

      widget.onCaseLogged?.call(caseRecord);

      if (mounted) {
        Navigator.of(context).pop(caseRecord);
      }
    } catch (e, st) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        DenteraSnackBar.showError(
          context,
          message: isEditing ? 'Failed to update clinical case' : 'Failed to log clinical case',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final clinicsAsync = ref.watch(clinicListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceContainer : AppColors.surfaceContainerLowest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.dragHandle : AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.caseRecord != null ? 'Edit Clinical Case' : 'Log Clinical Case',
                          style: AppTextStyles.h2.copyWith(
                            color: isDark ? AppDarkColors.tealAccent : AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.patientName != null
                              ? 'Record clinical procedure for ${widget.patientName}'
                              : 'Record clinical procedure for patient #${widget.patientId}',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppDarkColors.textSecondary : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: isDark ? AppDarkColors.textSecondary : AppColors.outline),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Divider(height: 24, thickness: 0.8, color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),

              // 3. Clinic Department Selector
              clinicsAsync.when(
                data: (clinics) {
                  if (clinics.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'No clinics available. Please create a clinic first.',
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
                      ),
                    );
                  }

                  // Default selected clinic if null or invalid
                  if (_selectedClinicId == null || !clinics.any((c) => c.id == _selectedClinicId)) {
                    _selectedClinicId = clinics.first.id;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      DenteraDropdown<String>(
                        label: 'Department / Clinic',
                        value: _selectedClinicId,
                        prefixIcon: const Icon(Icons.medical_services_outlined, size: 20),
                        items: clinics.map((clinic) {
                          return DropdownMenuItem<String>(
                            value: clinic.id,
                            child: Text(clinic.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedClinicId = val;
                              _selectedRequirementId = null; // Reset cascaded requirement
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // 4. Cascaded Requirements Selector
                      _buildRequirementSelector(_selectedClinicId!),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Failed to load clinics: $err',
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 5. Initial Status Dropdown
              DenteraDropdown<String>(
                label: 'Procedure Status',
                value: _selectedStatus,
                prefixIcon: const Icon(Icons.flag_outlined, size: 20),
                items: _statuses.map((st) {
                  return DropdownMenuItem<String>(
                    value: st,
                    child: Text(st),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedStatus = val);
                  }
                },
              ),
              const SizedBox(height: 16),

              // 5.5 Planned Number of Visits (1-10) & Labels
              DenteraDropdown<int>(
                label: 'Planned Number of Visits (1-10)',
                value: _plannedVisitsCount,
                prefixIcon: const Icon(Icons.repeat_rounded, size: 20),
                items: List.generate(10, (i) => i + 1).map((count) {
                  return DropdownMenuItem<int>(
                    value: count,
                    child: Text('$count ${count == 1 ? 'Visit' : 'Visits'}'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) _onPlannedVisitsChanged(val);
                },
              ),
              const SizedBox(height: 12),

              Text(
                'Visit Milestone Labels',
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(_plannedVisitsCount, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: DenteraTextField(
                    controller: _visitLabelControllers[index],
                    label: 'Visit ${index + 1} Label',
                    hintText: 'e.g., Visit ${index + 1}, Primary Impressions...',
                    prefixIcon: Icon(Icons.flag_outlined, size: 18, color: isDark ? AppDarkColors.textSecondary : AppColors.outline),
                  ),
                );
              }),
              const SizedBox(height: 8),

              // 6. Clinical Procedure Notes Field
              DenteraTextField(
                controller: _notesController,
                label: 'Clinical Notes / Findings',
                hintText: 'e.g., Primary impression completed, cavity prepared Class II...',
                prefixIcon: Icon(Icons.edit_note_rounded, size: 20, color: isDark ? AppDarkColors.textSecondary : AppColors.outline),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // 7. Action Buttons
              Row(
                children: <Widget>[
                  Expanded(
                    child: SecondaryButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      text: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      text: _isSubmitting
                          ? 'Saving...'
                          : (widget.caseRecord != null ? 'Update Case Record' : 'Log Case Record'),
                      icon: Icon(
                        widget.caseRecord != null ? Icons.save_outlined : Icons.add_rounded,
                        size: 18,
                        color: isDark ? AppDarkColors.onTeal : AppColors.onPrimary,
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementSelector(String clinicId) {
    final reqsAsync = ref.watch(requirementsByClinicProvider(clinicId));

    return reqsAsync.when(
      data: (requirements) {
        if (requirements.isEmpty) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppDarkColors.surfaceContainerHigh : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Text(
              'No procedural requirements defined for this clinic yet.',
              style: AppTextStyles.caption.copyWith(color: isDark ? AppDarkColors.textSecondary : AppColors.outline),
            ),
          );
        }

        // Default or sanitize selected requirement
        if (_selectedRequirementId == null ||
            !requirements.any((r) => r.id == _selectedRequirementId)) {
          _selectedRequirementId = requirements.first.id;
        }

        return DenteraDropdown<String>(
          label: 'Procedural Requirement',
          value: _selectedRequirementId,
          prefixIcon: const Icon(Icons.assignment_outlined, size: 20),
          items: requirements.map((req) {
            return DropdownMenuItem<String>(
              value: req.id,
              child: Text(
                '${req.title} (${req.completedCount}/${req.targetCount})',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedRequirementId = val);
            }
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      error: (err, _) => Text(
        'Failed to load requirements: $err',
        style: AppTextStyles.caption.copyWith(color: AppColors.error),
      ),
    );
  }
}
