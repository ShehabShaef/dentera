import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';

/// Card widget visualizing an individual clinical case record and its evaluation status.
class CaseRecordCard extends StatelessWidget {
  const CaseRecordCard({
    super.key,
    required this.caseRecord,
    required this.requirementTitle,
    required this.clinicName,
    this.clinicColor = AppColors.secondary,
    this.onTap,
  });

  final CaseRecord caseRecord;
  final String requirementTitle;
  final String clinicName;
  final Color clinicColor;
  final VoidCallback? onTap;

  String _formatDate(DateTime date) {
    const months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = caseRecord.status.toLowerCase().contains('completed') ||
        caseRecord.status.toLowerCase().contains('evaluated');

    final statusBg = isCompleted
        ? AppColors.secondaryContainer.withValues(alpha: 0.3)
        : AppColors.primaryContainer.withValues(alpha: 0.12);
    final statusColor = isCompleted ? AppColors.onSecondaryContainer : AppColors.primary;

    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap ?? () {
          // TODO: Phase 6.2 - Open Case Record details
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
              width: 1.0,
            ),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header: Procedure & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      requirementTitle,
                      style: AppTextStyles.h2.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      caseRecord.status,
                      style: AppTextStyles.labelCaps.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Clinic Category Tag
              Row(
                children: <Widget>[
                  Icon(
                    Icons.medical_services_outlined,
                    size: 16,
                    color: clinicColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    clinicName,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Divider(
                height: 20,
                thickness: 0.8,
                color: AppColors.surfaceVariant,
              ),

              // Timestamps and Notes / Evaluation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.outline,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Started: ${_formatDate(caseRecord.dateStarted)}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (caseRecord.dateCompleted != null)
                    Text(
                      'Done: ${_formatDate(caseRecord.dateCompleted!)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (caseRecord.notes != null && caseRecord.notes!.isNotEmpty)
                    Flexible(
                      child: Text(
                        caseRecord.notes!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
