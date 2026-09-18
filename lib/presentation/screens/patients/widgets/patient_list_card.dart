import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';

/// Card widget representing a patient in the master roster.
class PatientListCard extends StatelessWidget {
  const PatientListCard({
    super.key,
    required this.patient,
    this.subtitle,
    this.tags = const <String>[],
    this.onTap,
  });

  final Patient patient;
  final String? subtitle;
  final List<String> tags;
  final VoidCallback? onTap;

  String get _initials {
    final parts = patient.name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return patient.name.substring(0, patient.name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSubtitle = subtitle ?? '${patient.gender}, ${patient.age} Y • ID: ${patient.id}';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppDarkColors.surfaceContainer : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap ?? () {
          // TODO: Phase 6.2 - Navigate to patient_case_sheet
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant.withValues(alpha: 0.3),
              width: 1.0,
            ),
            boxShadow: isDark ? AppDarkColors.cardShadow : AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Top Row: Avatar, Name & Trailing Action
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // Circular Initials Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? AppDarkColors.primaryTeal.withValues(alpha: 0.15)
                          : AppColors.primaryContainer.withValues(alpha: 0.15),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials,
                      style: AppTextStyles.h2.copyWith(
                        color: isDark ? AppDarkColors.primaryTeal : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Patient Name & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          patient.name,
                          style: AppTextStyles.h2.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          effectiveSubtitle,
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Trailing Chevron
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? AppDarkColors.textMuted : AppColors.outlineVariant,
                    size: 22,
                  ),
                ],
              ),

              // Clinical Badges Row
              if (tags.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags.map((tag) {
                    final isPending = tag.toLowerCase().contains('pending') ||
                        tag.toLowerCase().contains('progress');
                    final isCompleted = tag.toLowerCase().contains('completed') ||
                        tag.toLowerCase().contains('sign-off');

                    Color tagBg = isDark
                        ? AppDarkColors.surfaceContainerHighest
                        : AppColors.primaryContainer.withValues(alpha: 0.1);
                    Color tagText = isDark ? AppDarkColors.textSecondary : AppColors.primary;
                    Color tagBorder = isDark
                        ? AppDarkColors.borderSubtle
                        : AppColors.primary.withValues(alpha: 0.2);

                    if (isPending) {
                      tagBg = isDark
                          ? AppDarkColors.primaryTeal.withValues(alpha: 0.15)
                          : AppColors.secondaryContainer.withValues(alpha: 0.2);
                      tagText = isDark ? AppDarkColors.primaryTeal : AppColors.secondary;
                      tagBorder = isDark
                          ? AppDarkColors.primaryTeal.withValues(alpha: 0.3)
                          : AppColors.secondary.withValues(alpha: 0.3);
                    } else if (isCompleted) {
                      tagBg = isDark
                          ? AppDarkColors.primaryTeal.withValues(alpha: 0.25)
                          : AppColors.secondaryContainer.withValues(alpha: 0.3);
                      tagText = isDark ? AppDarkColors.primaryTeal : AppColors.onSecondaryContainer;
                      tagBorder = isDark
                          ? AppDarkColors.primaryTeal.withValues(alpha: 0.5)
                          : AppColors.secondaryContainer;
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tagBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tagBorder, width: 1.0),
                      ),
                      child: Text(
                        tag,
                        style: AppTextStyles.labelCaps.copyWith(
                          color: tagText,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
