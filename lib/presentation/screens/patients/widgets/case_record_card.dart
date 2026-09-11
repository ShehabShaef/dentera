import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';
import '../../../state/state.dart';

/// Card widget visualizing an individual clinical case record and its evaluation status.
class CaseRecordCard extends ConsumerWidget {
  const CaseRecordCard({
    super.key,
    required this.caseRecord,
    required this.requirementTitle,
    required this.clinicName,
    this.clinicColor = AppColors.secondary,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final CaseRecord caseRecord;
  final String requirementTitle;
  final String clinicName;
  final Color clinicColor;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  String _formatDate(DateTime date) {
    const months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(caseVisitsByCaseRecordProvider(caseRecord.id));
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
                  if (onEdit != null || onDelete != null) ...<Widget>[
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        size: 18,
                        color: AppColors.onSurfaceVariant,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: 'Case actions',
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit?.call();
                        } else if (value == 'delete') {
                          onDelete?.call();
                        }
                      },
                      itemBuilder: (context) => <PopupMenuEntry<String>>[
                        if (onEdit != null)
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18, color: AppColors.onSurface),
                                SizedBox(width: 8),
                                Text('Edit Case'),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                SizedBox(width: 8),
                                Text(
                                  'Delete Case',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
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

              // Multi-Visit Step Indicator
              visitsAsync.when(
                data: (visits) {
                  if (visits.isEmpty) return const SizedBox.shrink();
                  final totalVisits = visits.length;
                  final completedVisits =
                      visits.where((v) => v.status == 'Completed').length;
                  final progress = totalVisits > 0 ? (completedVisits / totalVisits) : 0.0;
                  final isAllDone = completedVisits == totalVisits;

                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.2),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.linear_scale_rounded,
                          size: 16,
                          color: isAllDone ? AppColors.secondary : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Visit $completedVisits of $totalVisits',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 5,
                              backgroundColor: AppColors.outlineVariant.withValues(alpha: 0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isAllDone ? AppColors.secondary : AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
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
