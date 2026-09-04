import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';

/// Modal bottom sheet displaying all clinical [CaseRecord] logs associated with a specific [Requirement].
///
/// ### Invocation Pattern:
/// Triggered imperatively via [RequirementCasesBottomSheet.show] when a dental student taps a
/// [RequirementDetailCard] inside [ClinicDetailsScreen]. This modal is presented as a modal bottom
/// sheet with [showModalBottomSheet], ensuring it overlays the current clinical screen context
/// without disrupting the underlying scroll position or route stack.
///
/// ### Relational Query Logic:
/// 1. **Primary Key / Foreign Key Join:**
///    The bottom sheet watches [casesByRequirementProvider] parameterized by [requirement.id].
///    Under the hood, this queries SQLite table `case_records` with `where: 'requirementId = ?'`.
/// 2. **Patient Entity Hydration:**
///    Simultaneously, the widget watches [patientListProvider] to hydrate the foreign key
///    `patientId` on each [CaseRecord] to a friendly patient name and demographic context.
///    If an un-cached or freshly imported patient record is encountered, it gracefully falls back
///    to displaying `'Patient #${caseRecord.patientId}'` without throwing null-pointer exceptions.
///
/// ### State Management & Reactivity:
/// Because this widget uses Riverpod's reactive [ConsumerWidget] pattern, any updates committed
/// to the SQLite database (such as completing an evaluation or logging an additional patient procedure)
/// that invalidate [casesByRequirementProvider] or [allCasesProvider] will immediately trigger a
/// seamless re-render of this sheet without requiring manual refresh listeners or lifecycle polling.
class RequirementCasesBottomSheet extends ConsumerWidget {
  const RequirementCasesBottomSheet({
    super.key,
    required this.requirement,
    this.accentColor = AppColors.secondary,
  });

  final Requirement requirement;
  final Color accentColor;

  /// Convenience static helper to display the [RequirementCasesBottomSheet].
  static Future<void> show(
    BuildContext context, {
    required Requirement requirement,
    Color? accentColor,
  }) {
    AppLogger.info('Opened requirement cases bottom sheet for requirement: ${requirement.id}');
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RequirementCasesBottomSheet(
        requirement: requirement,
        accentColor: accentColor ?? AppColors.secondary,
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casesAsync = ref.watch(casesByRequirementProvider(requirement.id));
    final patientsAsync = ref.watch(patientListProvider);

    final patientsMap = <String, Patient>{
      for (final p in patientsAsync.valueOrNull ?? const <Patient>[]) p.id: p,
    };

    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 1. Drag Handle
            const SizedBox(height: 12),
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

            // 2. Header: Title & Quota Badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          requirement.title,
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${requirement.completedCount} of ${requirement.targetCount} Completed',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      'Quota: ${requirement.targetCount}',
                      style: AppTextStyles.labelCaps.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.outline),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 20, thickness: 0.8, color: AppColors.outlineVariant),

            // 3. Reactive Cases List
            Flexible(
              child: casesAsync.when(
                data: (cases) {
                  if (cases.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: cases.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final caseRecord = cases[index];
                      final patient = patientsMap[caseRecord.patientId];
                      final patientName = patient?.name ?? 'Patient #${caseRecord.patientId}';
                      final isCompleted = caseRecord.status.toLowerCase().contains('completed') ||
                          caseRecord.status.toLowerCase().contains('evaluated');

                      return Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.outlineVariant.withValues(alpha: 0.3),
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // Top Row: Patient Name & Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: accentColor.withValues(alpha: 0.15),
                                      child: Text(
                                        patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                                        style: AppTextStyles.caption.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      patientName,
                                      style: AppTextStyles.bodyMd.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? AppColors.secondaryContainer.withValues(alpha: 0.3)
                                        : AppColors.primaryContainer.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: Text(
                                    caseRecord.status,
                                    style: AppTextStyles.labelCaps.copyWith(
                                      color: isCompleted
                                          ? AppColors.onSecondaryContainer
                                          : AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Dates Row
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
                                if (caseRecord.dateCompleted != null) ...[
                                  const SizedBox(width: 16),
                                  const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 14,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Completed: ${_formatDate(caseRecord.dateCompleted!)}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            // Clinical Notes (if available)
                            if (caseRecord.notes != null && caseRecord.notes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.outlineVariant.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  caseRecord.notes!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'Failed to load case records: $err',
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerHigh,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 32,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Case Records Logged',
              style: AppTextStyles.h2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No clinical cases have been logged for this requirement yet. Cases logged in Patient Case Sheets will appear here automatically.',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
