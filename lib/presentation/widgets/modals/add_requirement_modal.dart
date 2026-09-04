import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../data/database/database_providers.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';
import '../buttons/buttons.dart';
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
    this.onRequirementAdded,
  });

  final String clinicId;
  final String? clinicName;
  final ValueChanged<Requirement>? onRequirementAdded;

  /// Convenience static method to show the AddRequirementModal bottom sheet.
  static Future<Requirement?> show(
    BuildContext context, {
    required String clinicId,
    String? clinicName,
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
        onRequirementAdded: onRequirementAdded,
      ),
    );
  }

  @override
  ConsumerState<AddRequirementModal> createState() => _AddRequirementModalState();
}

class _AddRequirementModalState extends ConsumerState<AddRequirementModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _quotaController = TextEditingController(text: '5');

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _quotaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final title = _titleController.text.trim();
    final targetCount = int.parse(_quotaController.text.trim());
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final reqId = 'req-${slug.isNotEmpty ? slug : 'case'}-${DateTime.now().millisecondsSinceEpoch % 10000}';

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
      AppLogger.error('Failed to create requirement: $e', e, st);
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create requirement: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final clinicDisplayName = widget.clinicName ?? 'Clinic';

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
                          'Add Requirement',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Define procedural quota for $clinicDisplayName',
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

              // 3. Requirement Title Field
              DenteraTextField(
                controller: _titleController,
                label: 'Requirement Title',
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

              // 4. Target Quota Count Field
              DenteraTextField(
                controller: _quotaController,
                label: 'Target Quota Count',
                hintText: 'e.g., 5',
                prefixIcon: const Icon(Icons.track_changes_rounded, size: 20),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter target quota';
                  }
                  final count = int.tryParse(value.trim());
                  if (count == null || count <= 0) {
                    return 'Quota must be greater than 0';
                  }
                  if (count > 999) {
                    return 'Quota count cannot exceed 999';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

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
                      text: _isSubmitting ? 'Saving...' : 'Save Requirement',
                      icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.onPrimary),
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
