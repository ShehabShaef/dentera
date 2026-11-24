import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
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
    this.errorMessage,
  });

  final String selectedYear;
  final ValueChanged<String> onYearSelected;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final bool isLoading;
  final String? errorMessage;

  static const List<String> availableYears = <String>[
    '3rd Year',
    '4th Year',
    '5th Year',
    'Internship',
  ];

  static String getLocalizedYear(BuildContext context, String year) {
    switch (year) {
      case '3rd Year':
        return context.l10n.academicYearThird;
      case '4th Year':
        return context.l10n.academicYearFourth;
      case '5th Year':
        return context.l10n.academicYearFifth;
      case 'Internship':
        return context.l10n.academicYearInternship;
      default:
        return year;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  context.l10n.clinicalYear,
                  style: AppTextStyles.h1,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.selectAcademicStage,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: isDark ? AppDarkColors.textSecondary : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Selectable Year Options — theme-aware surfaces for Dark Mode
                Column(
                  children: availableYears.map((year) {
                    final isSelected = year == selectedYear;
                    final localizedTitle = getLocalizedYear(context, year);
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
                                ? (isDark
                                    ? AppDarkColors.secondary.withValues(alpha: 0.2)
                                    : AppColors.secondaryContainer.withValues(alpha: 0.2))
                                : (isDark
                                    ? AppDarkColors.surfaceContainerLow
                                    : AppColors.surfaceContainerLowest),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? AppDarkColors.secondary : AppColors.secondary)
                                  : (isDark ? AppDarkColors.outlineVariant : AppColors.outlineVariant),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            localizedTitle,
                            style: AppTextStyles.bodyMd.copyWith(
                              color: isSelected
                                  ? (isDark ? AppDarkColors.primary : AppColors.primary)
                                  : (isDark ? AppDarkColors.textSecondary : AppColors.onSurfaceVariant),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Validation Error Message
                if (errorMessage != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0, left: 4.0, right: 4.0),
                    child: Text(
                      errorMessage!,
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppDarkColors.error : AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Action Area
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    TextButton(
                      onPressed: onBack,
                      child: Text(
                        context.l10n.back,
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppDarkColors.outline : AppColors.outline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    PrimaryButton(
                      isFullWidth: false,
                      isLoading: isLoading,
                      text: context.l10n.enterWorkspace,
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
