import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../data/database/database_providers.dart';
import '../../../domain/constants/dental_catalog.dart';
import '../../../domain/entities/entities.dart';
import '../../../l10n/l10n.dart';
import '../../state/state.dart';
import '../buttons/buttons.dart';
import '../dentera_snackbar.dart';
import '../inputs/inputs.dart';

/// Bottom sheet modal to define and append a new procedural requirement to a clinic.
///
/// Captures the requirement's clinical procedure title and required target quota.
/// Persists directly to the local SQLite database via [requirementRepositoryProvider],
/// maintaining foreign key constraints with the parent [clinicId], and invalidates
/// [requirementsByClinicProvider] and [allRequirementsProvider] so departmental and
/// global quota progress recalculate immediately without page reloads.
class AddRequirementModal extends ConsumerStatefulWidget {
  const AddRequirementModal({
    super.key,
    required this.clinicId,
    this.clinicName,
    this.initialProcedure,
    this.onRequirementAdded,
  });

  final String clinicId;
  final String? clinicName;
  final String? initialProcedure;
  final ValueChanged<Requirement>? onRequirementAdded;

  /// Convenience static method to show the AddRequirementModal bottom sheet.
  static Future<Requirement?> show(
    BuildContext context, {
    required String clinicId,
    String? clinicName,
    String? initialProcedure,
    ValueChanged<Requirement>? onRequirementAdded,
  }) {
    AppLogger.info('Opened AddRequirementModal for clinic: $clinicId');
    return showModalBottomSheet<Requirement>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddRequirementModal(
        clinicId: clinicId,
        clinicName: clinicName,
        initialProcedure: initialProcedure,
        onRequirementAdded: onRequirementAdded,
      ),
    );
  }

  /// Synchronously validates the target quota count for a clinic requirement.
  ///
  /// **Business Rules & Data Integrity:**
  /// - Field cannot be empty (`'Please enter target quota'`).
  /// - Must parse to a valid integer (`'Quota must be a valid number'`).
  /// - Explicitly blocks negative numbers (`count < 0`); logs a warning and returns `'Quota cannot be negative'`.
  /// - Requires strictly positive target count (`count == 0`); logs a warning and returns `'Quota must be greater than 0'`.
  /// - Enforces maximum quota cap (`count > 999`); logs a warning and returns `'Quota count cannot exceed 999'`.
  ///
  /// Enforces valid quota targets prior to SQLite record creation.
  static String? validateQuota(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter target quota';
    }
    final count = int.tryParse(value.trim());
    if (count == null) {
      AppLogger.warning('Validation failed: Quota target must be a valid integer ("$value")');
      return 'Quota must be a valid number';
    }
    if (count < 0) {
      AppLogger.warning('Validation failed: Quota target cannot be negative ($count)');
      return 'Quota cannot be negative';
    }
    if (count == 0) {
      AppLogger.warning('Validation failed: Quota target must be greater than 0');
      return 'Quota must be greater than 0';
    }
    if (count > 999) {
      AppLogger.warning('Validation failed: Quota count exceeds limit of 999 ($count)');
      return 'Quota count cannot exceed 999';
    }
    return null;
  }

  @override
  ConsumerState<AddRequirementModal> createState() => _AddRequirementModalState();
}

class _AddRequirementModalState extends ConsumerState<AddRequirementModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _quotaController = TextEditingController(text: '5');

  late String _selectedProcedure;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedProcedure = widget.initialProcedure ?? DentalCatalog.otherOption;
    if (_selectedProcedure != DentalCatalog.otherOption) {
      _titleController.text = _selectedProcedure;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quotaController.dispose();
    super.dispose();
  }

  String? _resolveClinicName() {
    if (widget.clinicName != null && widget.clinicName!.trim().isNotEmpty) {
      return widget.clinicName!.trim();
    }
    final clinics = ref.read(clinicListProvider).valueOrNull;
    if (clinics != null) {
      final clinic = clinics.where((c) => c.id == widget.clinicId).firstOrNull;
      if (clinic != null) return clinic.name;
    }
    return null;
  }

  Future<void> _submit() async {
    final clinicName = _resolveClinicName();
    final isStandardClinic = DentalCatalog.isStandardDepartment(clinicName);
    final isOther = !isStandardClinic || _selectedProcedure == DentalCatalog.otherOption;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final title = isOther ? _titleController.text.trim() : _selectedProcedure;
    final targetCount = int.parse(_quotaController.text.trim());

    // Generate collision-free UUID v4 for the new requirement record.
    // Offline-first SQLite requires client-side primary key generation that guarantees
    // global uniqueness without requiring a central server or roundtrip network coordination.
    final reqId = const Uuid().v4();
    AppLogger.debug('Generated collision-free UUID [$reqId] for new requirement record.');

    final newReq = Requirement(
      id: reqId,
      clinicId: widget.clinicId,
      title: title,
      targetCount: targetCount,
      completedCount: 0,
    );

    try {
      AppLogger.info('Creating new requirement for clinic ${widget.clinicId}: ${newReq.title} (Target: ${newReq.targetCount})');
      await ref.read(requirementRepositoryProvider).addRequirement(newReq);
      ref.invalidate(requirementsByClinicProvider(widget.clinicId));
      ref.invalidate(allRequirementsProvider);

      widget.onRequirementAdded?.call(newReq);

      if (mounted) {
        Navigator.of(context).pop(newReq);
      }
    } catch (e, st) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        DenteraSnackBar.showError(
          context,
          message: 'Failed to create requirement',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final resolvedClinicName = _resolveClinicName();
    final clinicDisplayName = resolvedClinicName ?? widget.clinicName ?? 'Clinic';
    final isStandardClinic = DentalCatalog.isStandardDepartment(resolvedClinicName);
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
                          context.l10n.addRequirement,
                          style: AppTextStyles.h2.copyWith(
                            color: isDark ? AppDarkColors.tealAccent : AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${context.l10n.defineProceduralQuota} ($clinicDisplayName)',
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

              // 3. Procedure / Requirement Selection
              if (isStandardClinic) ...[
                // Predefined procedure dropdown with "Other..." option
                DenteraDropdown<String>(
                  label: context.l10n.procedureRequirement,
                  value: _selectedProcedure,
                  prefixIcon: const Icon(Icons.assignment_outlined, size: 20),
                  items: DentalCatalog.getProcedureOptionsForDepartment(resolvedClinicName!)
                      .map(
                        (proc) => DropdownMenuItem<String>(
                          value: proc,
                          child: Text(proc),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedProcedure = val;
                        if (val != DentalCatalog.otherOption) {
                          _titleController.text = val;
                        } else {
                          _titleController.clear();
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Custom Procedure Title (revealed when "Other..." is selected)
                if (_selectedProcedure == DentalCatalog.otherOption) ...[
                  DenteraTextField(
                    controller: _titleController,
                    label: context.l10n.customProcedureTitle,
                    hintText: 'e.g., Custom Implant Guide',
                    prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a requirement title';
                      }
                      if (value.trim().length < 3) {
                        return 'Title must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ] else ...[
                // Free-text input for clinics created under "Other..."
                DenteraTextField(
                  controller: _titleController,
                  label: context.l10n.requirementTitle,
                  hintText: 'e.g., Complete Denture or Class II Amalgam',
                  prefixIcon: const Icon(Icons.assignment_outlined, size: 20),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a requirement title';
                    }
                    if (value.trim().length < 3) {
                      return 'Title must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // 4. Target Quota Count Field
              DenteraTextField(
                controller: _quotaController,
                label: context.l10n.targetCountLabel,
                hintText: 'e.g., 5',
                prefixIcon: const Icon(Icons.track_changes_rounded, size: 20),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*')),
                ],
                validator: AddRequirementModal.validateQuota,
              ),
              const SizedBox(height: 28),

              // 5. Action Buttons
              Row(
                children: <Widget>[
                  Expanded(
                    child: SecondaryButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      text: context.l10n.cancel,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      text: _isSubmitting ? context.l10n.saving : context.l10n.saveRequirement,
                      icon: Icon(Icons.add_rounded, size: 18, color: isDark ? AppDarkColors.onTeal : AppColors.onPrimary),
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
