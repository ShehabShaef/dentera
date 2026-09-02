import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

/// Step 3 of Onboarding: Academic Year Selection.
class AcademicYearPage extends StatelessWidget {
  const AcademicYearPage({
    super.key,
    required this.selectedYear,
    required this.onYearSelected,
    required this.onSubmit,
    required this.onBack,
    this.isLoading = false,
  });

  final String selectedYear;
  final ValueChanged<String> onYearSelected;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final bool isLoading;

  static const List<String> availableYears = <String>[
    '3rd Year',
    '4th Year',
    '5th Year',
    'Internship',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: BaseCard(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Title & Subtitle
                Text(
                  'Clinical Year',
                  style: AppTextStyles.h1,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select your current academic stage to tailor your quota tracking.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Selectable Year Options
                Column(
                  children: availableYears.map((year) {
                    final isSelected = year == selectedYear;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () => onYearSelected(year),
                        borderRadius: BorderRadius.circular(9999),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.secondaryContainer.withValues(alpha: 0.2)
                                : AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: isSelected ? AppColors.secondary : AppColors.outlineVariant,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            year,
                            style: AppTextStyles.bodyMd.copyWith(
                              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Action Area
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    TextButton(
                      onPressed: onBack,
                      child: Text(
                        'Back',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.outline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    PrimaryButton(
                      isFullWidth: false,
                      isLoading: isLoading,
                      text: 'Enter Workspace',
                      onPressed: onSubmit,
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
