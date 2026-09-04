import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../data/database/database_providers.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';
import '../buttons/buttons.dart';
import '../inputs/inputs.dart';

/// Bottom sheet modal to register a new dental clinic department in Dentera.
///
/// Captures the clinic's name, designated academic year, and color theme.
/// Writes directly to the local SQLite database via [clinicRepositoryProvider] and
/// invalidates [clinicListProvider] to trigger automatic reactive UI updates across
/// the application without manual state syncing or polling.
class AddClinicModal extends ConsumerStatefulWidget {
  const AddClinicModal({
    super.key,
    this.onClinicAdded,
  });

  final ValueChanged<Clinic>? onClinicAdded;

  /// Convenience static method to show the AddClinicModal bottom sheet.
  static Future<Clinic?> show(
    BuildContext context, {
    ValueChanged<Clinic>? onClinicAdded,
  }) {
    AppLogger.info('Opened AddClinicModal');
    return showModalBottomSheet<Clinic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddClinicModal(onClinicAdded: onClinicAdded),
    );
  }

  @override
  ConsumerState<AddClinicModal> createState() => _AddClinicModalState();
}

class _AddClinicModalState extends ConsumerState<AddClinicModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  String _selectedAcademicYear = '5th Year';
  String _selectedColorHex = '#003E6F';
  bool _isSubmitting = false;

  static const List<String> _academicYears = <String>[
    '3rd Year',
    '4th Year',
    '5th Year',
    'Internship',
    'General Practice',
  ];

  static const List<String> _colorPalette = <String>[
    '#003E6F', // Deep Navy (Prosthodontics)
    '#1E568C', // Clinical Blue (Endodontics)
    '#006A64', // Deep Teal (Operative)
    '#2E3F50', // Slate Navy (Oral Surgery)
    '#37485A', // Steel Blue (Periodontics)
    '#7B1FA2', // Royal Purple (Orthodontics)
    '#C2185B', // Rose / Pediatric
    '#E65100', // Amber / Radiography
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final clinicName = _nameController.text.trim();
    final slug = clinicName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final clinicId = 'clinic-${slug.isNotEmpty ? slug : 'dept'}-${DateTime.now().millisecondsSinceEpoch % 10000}';

    final newClinic = Clinic(
      id: clinicId,
      name: clinicName,
      academicYear: _selectedAcademicYear,
      colorHex: _selectedColorHex,
    );

    try {
      AppLogger.info('Creating new clinic: ${newClinic.name} (${newClinic.id})');
      await ref.read(clinicRepositoryProvider).addClinic(newClinic);
      ref.invalidate(clinicListProvider);

      widget.onClinicAdded?.call(newClinic);

      if (mounted) {
        Navigator.of(context).pop(newClinic);
      }
    } catch (e, st) {
      AppLogger.error('Failed to create clinic: $e', e, st);
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create clinic: $e'),
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
                          'Add Dental Clinic',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Create a new clinical department to track quotas',
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

              // 3. Clinic Name Field
              DenteraTextField(
                controller: _nameController,
                label: 'Clinic Name',
                hintText: 'e.g., Orthodontics or Pedodontics',
                prefixIcon: const Icon(Icons.medical_services_outlined, size: 20),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a clinic name';
                  }
                  if (value.trim().length < 2) {
                    return 'Clinic name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 4. Academic Year Dropdown
              DenteraDropdown<String>(
                label: 'Academic Year',
                value: _selectedAcademicYear,
                prefixIcon: const Icon(Icons.school_outlined, size: 20),
                items: _academicYears
                    .map(
                      (year) => DropdownMenuItem<String>(
                        value: year,
                        child: Text(year),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedAcademicYear = val);
                  }
                },
              ),
              const SizedBox(height: 20),

              // 5. Color Theme Selection
              Text(
                'Department Theme Color',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: _colorPalette.map((hex) {
                  final isSelected = hex.toLowerCase() == _selectedColorHex.toLowerCase();
                  final color = _parseColor(hex);

                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorHex = hex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.onSurface : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      text: _isSubmitting ? 'Saving...' : 'Save Clinic',
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
