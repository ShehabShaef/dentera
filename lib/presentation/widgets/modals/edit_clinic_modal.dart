import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../data/database/database_providers.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';
import '../buttons/buttons.dart';
import '../dentera_snackbar.dart';
import '../inputs/inputs.dart';

/// Modal bottom sheet to edit an existing dental clinic department in Dentera.
///
/// Pre-filled with the clinic's existing name, academic year, and color palette.
/// Persists modifications via [clinicRepositoryProvider.updateClinic] and invalidates
/// [clinicListProvider] to automatically refresh the UI across all screens.
class EditClinicModal extends ConsumerStatefulWidget {
  const EditClinicModal({
    super.key,
    required this.clinic,
    this.onClinicUpdated,
  });

  final Clinic clinic;
  final ValueChanged<Clinic>? onClinicUpdated;

  /// Convenience static helper to show the [EditClinicModal] bottom sheet.
  static Future<Clinic?> show(
    BuildContext context, {
    required Clinic clinic,
    ValueChanged<Clinic>? onClinicUpdated,
  }) {
    AppLogger.info('Opened EditClinicModal for clinic: ${clinic.id}');
    return showModalBottomSheet<Clinic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditClinicModal(
        clinic: clinic,
        onClinicUpdated: onClinicUpdated,
      ),
    );
  }

  @override
  ConsumerState<EditClinicModal> createState() => _EditClinicModalState();
}

class _EditClinicModalState extends ConsumerState<EditClinicModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  late String _selectedAcademicYear;
  late String _selectedColorHex;
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
    '#455A64', // Blue Grey (Oral Medicine)
    '#7B1FA2', // Royal Purple (Orthodontics)
    '#C2185B', // Rose / Pediatric
    '#E65100', // Amber / Radiography
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.clinic.name);
    _selectedAcademicYear = _academicYears.contains(widget.clinic.academicYear)
        ? widget.clinic.academicYear
        : _academicYears.first;
    _selectedColorHex = widget.clinic.colorHex;
  }

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

    final updatedClinic = widget.clinic.copyWith(
      name: _nameController.text.trim(),
      academicYear: _selectedAcademicYear,
      colorHex: _selectedColorHex,
    );

    try {
      AppLogger.info('Updating clinic: ${updatedClinic.name} (${updatedClinic.id})');
      await ref.read(clinicRepositoryProvider).updateClinic(updatedClinic);
      ref.invalidate(clinicListProvider);

      widget.onClinicUpdated?.call(updatedClinic);

      if (mounted) {
        Navigator.of(context).pop(updatedClinic);
      }
    } catch (e, st) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        DenteraSnackBar.showError(
          context,
          message: 'Failed to update clinic',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceContainer : AppColors.surfaceContainerLowest,
        borderRadius: const BorderRadius.only(
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
                            'Edit Clinic',
                            style: AppTextStyles.h2.copyWith(
                              color: isDark ? AppDarkColors.tealAccent : AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Update clinic name, curriculum, and color theme',
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
                Divider(height: 20, thickness: 0.8, color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),

                // 3. Clinic Name Input
                Text(
                  'Clinic Name',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                DenteraTextField(
                  controller: _nameController,
                  hintText: 'e.g. Pediatric Dentistry',
                  prefixIcon: Icon(Icons.business_rounded, color: isDark ? AppDarkColors.textSecondary : AppColors.outline),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Clinic name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Clinic name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 4. Academic Year Selection
                Text(
                  'Academic Year',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _academicYears.map((year) {
                    final isSelected = year == _selectedAcademicYear;
                    return ChoiceChip(
                      label: Text(year),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedAcademicYear = year);
                      },
                      labelStyle: AppTextStyles.caption.copyWith(
                        color: isSelected ? (isDark ? AppDarkColors.onTeal : AppColors.onSecondary) : (isDark ? AppDarkColors.textSecondary : AppColors.onSurfaceVariant),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      selectedColor: isDark ? AppDarkColors.tealAccent : AppColors.secondary,
                      backgroundColor: isDark ? AppDarkColors.surfaceContainerHigh : AppColors.surfaceContainerLow,
                      side: BorderSide(
                        color: isSelected ? (isDark ? AppDarkColors.tealAccent : AppColors.secondary) : (isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 5. Department Color
                Text(
                  'Department Color',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: _colorPalette.map((hex) {
                    final color = _parseColor(hex);
                    final isSelected = hex == _selectedColorHex;

                    return InkWell(
                      onTap: () => setState(() => _selectedColorHex = hex),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? (isDark ? AppDarkColors.tealAccent : AppColors.surface) : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        text: _isSubmitting ? 'Saving...' : 'Save Changes',
                        icon: Icon(Icons.check_circle_outline_rounded, size: 18, color: isDark ? AppDarkColors.onTeal : AppColors.onPrimary),
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
