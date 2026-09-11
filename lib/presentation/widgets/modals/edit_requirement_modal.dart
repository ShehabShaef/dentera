import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../data/database/database_providers.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';
import '../buttons/buttons.dart';
import '../dentera_snackbar.dart';
import '../inputs/inputs.dart';
import 'add_requirement_modal.dart';

/// Modal bottom sheet to edit an existing academic clinical requirement.
///
/// Allows in-place editing of the procedure title and target quota count.
/// Persists directly to the local SQLite database via [requirementRepositoryProvider.updateRequirement]
/// and invalidates [requirementsByClinicProvider] and [allRequirementsProvider] to recalculate
/// quota progress across departmental and global dashboards immediately.
class EditRequirementModal extends ConsumerStatefulWidget {
  const EditRequirementModal({
    super.key,
    required this.requirement,
    this.onRequirementUpdated,
  });

  final Requirement requirement;
  final ValueChanged<Requirement>? onRequirementUpdated;

  /// Convenience static helper to show the [EditRequirementModal] bottom sheet.
  static Future<Requirement?> show(
    BuildContext context, {
    required Requirement requirement,
    ValueChanged<Requirement>? onRequirementUpdated,
  }) {
    AppLogger.info('Opened EditRequirementModal for requirement: ${requirement.id}');
    return showModalBottomSheet<Requirement>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditRequirementModal(
        requirement: requirement,
        onRequirementUpdated: onRequirementUpdated,
      ),
    );
  }

  @override
  ConsumerState<EditRequirementModal> createState() => _EditRequirementModalState();
}

class _EditRequirementModalState extends ConsumerState<EditRequirementModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _quotaController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.requirement.title);
    _quotaController = TextEditingController(text: widget.requirement.targetCount.toString());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quotaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final updatedRequirement = widget.requirement.copyWith(
      title: _titleController.text.trim(),
      targetCount: int.parse(_quotaController.text.trim()),
    );

    try {
      AppLogger.info('Updating requirement: ${updatedRequirement.title} (${updatedRequirement.id})');
      await ref.read(requirementRepositoryProvider).updateRequirement(updatedRequirement);

      ref.invalidate(requirementsByClinicProvider(widget.requirement.clinicId));
      ref.invalidate(allRequirementsProvider);

      widget.onRequirementUpdated?.call(updatedRequirement);

      if (mounted) {
        Navigator.of(context).pop(updatedRequirement);
      }
    } catch (e, st) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        DenteraSnackBar.showError(
          context,
          message: 'Failed to update requirement',
          error: e,
          stackTrace: st,
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
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                            'Edit Requirement',
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Adjust procedure title and target quota',
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
                const Divider(height: 20, thickness: 0.8, color: AppColors.outlineVariant),

                // 3. Title Input
                Text(
                  'Procedure Title',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                DenteraTextField(
                  controller: _titleController,
                  hintText: 'e.g. Complete Denture',
                  prefixIcon: const Icon(Icons.medical_services_outlined, color: AppColors.outline),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Procedure title is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Procedure title must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 4. Target Quota Input
                Text(
                  'Target Quota Count',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                DenteraTextField(
                  controller: _quotaController,
                  hintText: 'e.g. 5',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  prefixIcon: const Icon(Icons.track_changes_rounded, color: AppColors.outline),
                  validator: AddRequirementModal.validateQuota,
                ),
                const SizedBox(height: 24),

                // 5. Action Buttons
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        text: _isSubmitting ? 'Saving...' : 'Save Changes',
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.onPrimary),
                        onPressed: _isSubmitting ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
