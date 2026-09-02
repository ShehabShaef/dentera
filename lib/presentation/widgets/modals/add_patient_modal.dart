import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    final phone = _phoneController.text.trim();
    final medHistory = _medicalHistoryController.text.trim();

    final newPatient = Patient(
      id: 'PT-${DateTime.now().millisecondsSinceEpoch % 10000}',
      name: name,
      age: age,
      gender: _selectedGender,
      phoneNumber: phone.isNotEmpty ? phone : null,
      medicalHistory: medHistory.isNotEmpty ? medHistory : null,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(patientRepositoryProvider).addPatient(newPatient);
      ref.invalidate(patientListProvider);
    } catch (_) {
      // Offline fallback handling
    }

    widget.onPatientAdded?.call(newPatient);
    if (!mounted) return;
    Navigator.of(context).pop(newPatient);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter age';
                                }
                                if (int.tryParse(value.trim()) == null) {
                                  return 'Invalid';
                                }
                                return null;
                              },
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
                        children: _clinics.map((clinic) {
                          final isSelected = clinic == _selectedClinic;
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
