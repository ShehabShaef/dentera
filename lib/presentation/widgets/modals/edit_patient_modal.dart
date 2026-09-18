import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../data/database/database_providers.dart';
import '../../../domain/entities/entities.dart';
import '../../../l10n/l10n.dart';
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
  late final TextEditingController _chiefComplaintController;
  late final TextEditingController _historyOfChiefComplaintController;
  late final TextEditingController _dentalHistoryController;
  late final TextEditingController _medicationsController;
  late final TextEditingController _diagnosticAidsController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient.name);
    _ageController = TextEditingController(text: widget.patient.age.toString());
    _phoneController = TextEditingController(text: widget.patient.phoneNumber ?? '');
    _medicalHistoryController = TextEditingController(text: widget.patient.medicalHistory ?? '');
    _chiefComplaintController = TextEditingController(text: widget.patient.chiefComplaint ?? '');
    _historyOfChiefComplaintController =
        TextEditingController(text: widget.patient.historyOfChiefComplaint ?? '');
    _dentalHistoryController = TextEditingController(text: widget.patient.dentalHistory ?? '');
    _medicationsController = TextEditingController(text: widget.patient.medications ?? '');
    _diagnosticAidsController = TextEditingController(text: widget.patient.diagnosticAids ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _medicalHistoryController.dispose();
    _chiefComplaintController.dispose();
    _historyOfChiefComplaintController.dispose();
    _dentalHistoryController.dispose();
    _medicationsController.dispose();
    _diagnosticAidsController.dispose();
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
      chiefComplaint: _chiefComplaintController.text.trim().isNotEmpty
          ? _chiefComplaintController.text.trim()
          : null,
      historyOfChiefComplaint: _historyOfChiefComplaintController.text.trim().isNotEmpty
          ? _historyOfChiefComplaintController.text.trim()
          : null,
      dentalHistory: _dentalHistoryController.text.trim().isNotEmpty
          ? _dentalHistoryController.text.trim()
          : null,
      medications: _medicationsController.text.trim().isNotEmpty
          ? _medicationsController.text.trim()
          : null,
      diagnosticAids: _diagnosticAidsController.text.trim().isNotEmpty
          ? _diagnosticAidsController.text.trim()
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                          context.l10n.editPatientProfile,
                          style: AppTextStyles.h2.copyWith(
                            color: isDark ? AppDarkColors.textPrimary : AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${context.l10n.updateDemographicsSubtitle} #${widget.patient.id}',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: isDark ? AppDarkColors.textMuted : AppColors.outline),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Divider(height: 24, thickness: 0.8, color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),

              // 3. Name Field
              DenteraTextField(
                controller: _nameController,
                label: context.l10n.fullName,
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
                      label: context.l10n.age,
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
                      label: context.l10n.phoneNumberLabel,
                      hintText: 'e.g., +967-771122334',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 20),
              Text(
                context.l10n.clinicalAnamnesisHistory,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              // Chief Complaint (CC)
              DenteraTextField(
                controller: _chiefComplaintController,
                label: context.l10n.chiefComplaint,
                hintText: 'e.g., Severe throbbing pain in upper right quadrant',
                prefixIcon: const Icon(Icons.record_voice_over_outlined, size: 20),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 14),

              // History of Chief Complaint (HCC)
              DenteraTextField(
                controller: _historyOfChiefComplaintController,
                label: context.l10n.historyOfChiefComplaint,
                hintText: 'e.g., Pain started 3 days ago, aggravated by cold stimuli',
                prefixIcon: const Icon(Icons.history_edu_outlined, size: 20),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 14),

              // Medical History & Allergies
              DenteraTextField(
                controller: _medicalHistoryController,
                label: context.l10n.medicalHistoryAndAllergies,
                hintText: 'e.g., Penicillin allergy, Hypertension, Diabetic...',
                prefixIcon: const Icon(Icons.medical_information_outlined, size: 20),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 14),

              // Dental History
              DenteraTextField(
                controller: _dentalHistoryController,
                label: context.l10n.dentalHistory,
                hintText: 'e.g., Past extractions, regular scaling, RCT 2 years ago',
                prefixIcon: const Icon(Icons.medical_services_outlined, size: 20),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 14),

              // Current Medications
              DenteraTextField(
                controller: _medicationsController,
                label: context.l10n.currentMedications,
                hintText: 'e.g., Amoxicillin 500mg, Metformin 500mg',
                prefixIcon: const Icon(Icons.medication_outlined, size: 20),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 14),

              // Diagnostic Aids
              DenteraTextField(
                controller: _diagnosticAidsController,
                label: context.l10n.diagnosticAids,
                hintText: 'e.g., Periapical radiograph tooth #16, vitality test positive',
                prefixIcon: const Icon(Icons.biotech_outlined, size: 20),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // 6. Action Buttons
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      text: _isSubmitting ? context.l10n.saving : context.l10n.saveChanges,
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
