import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';
import '../buttons/buttons.dart';
import '../dentera_snackbar.dart';

/// Modal bottom sheet to stage a new or edit an existing [TreatmentPlan] item.
class AddTreatmentPlanModal extends ConsumerStatefulWidget {
  const AddTreatmentPlanModal({
    super.key,
    required this.patientId,
    this.patientName,
    this.treatmentPlan,
    this.initialPhase,
    this.onPlanSaved,
  });

  final String patientId;
  final String? patientName;
  final TreatmentPlan? treatmentPlan;
  final int? initialPhase;
  final ValueChanged<TreatmentPlan>? onPlanSaved;

  /// Convenience helper to display [AddTreatmentPlanModal].
  static Future<TreatmentPlan?> show(
    BuildContext context, {
    required String patientId,
    String? patientName,
    TreatmentPlan? treatmentPlan,
    int? initialPhase,
    ValueChanged<TreatmentPlan>? onPlanSaved,
  }) {
    AppLogger.info(
      'Opened AddTreatmentPlanModal for patient: $patientId (editing: ${treatmentPlan != null})',
    );
    return showModalBottomSheet<TreatmentPlan>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTreatmentPlanModal(
        patientId: patientId,
        patientName: patientName,
        treatmentPlan: treatmentPlan,
        initialPhase: initialPhase,
        onPlanSaved: onPlanSaved,
      ),
    );
  }

  @override
  ConsumerState<AddTreatmentPlanModal> createState() => _AddTreatmentPlanModalState();
}

class _AddTreatmentPlanModalState extends ConsumerState<AddTreatmentPlanModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;

  late int _selectedPhase;
  String? _selectedClinicId;
  late String _selectedStatus;
  bool _isSubmitting = false;

  static const List<String> _statuses = <String>[
    TreatmentPlan.statusProposed,
    TreatmentPlan.statusApproved,
    TreatmentPlan.statusCompleted,
  ];

  @override
  void initState() {
    super.initState();
    final plan = widget.treatmentPlan;
    _selectedPhase = plan?.phase ?? widget.initialPhase ?? 1;
    _selectedClinicId = plan?.targetClinicId;
    _selectedStatus = plan?.status ?? TreatmentPlan.statusProposed;
    _titleController = TextEditingController(text: plan?.title ?? '');
    _notesController = TextEditingController(text: plan?.notes ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final isEditing = widget.treatmentPlan != null;
      final plan = TreatmentPlan(
        id: widget.treatmentPlan?.id ?? const Uuid().v4(),
        patientId: widget.patientId,
        phase: _selectedPhase,
        title: _titleController.text.trim(),
        status: _selectedStatus,
        targetClinicId: _selectedClinicId,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: widget.treatmentPlan?.createdAt ?? DateTime.now(),
      );

      final controller = ref.read(treatmentPlansControllerProvider);
      if (isEditing) {
        await controller.updatePlan(plan);
      } else {
        await controller.addPlan(plan);
      }

      widget.onPlanSaved?.call(plan);

      if (mounted) {
        Navigator.of(context).pop(plan);
        DenteraSnackBar.showSuccess(
          context,
          message: isEditing
              ? 'Treatment plan item updated successfully'
              : 'Treatment plan item staged for Phase $_selectedPhase',
        );
      }
    } catch (e) {
      AppLogger.error('Failed to save treatment plan', e);
      if (mounted) {
        setState(() => _isSubmitting = false);
        DenteraSnackBar.showError(
          context,
          message: 'Failed to save treatment plan: ${e.toString()}',
          error: e,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinicsAsync = ref.watch(clinicListProvider);
    final isEditing = widget.treatmentPlan != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceContainer : AppColors.surfaceContainerLowest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.dragHandle : AppColors.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                isEditing ? 'Edit Treatment Plan Item' : 'Stage Proposed Treatment',
                style: AppTextStyles.h1Mobile.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppDarkColors.tealAccent : AppColors.primary,
                ),
              ),
              if (widget.patientName != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Patient: ${widget.patientName}',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppDarkColors.textSecondary : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Academic Phase Selector
              Text(
                'Academic Treatment Phase',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _selectedPhase,
                dropdownColor: isDark ? AppDarkColors.surfaceContainer : null,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? AppDarkColors.inputFill : AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppDarkColors.tealAccent : AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: TreatmentPhase.values.map((phase) {
                  return DropdownMenuItem<int>(
                    value: phase.value,
                    child: Text(
                      phase.label,
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppDarkColors.textPrimary : null,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedPhase = val);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Proposed Procedure Title
              Text(
                'Proposed Procedure / Treatment Title',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g., Scaling & Root Planing, Anterior RCT, Class II Composite',
                  filled: true,
                  fillColor: isDark ? AppDarkColors.inputFill : AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppDarkColors.tealAccent : AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a treatment procedure title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Target Department / Clinic
              Text(
                'Target Clinical Department (Optional)',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              clinicsAsync.when(
                data: (clinics) {
                  return DropdownButtonFormField<String?>(
                    initialValue: _selectedClinicId,
                    dropdownColor: isDark ? AppDarkColors.surfaceContainer : null,
                    decoration: InputDecoration(
                      hintText: 'General / Interdisciplinary',
                      filled: true,
                      fillColor: isDark ? AppDarkColors.inputFill : AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppDarkColors.tealAccent : AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'General / Interdisciplinary',
                          style: TextStyle(color: isDark ? AppDarkColors.textPrimary : null),
                        ),
                      ),
                      ...clinics.map((clinic) {
                        return DropdownMenuItem<String?>(
                          value: clinic.id,
                          child: Text(
                            clinic.name,
                            style: TextStyle(color: isDark ? AppDarkColors.textPrimary : null),
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedClinicId = val),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Text('Failed to load clinic departments'),
              ),
              const SizedBox(height: 16),

              // Status Selector
              Text(
                'Treatment Status',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                dropdownColor: isDark ? AppDarkColors.surfaceContainer : null,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? AppDarkColors.inputFill : AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppDarkColors.tealAccent : AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _statuses.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(
                      status,
                      style: TextStyle(color: isDark ? AppDarkColors.textPrimary : null),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedStatus = val);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Clinical Notes
              Text(
                'Clinical Notes / Faculty Instructions',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add clinical justification, tooth numbers, or supervisor notes...',
                  filled: true,
                  fillColor: isDark ? AppDarkColors.inputFill : AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppDarkColors.tealAccent : AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: <Widget>[
                  Expanded(
                    child: SecondaryButton(
                      text: 'Cancel',
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      text: _isSubmitting
                          ? 'Saving...'
                          : isEditing
                              ? 'Update Treatment'
                              : 'Stage Treatment',
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _handleSubmit,
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
