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

/// Modal bottom sheet for updating demographic and medical records of an existing [Patient].
///
/// ### Form Validation Logic:
/// - **Name:** Required, at least 2 characters long, capitalized as words.
/// - **Age:** Required, numeric digits only, clamped within clinical bounds (1 to 120).
/// - **Phone Number:** Optional, accepts formatted contact strings.
/// - **Medical History & Allergies:** Optional multiline field capturing systemic risks.
///
/// ### Relational SQLite Updates & State Invalidation:
/// Submitting mutations updates the row in the `patients` SQLite table via [patientRepositoryProvider.updatePatient].
/// Upon successful persistence:
/// - [patientByIdProvider(patient.id)] is invalidated to immediately refresh active case sheets.
/// - [patientListProvider] is invalidated to update the master patient roster and search filters.
class EditPatientModal extends ConsumerStatefulWidget {
  const EditPatientModal({
    super.key,
    required this.patient,
    this.onPatientUpdated,
  });

  final Patient patient;
  final ValueChanged<Patient>? onPatientUpdated;

  /// Convenience static helper to show the [EditPatientModal].
  static Future<Patient?> show(
    BuildContext context, {
    required Patient patient,
    ValueChanged<Patient>? onPatientUpdated,
  }) {
    AppLogger.info('Opened EditPatientModal for patient: ${patient.id}');
    return showModalBottomSheet<Patient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditPatientModal(
        patient: patient,
        onPatientUpdated: onPatientUpdated,
      ),
    );
  }

  @override
  ConsumerState<EditPatientModal> createState() => _EditPatientModalState();
}

class _EditPatientModalState extends ConsumerState<EditPatientModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _phoneController;
  late final TextEditingController _medicalHistoryController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient.name);
    _ageController = TextEditingController(text: widget.patient.age.toString());
    _phoneController = TextEditingController(text: widget.patient.phoneNumber ?? '');
    _medicalHistoryController = TextEditingController(text: widget.patient.medicalHistory ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _medicalHistoryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final updatedPatient = widget.patient.copyWith(
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      medicalHistory: _medicalHistoryController.text.trim().isNotEmpty
          ? _medicalHistoryController.text.trim()
          : null,
    );

    try {
      AppLogger.info('Updated patient details for: ${updatedPatient.name} (${updatedPatient.id})');
      await ref.read(patientRepositoryProvider).updatePatient(updatedPatient);

      ref.invalidate(patientByIdProvider(widget.patient.id));
      ref.invalidate(patientListProvider);

      widget.onPatientUpdated?.call(updatedPatient);

      if (mounted) {
        Navigator.of(context).pop(updatedPatient);
      }
    } catch (e, st) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        DenteraSnackBar.showError(
          context,
          message: 'Failed to update patient',
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
                          'Edit Patient Profile',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Update demographics and medical history for #${widget.patient.id}',
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

              // 3. Name Field
              DenteraTextField(
                controller: _nameController,
                label: 'Full Name',
                hintText: 'e.g., Ali Nasser',
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter patient name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 4. Age & Phone Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Age
                  SizedBox(
                    width: 100,
                    child: DenteraTextField(
                      controller: _ageController,
                      label: 'Age',
                      hintText: '25',
                      prefixIcon: const Icon(Icons.cake_outlined, size: 18),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final age = int.tryParse(value.trim());
                        if (age == null || age <= 0 || age > 120) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Phone
                  Expanded(
                    child: DenteraTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hintText: 'e.g., +967-771122334',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 5. Medical History & Systemic Conditions
              DenteraTextField(
                controller: _medicalHistoryController,
                label: 'Medical History & Allergies',
                hintText: 'e.g., Penicillin allergy, Hypertension, Diabetic...',
                prefixIcon: const Icon(Icons.medical_information_outlined, size: 20),
                maxLines: 3,
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
                      text: _isSubmitting ? 'Saving...' : 'Save Changes',
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
