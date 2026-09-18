import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../data/database/database_providers.dart';
import '../../../domain/entities/entities.dart';
import '../../../l10n/l10n.dart';
import '../../state/state.dart';
import '../buttons/buttons.dart';
import '../dentera_snackbar.dart';
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
  String? _selectedClinicId;
  Requirement? _selectedMainRequirement;
  bool _showOptionalDetails = false;

  static const List<String> _genders = <String>['Male', 'Female'];
  static const List<Clinic> _fallbackClinics = <Clinic>[
    Clinic(id: 'clinic-prosth', name: 'Prosthodontics', academicYear: '5th Year', colorHex: '#003E6F'),
    Clinic(id: 'clinic-operative', name: 'Operative', academicYear: '5th Year', colorHex: '#006A64'),
    Clinic(id: 'clinic-endo', name: 'Endodontics', academicYear: '5th Year', colorHex: '#2E3F50'),
    Clinic(id: 'clinic-surgery', name: 'Oral Surgery', academicYear: '5th Year', colorHex: '#8C1D18'),
    Clinic(id: 'clinic-perio', name: 'Periodontics', academicYear: '5th Year', colorHex: '#526070'),
    Clinic(id: 'clinic-pediatric', name: 'Pediatric Dentistry', academicYear: '5th Year', colorHex: '#6750A4'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _medicalHistoryController.dispose();
    super.dispose();
  }

  /// Persists a new patient and automatically creates an initial clinical [CaseRecord]
  /// linked to the explicitly designated main case / procedure.
  ///
  /// **Why Sequential Insertion is Required:**
  /// Under SQLite foreign key constraints (`PRAGMA foreign_keys = ON;`), a child
  /// [CaseRecord] cannot reference a [patientId] that does not yet exist in the
  /// `patients` table. We first insert the [Patient] entity. Once successfully written,
  /// we extract the patient's generated UUID and insert the initial [CaseRecord]
  /// linked to the user's selected clinic and procedure requirement.
  ///
  /// **Preventing Orphaned Records & Auto-Case Binding Decoupling:**
  /// Rather than defaulting to a hardcoded or arbitrary first requirement, the initial
  /// [CaseRecord] is bound directly to the clinician's chosen [_selectedMainRequirement].
  /// This ensures the patient appears in clinic-specific roster filters while accurately
  /// reflecting their primary clinical indication.
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

      // 2. Insert initial CaseRecord linked to the explicitly selected procedure requirement.
      if (_selectedMainRequirement != null) {
        final initialCaseId = const Uuid().v4();
        AppLogger.debug('Generated collision-free UUID [$initialCaseId] for initial case record.');

        final initialCase = CaseRecord(
          id: initialCaseId,
          patientId: newPatient.id,
          requirementId: _selectedMainRequirement!.id,
          status: 'In Progress',
          notes: 'Initial registration case for $_selectedClinic clinic.',
          dateStarted: DateTime.now(),
        );

        await ref.read(caseRecordRepositoryProvider).addCaseRecord(initialCase);

        AppLogger.info(
          '[AddPatientModal] Relational SQLite insert: created Patient (${newPatient.id}: "${newPatient.name}") and initial CaseRecord (${initialCase.id}) linked to clinic "$_selectedClinic" (requirement: ${_selectedMainRequirement!.id}).',
        );
      } else {
        AppLogger.info(
          '[AddPatientModal] Created Patient (${newPatient.id}: "${newPatient.name}") without initial CaseRecord (no requirement selected or available).',
        );
      }

      // 3. Invalidate affected providers to update state across the app.
      ref.invalidate(patientListProvider);
      ref.invalidate(allCasesProvider);
      ref.invalidate(casesByPatientProvider(newPatient.id));
      ref.invalidate(requirementsByClinicProvider);
      ref.invalidate(allRequirementsProvider);
      ref.invalidate(globalQuotaSummaryProvider);
    } catch (e, stack) {
      if (mounted) {
        DenteraSnackBar.showError(
          context,
          message: 'Failed to register patient',
          error: e,
          stackTrace: stack,
        );
      }
      return;
    }

    widget.onPatientAdded?.call(newPatient);
    if (!mounted) return;
    Navigator.of(context).pop(newPatient);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final clinicsAsync = ref.watch(allClinicsProvider);
    final List<Clinic> availableClinics =
        clinicsAsync.valueOrNull != null && clinicsAsync.value!.isNotEmpty
            ? clinicsAsync.value!
            : _fallbackClinics;

    final Clinic activeClinic = availableClinics.firstWhere(
      (c) =>
          (_selectedClinicId != null && c.id == _selectedClinicId) ||
          c.name.toLowerCase() == _selectedClinic.toLowerCase(),
      orElse: () => availableClinics.first,
    );
    final activeClinicId = activeClinic.id;

    // Dynamically watch requirements for the selected clinic
    final reqsAsync = ref.watch(requirementsByClinicProvider(activeClinicId));
    final List<Requirement> availableReqs = reqsAsync.valueOrNull ?? const <Requirement>[];

    // Ensure selected requirement belongs to the active clinic
    final Requirement? activeSelectedReq = (_selectedMainRequirement != null &&
            availableReqs.any((r) => r.id == _selectedMainRequirement!.id))
        ? _selectedMainRequirement
        : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceContainer : AppColors.surfaceContainerLowest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        boxShadow: isDark ? AppDarkColors.cardShadow : AppColors.cardShadow,
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
                  color: isDark ? AppDarkColors.dragHandle : AppColors.surfaceVariant,
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
                    context.l10n.newPatient,
                    style: AppTextStyles.h1Mobile.copyWith(
                      color: isDark ? AppDarkColors.textPrimary : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
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
                        label: '${context.l10n.patientName} *',
                        hintText: 'e.g. John Doe',
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.l10n.pleaseEnterPatientName;
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
                              label: '${context.l10n.age} *',
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
                              label: context.l10n.gender,
                              value: _selectedGender,
                              items: _genders
                                  .map((g) => DropdownMenuItem(
                                        value: g,
                                        child: Text(g == 'Male' ? context.l10n.male : context.l10n.female),
                                      ))
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
                        context.l10n.assignToClinic,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableClinics.map((clinicItem) {
                          final isSelected = clinicItem.id == activeClinicId;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedClinicId = clinicItem.id;
                                _selectedClinic = clinicItem.name;
                                _selectedMainRequirement = null;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? AppDarkColors.primaryTeal.withValues(alpha: 0.18) : AppColors.secondaryContainer.withValues(alpha: 0.25))
                                    : (isDark ? AppDarkColors.surfaceContainerHigh : AppColors.surfaceContainerLowest),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? (isDark ? AppDarkColors.primaryTeal : AppColors.secondary)
                                      : (isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Text(
                                clinicItem.name,
                                style: AppTextStyles.labelCaps.copyWith(
                                  color: isSelected
                                      ? (isDark ? AppDarkColors.primaryTeal : AppColors.secondary)
                                      : (isDark ? AppDarkColors.textPrimary : AppColors.onSurface),
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (availableReqs.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 14),
                        DenteraDropdown<String>(
                          key: ValueKey('${activeClinicId}_${activeSelectedReq?.id}'),
                          label: context.l10n.mainCaseProcedure,
                          hintText: context.l10n.selectMainProcedure,
                          value: activeSelectedReq?.id,
                          prefixIcon: const Icon(Icons.assignment_outlined, size: 20),
                          items: availableReqs.map((req) {
                            return DropdownMenuItem<String>(
                              value: req.id,
                              child: Text(
                                '${req.title} (${req.completedCount}/${req.targetCount})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return context.l10n.pleaseSelectMainProcedure;
                            }
                            return null;
                          },
                          onChanged: (val) {
                            setState(() {
                              _selectedMainRequirement = val != null
                                  ? availableReqs.firstWhere((r) => r.id == val)
                                  : null;
                            });
                          },
                        ),
                      ],
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
                                context.l10n.addContactAndDetailsOptional,
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
                          label: context.l10n.phoneNumberLabel,
                          hintText: 'e.g. +967 771 234 567',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),

                        // Medical History
                        DenteraTextField(
                          label: context.l10n.medicalHistoryLabel,
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
                      text: context.l10n.cancel,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      text: context.l10n.savePatient,
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
