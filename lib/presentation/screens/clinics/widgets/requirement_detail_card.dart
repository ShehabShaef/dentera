import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';
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
class RequirementDetailCard extends StatelessWidget {
  const RequirementDetailCard({
    super.key,
    required this.requirement,
    this.accentColor = AppColors.secondary,
    this.linkedCases = const <LinkedPatientCase>[],
    this.onTap,
  });

  final Requirement requirement;
  final Color accentColor;
  final List<LinkedPatientCase> linkedCases;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
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
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${requirement.completedCount} / ${requirement.targetCount}',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          RequirementProgressBar.fromQuota(
            label: '${((requirement.completedCount / (requirement.targetCount > 0 ? requirement.targetCount : 1)) * 100).toInt()}% Done',
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
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: linkedCases.isNotEmpty
                ? Column(
                    children: linkedCases.map((patientCase) {
                      final isDone = patientCase.isCompleted;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.outlineVariant.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              patientCase.patientName,
                              style: AppTextStyles.bodyMd.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  isDone ? Icons.task_alt_rounded : Icons.hourglass_empty_rounded,
                                  size: 14,
                                  color: isDone ? AppColors.secondary : AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  patientCase.status,
                                  style: AppTextStyles.labelCaps.copyWith(
                                    color: isDone ? AppColors.secondary : AppColors.primary,
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
                      'No patients assigned yet.',
                      style: AppTextStyles.caption.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.outline,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
