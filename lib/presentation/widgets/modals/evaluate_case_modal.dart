import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../data/database/database_providers.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';
import '../buttons/buttons.dart';
import '../inputs/inputs.dart';

/// Modal bottom sheet for clinical supervisors and students to evaluate a [CaseRecord],
/// updating procedure status, assigning clinical grades/scores, and logging follow-up notes.
///
/// ### State Mutation & Invalidation:
/// Persists updates to the local SQLite database via [caseRecordRepositoryProvider.updateCaseRecord].
/// Upon successful persistence:
/// - [casesByPatientProvider] is invalidated to re-render the patient case sheet.
/// - [casesByRequirementProvider] is invalidated to refresh clinic requirement progress.
/// - [allCasesProvider] is invalidated to update total quota counts.
class EvaluateCaseModal extends ConsumerStatefulWidget {
  const EvaluateCaseModal({
    super.key,
    required this.caseRecord,
    this.patientName,
    this.onCaseEvaluated,
  });

  final CaseRecord caseRecord;
  final String? patientName;
  final ValueChanged<CaseRecord>? onCaseEvaluated;

  /// Convenience static helper to display the [EvaluateCaseModal].
  static Future<CaseRecord?> show(
    BuildContext context, {
    required CaseRecord caseRecord,
    String? patientName,
    ValueChanged<CaseRecord>? onCaseEvaluated,
  }) {
    AppLogger.info('Opened EvaluateCaseModal for case: ${caseRecord.id}');
    return showModalBottomSheet<CaseRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EvaluateCaseModal(
        caseRecord: caseRecord,
        patientName: patientName,
        onCaseEvaluated: onCaseEvaluated,
      ),
    );
  }

  @override
  ConsumerState<EvaluateCaseModal> createState() => _EvaluateCaseModalState();
}

class _EvaluateCaseModalState extends ConsumerState<EvaluateCaseModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _gradeController;
  late final TextEditingController _notesController;

  late String _selectedStatus;
  bool _isSubmitting = false;

  static const List<String> _statuses = <String>[
    'In Progress',
    'Evaluated',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = _statuses.contains(widget.caseRecord.status)
        ? widget.caseRecord.status
        : 'In Progress';

    // Parse existing grade if formatted as "Grade: <score>\n<notes>"
    final rawNotes = widget.caseRecord.notes ?? '';
    if (rawNotes.startsWith('Grade: ')) {
      final newlineIdx = rawNotes.indexOf('\n');
      if (newlineIdx != -1) {
        _gradeController = TextEditingController(
          text: rawNotes.substring(7, newlineIdx).trim(),
        );
        _notesController = TextEditingController(
          text: rawNotes.substring(newlineIdx + 1).trim(),
        );
      } else {
        _gradeController = TextEditingController(
          text: rawNotes.substring(7).trim(),
        );
        _notesController = TextEditingController();
      }
    } else {
      _gradeController = TextEditingController();
      _notesController = TextEditingController(text: rawNotes);
    }
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final grade = _gradeController.text.trim();
    final notes = _notesController.text.trim();

    String? combinedNotes;
    if (grade.isNotEmpty && notes.isNotEmpty) {
      combinedNotes = 'Grade: $grade\n$notes';
    } else if (grade.isNotEmpty) {
      combinedNotes = 'Grade: $grade';
    } else if (notes.isNotEmpty) {
      combinedNotes = notes;
    }

    final isDone = _selectedStatus == 'Completed' || _selectedStatus == 'Evaluated';
    final updatedCase = widget.caseRecord.copyWith(
      status: _selectedStatus,
      notes: combinedNotes,
      dateCompleted: isDone
          ? (widget.caseRecord.dateCompleted ?? DateTime.now())
          : null,
    );

    try {
      AppLogger.info(
        'Updating case record status to $_selectedStatus for case: ${widget.caseRecord.id}',
      );
      await ref.read(caseRecordRepositoryProvider).updateCaseRecord(updatedCase);

      ref.invalidate(casesByPatientProvider(widget.caseRecord.patientId));
      ref.invalidate(casesByRequirementProvider(widget.caseRecord.requirementId));
      ref.invalidate(allCasesProvider);

      widget.onCaseEvaluated?.call(updatedCase);

      if (mounted) {
        Navigator.of(context).pop(updatedCase);
      }
    } catch (e, st) {
      AppLogger.error('Failed to update case record: $e', e, st);
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to evaluate case record: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.only(
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
                    color: AppColors.outlineVariant,
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
                          'Evaluate Case Record',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.patientName != null
                              ? '${widget.patientName} • Case #${widget.caseRecord.id}'
                              : 'Case #${widget.caseRecord.id} (${widget.caseRecord.requirementId})',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.outline),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 0.8, color: AppColors.outlineVariant),

              // 3. Status Selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Procedure Status',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _statuses.map((status) {
                      final isSelected = _selectedStatus == status;
                      final isEvaluatedOrDone =
                          status == 'Evaluated' || status == 'Completed';
                      final activeColor = isEvaluatedOrDone
                          ? AppColors.secondary
                          : AppColors.primary;

                      return ChoiceChip(
                        label: Text(
                          status,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: activeColor,
                        backgroundColor: AppColors.surfaceContainerLow,
                        side: BorderSide(
                          color: isSelected ? activeColor : AppColors.outlineVariant,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedStatus = status);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Grade / Score Input
              DenteraTextField(
                controller: _gradeController,
                label: 'Grade / Score (Optional)',
                hintText: 'e.g., 9.0/10, Pass, A',
                prefixIcon: const Icon(Icons.grade_outlined, size: 20),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),

              // 5. Clinical Notes & Feedback
              DenteraTextField(
                controller: _notesController,
                label: 'Clinical Notes & Evaluation Remarks',
                hintText: 'e.g., Margins well-adapted, patient tolerated procedure well...',
                prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // 6. Action Buttons
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
                      text: _isSubmitting ? 'Saving...' : 'Save Evaluation',
                      icon: const Icon(Icons.check_rounded, size: 18, color: AppColors.onPrimary),
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
}
