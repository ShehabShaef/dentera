import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../domain/entities/entities.dart';
import '../../state/case_visits_provider.dart';
import '../buttons/buttons.dart';
import '../inputs/inputs.dart';

/// Widget rendering an interactive clinical timeline of milestone visits for a [CaseRecord].
class CaseVisitTimelineWidget extends ConsumerWidget {
  const CaseVisitTimelineWidget({
    super.key,
    required this.caseRecordId,
    this.isEditable = true,
  });

  final String caseRecordId;
  final bool isEditable;

  static String _formatDate(DateTime date) {
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showCompleteVisitDialog(BuildContext context, WidgetRef ref, CaseVisit visit) {
    final notesController = TextEditingController(text: visit.notes ?? '');
    DateTime completionDate = visit.dateCompleted ?? DateTime.now();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Complete Visit ${visit.visitNumber}',
                  style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.title,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                // Date picker row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Completion Date:',
                      style: AppTextStyles.caption.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_formatDate(completionDate)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: completionDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => completionDate = picked);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DenteraTextField(
                  controller: notesController,
                  label: 'Clinical Progress Notes',
                  hintText: 'Enter clinical observations, findings, materials used...',
                  prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            PrimaryButton(
              text: 'Mark Completed',
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onPressed: () async {
                final notes = notesController.text.trim();
                await ref.read(caseVisitsControllerProvider).completeVisit(
                      visit: visit,
                      notes: notes,
                      dateCompleted: completionDate,
                    );
                if (dialogCtx.mounted) {
                  Navigator.of(dialogCtx).pop();
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Visit ${visit.visitNumber} marked as completed'),
                      backgroundColor: AppColors.secondary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(caseVisitsByCaseRecordProvider(caseRecordId));

    return visitsAsync.when(
      data: (visits) {
        if (visits.isEmpty) {
          return const SizedBox.shrink();
        }

        final completedCount = visits.where((v) => v.status == 'Completed').length;
        final totalCount = visits.length;
        final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.4),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Visit X of Y summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.linear_scale_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Clinical Visit Milestones',
                        style: AppTextStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: completedCount == totalCount
                          ? AppColors.secondaryContainer.withValues(alpha: 0.3)
                          : AppColors.primaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Visit $completedCount of $totalCount',
                      style: AppTextStyles.labelCaps.copyWith(
                        color: completedCount == totalCount
                            ? AppColors.onSecondaryContainer
                            : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.outlineVariant.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completedCount == totalCount ? AppColors.secondary : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Timeline list
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visits.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final visit = visits[index];
                  final isDone = visit.status == 'Completed';

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.surfaceContainerLowest
                          : AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDone
                            ? AppColors.secondary.withValues(alpha: 0.3)
                            : AppColors.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Step Circle
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDone
                                    ? AppColors.secondary
                                    : AppColors.outlineVariant.withValues(alpha: 0.3),
                              ),
                              child: Center(
                                child: isDone
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : Text(
                                        '${visit.visitNumber}',
                                        style: AppTextStyles.caption.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Visit Title
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    visit.title,
                                    style: AppTextStyles.bodyMd.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  if (isDone && visit.dateCompleted != null)
                                    Text(
                                      'Completed ${_formatDate(visit.dateCompleted!)}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Action button
                            if (isEditable && !isDone)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.check_circle_outline, size: 16),
                                label: const Text('Complete'),
                                onPressed: () => _showCompleteVisitDialog(context, ref, visit),
                              )
                            else if (isEditable)
                              IconButton(
                                icon: const Icon(Icons.edit_note, size: 20),
                                tooltip: 'Edit Visit Notes',
                                onPressed: () => _showCompleteVisitDialog(context, ref, visit),
                              ),
                          ],
                        ),
                        // Notes if any
                        if (visit.notes != null && visit.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.notes,
                                    size: 14,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      visit.notes!,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
