import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../l10n/l10n.dart';
import '../../../widgets/cards/base_card.dart';
import '../../../widgets/progress/requirement_progress_bar.dart';

/// Linked patient case summary inside requirement card.
class LinkedPatientCase {
  const LinkedPatientCase({
    required this.patientName,
    required this.status,
    this.isCompleted = false,
  });

  final String patientName;
  final String status;
  final bool isCompleted;
}

/// Detailed card displaying a procedural requirement, quota progress, and linked patient cases.
///
/// ### Modal Invocation & Navigation:
/// Tapping this card triggers [onTap], which typically invokes [RequirementCasesBottomSheet.show].
/// This presents a modal bottom sheet overlay with the complete relational log of all [CaseRecord]
/// entities linked to this specific requirement.
///
/// ### Relational Case Aggregation:
/// The card renders a preview of [linkedCases] (or a clean zero-state message if unassigned),
/// showing active progress before the student drills down into individual patient case histories.
class RequirementDetailCard extends StatelessWidget {
  const RequirementDetailCard({
    super.key,
    required this.requirement,
    this.accentColor = AppColors.secondary,
    this.linkedCases = const <LinkedPatientCase>[],
    this.onTap,
    this.onEdit,
  });

  final Requirement requirement;
  final Color accentColor;
  final List<LinkedPatientCase> linkedCases;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: BaseCard(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header: Requirement Title & Quota Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      requirement.title,
                      style: AppTextStyles.h2.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppDarkColors.surfaceContainerHigh : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${requirement.completedCount} / ${requirement.targetCount}',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 18, color: isDark ? AppDarkColors.textMuted : AppColors.outline),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: context.l10n.editRequirement,
                      onPressed: onEdit,
                    ),
                  ],
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: isDark ? AppDarkColors.textMuted : AppColors.outline,
                  ),
                ],
              ),
          const SizedBox(height: 12),

          // Progress Bar
          RequirementProgressBar.fromQuota(
            label: context.l10n.percentDone(((requirement.completedCount / (requirement.targetCount > 0 ? requirement.targetCount : 1)) * 100).toInt()),
            completed: requirement.completedCount,
            total: requirement.targetCount,
            progressColor: accentColor,
            showQuotaText: false,
          ),
          const SizedBox(height: 14),

          // Linked Cases Sub-Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppDarkColors.surfaceContainerLowest : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: linkedCases.isNotEmpty
                ? Column(
                    children: linkedCases.map((patientCase) {
                      final isDone = patientCase.isCompleted;
                      final statusColor = isDone
                          ? (isDark ? AppDarkColors.primaryTeal : AppColors.secondary)
                          : (isDark ? AppDarkColors.primaryTeal.withValues(alpha: 0.8) : AppColors.primary);
                      final displayStatus = patientCase.status.toLowerCase() == 'completed'
                          ? context.l10n.completed
                          : (patientCase.status.toLowerCase() == 'in progress'
                              ? context.l10n.inProgress
                              : (patientCase.status.toLowerCase() == 'evaluated'
                                  ? context.l10n.evaluated
                                  : patientCase.status));

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.surfaceContainer : AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              patientCase.patientName,
                              style: AppTextStyles.bodyMd.copyWith(
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  isDone ? Icons.task_alt_rounded : Icons.hourglass_empty_rounded,
                                  size: 14,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  displayStatus,
                                  style: AppTextStyles.labelCaps.copyWith(
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: Text(
                      context.l10n.noPatientsAssignedYet,
                      style: AppTextStyles.caption.copyWith(
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppDarkColors.textMuted : AppColors.outline,
                      ),
                    ),
                  ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}

