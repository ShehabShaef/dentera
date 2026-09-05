import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../data/database/database_providers.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';
import '../buttons/buttons.dart';
import '../inputs/inputs.dart';

/// Rapid-entry bottom sheet modal for creating a new patient record.
class AddPatientModal extends ConsumerStatefulWidget {
  const AddPatientModal({
    super.key,
    this.onPatientAdded,
  });

  final ValueChanged<Patient>? onPatientAdded;

  /// Convenience static method to show the AddPatientModal bottom sheet.
  static Future<Patient?> show(
    BuildContext context, {
    ValueChanged<Patient>? onPatientAdded,
  }) {
    return showModalBottomSheet<Patient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPatientModal(onPatientAdded: onPatientAdded),
    );
  }

  /// Synchronously validates the patient age input.
  ///
  /// **Business Rules & Data Integrity:**
  /// - Age is a mandatory field (`'Enter age'`).
  /// - Input must parse to a valid signed 32-bit integer (`'Invalid'`).
  /// - Explicitly blocks negative values (`age < 0`); logs a warning and returns `'Cannot be negative'`.
  /// - Guards against unreasonable ages (`age > 130`); logs a warning and returns `'Invalid age'`.
  ///
  /// Prevents corrupt or nonsensical demographic data from entering the local SQLite database.
  static String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter age';
    }
    final age = int.tryParse(value.trim());
    if (age == null) {
      AppLogger.warning('Validation failed: Age must be a valid integer ("$value")');
      return 'Invalid';
    }
    if (age < 0) {
      AppLogger.warning('Validation failed: Attempted to enter negative age ($age)');
      return 'Cannot be negative';
    }
    if (age > 130) {
      AppLogger.warning('Validation failed: Age exceeds realistic limit ($age)');
      return 'Invalid age';
    }
    return null;
  }

  @override
  ConsumerState<AddPatientModal> createState() => _AddPatientModalState();
}

class _AddPatientModalState extends ConsumerState<AddPatientModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _medicalHistoryController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedClinic = 'Prosthodontics';
  bool _showOptionalDetails = false;

  static const List<String> _genders = <String>['Male', 'Female'];
  static const List<String> _clinics = <String>[
    'Prosthodontics',
    'Operative',
    'Endodontics',
    'Oral Surgery',
    'Periodontics',
    'Pediatric Dentistry',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _medicalHistoryController.dispose();
    super.dispose();
  }

  String _getClinicId(String clinicName) {
    switch (clinicName.toLowerCase()) {
      case 'prosthodontics':
        return 'clinic-prosth';
      case 'operative':
      case 'operative dentistry':
        return 'clinic-operative';
      case 'endodontics':
        return 'clinic-endo';
      case 'oral surgery':
        return 'clinic-surgery';
      case 'periodontics':
        return 'clinic-perio';
      case 'pediatric dentistry':
      case 'pediatric':
        return 'clinic-pediatric';
      default:
        return 'clinic-prosth';
    }
  }

  String _getDefaultRequirementId(String clinicId) {
    switch (clinicId) {
      case 'clinic-prosth':
        return 'req-prosth-cd';
      case 'clinic-operative':
        return 'req-op-class1';
      case 'clinic-endo':
        return 'req-endo-anterior';
      case 'clinic-surgery':
        return 'req-surg-simple';
      case 'clinic-perio':
        return 'req-perio-srp';
      case 'clinic-pediatric':
        return 'req-peds-pulpotomy';
      default:
        return 'req-prosth-cd';
    }
  }

  /// Persists a new patient and automatically creates an initial clinical [CaseRecord].
  ///
  /// **Why Sequential Insertion is Required:**
  /// Under SQLite foreign key constraints (`PRAGMA foreign_keys = ON;`), a child
  /// [CaseRecord] cannot reference a [patientId] that does not yet exist in the
  /// `patients` table. We first insert the [Patient] entity. Once successfully written,
  /// we extract the patient's generated UUID and insert the initial [CaseRecord]
  /// linked to the user's selected clinic.
  ///
  /// **Preventing Orphaned Records:**
  /// By creating the initial [CaseRecord] at patient registration time, the patient
  /// is immediately associated with the clinical department chosen by the student.
  /// This ensures the patient appears in clinic-specific roster filters and prevents
  /// unassigned, orphaned patient records in the offline clinical database.
  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    final phone = _phoneController.text.trim();
    final medHistory = _medicalHistoryController.text.trim();

    // Generate collision-free UUID v4 for the new patient record.
    // Offline-first SQLite requires client-side primary key generation that guarantees
    // global uniqueness without requiring a central server or roundtrip network coordination.
    final patientId = const Uuid().v4();
    AppLogger.debug('Generated collision-free UUID [$patientId] for new patient record.');

    final newPatient = Patient(
      id: patientId,
      name: name,
      age: age,
      gender: _selectedGender,
      phoneNumber: phone.isNotEmpty ? phone : null,
      medicalHistory: medHistory.isNotEmpty ? medHistory : null,
      createdAt: DateTime.now(),
    );

    try {
      // 1. Insert the parent Patient record first.
      await ref.read(patientRepositoryProvider).addPatient(newPatient);

      // 2. Resolve the clinic ID and matching requirement ID for the initial case.
      final clinicRepo = ref.read(clinicRepositoryProvider);
      final allClinics = await clinicRepo.getAllClinics();
      final clinic = allClinics.where(
        (c) =>
            c.name.toLowerCase() == _selectedClinic.toLowerCase() ||
            c.name.toLowerCase().contains(_selectedClinic.toLowerCase()) ||
            _selectedClinic.toLowerCase().contains(c.name.toLowerCase()),
      ).firstOrNull;

      final clinicId = clinic?.id ?? _getClinicId(_selectedClinic);

      final reqRepo = ref.read(requirementRepositoryProvider);
      final clinicReqs = await reqRepo.getRequirementsByClinicId(clinicId);
      final requirementId = clinicReqs.isNotEmpty
          ? clinicReqs.first.id
          : _getDefaultRequirementId(clinicId);

      // 3. Insert the child CaseRecord referencing the new patient's ID.
      // Generate collision-free UUID v4 for the initial case record.
      final initialCaseId = const Uuid().v4();
      AppLogger.debug('Generated collision-free UUID [$initialCaseId] for initial case record.');

      final initialCase = CaseRecord(
        id: initialCaseId,
        patientId: newPatient.id,
        requirementId: requirementId,
        status: 'In Progress',
        notes: 'Initial registration case for $_selectedClinic clinic.',
        dateStarted: DateTime.now(),
      );

      await ref.read(caseRecordRepositoryProvider).addCaseRecord(initialCase);

      AppLogger.info(
        '[AddPatientModal] Relational SQLite insert: created Patient (${newPatient.id}: "${newPatient.name}") and initial CaseRecord (${initialCase.id}) linked to clinic "$_selectedClinic" (requirement: $requirementId).',
      );

      // 4. Invalidate affected providers to update state across the app.
      ref.invalidate(patientListProvider);
      ref.invalidate(allCasesProvider);
      ref.invalidate(casesByPatientProvider(newPatient.id));
    } catch (e, stack) {
      AppLogger.error(
        '[AddPatientModal] Failed to register patient and link initial case record: $e',
        e,
        stack,
      );
    }

    widget.onPatientAdded?.call(newPatient);
    if (!mounted) return;
    Navigator.of(context).pop(newPatient);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final clinicsAsync = ref.watch(clinicListProvider);
    final availableClinics = clinicsAsync.valueOrNull != null && clinicsAsync.value!.isNotEmpty
        ? clinicsAsync.value!.map((c) => c.name).toList()
        : _clinics;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // 1. Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),

            // 2. Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'New Patient',
                    style: AppTextStyles.h1Mobile.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.onSurfaceVariant,
                      size: 22,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              thickness: 0.8,
              color: AppColors.surfaceVariant,
            ),

            // 3. Scrollable Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Patient Name
                      DenteraTextField(
                        label: 'Patient Name *',
                        hintText: 'e.g. John Doe',
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the patient name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Age & Gender Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Age Input
                          Expanded(
                            flex: 1,
                            child: DenteraTextField(
                              label: 'Age *',
                              hintText: 'e.g. 45',
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              validator: AddPatientModal.validateAge,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Gender Dropdown
                          Expanded(
                            flex: 1,
                            child: DenteraDropdown<String>(
                              label: 'Gender',
                              value: _selectedGender,
                              items: _genders
                                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedGender = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Clinic Assignment Badges
                      Text(
                        'Assign to Clinic',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableClinics.map((clinic) {
                          final isSelected = clinic == _selectedClinic ||
                              clinic.toLowerCase() == _selectedClinic.toLowerCase();
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedClinic = clinic;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.secondaryContainer.withValues(alpha: 0.25)
                                    : AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.secondary : AppColors.outlineVariant,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Text(
                                clinic,
                                style: AppTextStyles.labelCaps.copyWith(
                                  color: isSelected ? AppColors.secondary : AppColors.onSurface,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Optional Contact & Medical History Accordion
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showOptionalDetails = !_showOptionalDetails;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                'Add Contact & Details (Optional)',
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(
                                _showOptionalDetails
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (_showOptionalDetails) ...<Widget>[
                        const SizedBox(height: 12),
                        // Phone Number
                        DenteraTextField(
                          label: 'Phone Number',
                          hintText: 'e.g. +967 771 234 567',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),

                        // Medical History
                        DenteraTextField(
                          label: 'Medical History / Allergies',
                          hintText: 'e.g. Hypertension, Penicillin allergy',
                          controller: _medicalHistoryController,
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Action Buttons Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: SecondaryButton(
                      text: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      text: 'Save Patient',
                      icon: const Icon(
                        Icons.save_rounded,
                        size: 18,
                        color: AppColors.onPrimary,
                      ),
                      onPressed: _savePatient,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
