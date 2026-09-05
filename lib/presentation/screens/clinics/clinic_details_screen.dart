import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';
import '../../widgets/widgets.dart';
import 'widgets/widgets.dart';

/// Clinic Details & Quotas breakdown screen wired to Riverpod SQLite state.
///
/// Dynamically builds clinic quotas and linked case records strictly from
/// [requirementsByClinicProvider] and [allCasesProvider], handling empty states natively without
/// visual mock fallbacks.
///
/// ### Modal Invocation & Administration:
/// - **Requirement Definition ([AddRequirementModal]):** Tapping the screen's Floating Action Button
///   opens [AddRequirementModal], allowing dental students to define new clinical procedures and target quotas
///   for this specific clinic without hardcoded placeholders.
/// - **Relational Case Inspection ([RequirementCasesBottomSheet]):** Tapping any [RequirementDetailCard]
///   triggers [RequirementCasesBottomSheet], fetching and displaying all clinical [CaseRecord] entries
///   belonging to that requirement via [casesByRequirementProvider].
///
/// ### Relational Querying & State Management:
/// Clinical requirements are queried reactively using [requirementsByClinicProvider(clinic.id)].
/// When new requirements or case records are submitted, state providers are invalidated,
/// triggering immediate local recalculation of overall clinic completion percentages and UI cards.
class ClinicDetailsScreen extends ConsumerWidget {
  const ClinicDetailsScreen({
    super.key,
    required this.clinic,
  });

  final Clinic clinic;

  Color get _clinicColor {
    try {
      final hex = clinic.colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  List<LinkedPatientCase> _resolveLinkedCases(
    List<CaseRecord>? cases,
    Requirement req,
  ) {
    if (cases != null && cases.isNotEmpty) {
      final matched = cases.where((c) => c.requirementId == req.id).toList();
      if (matched.isNotEmpty) {
        return matched
            .map((c) => LinkedPatientCase(
                  patientName: 'Patient #${c.patientId}',
                  status: c.status,
                  isCompleted: c.status.toLowerCase().contains('completed') ||
                      c.status.toLowerCase().contains('evaluated'),
                ))
            .toList();
      }
    }

    return const <LinkedPatientCase>[];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinicReqsAsync = ref.watch(requirementsByClinicProvider(clinic.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          clinic.name,
          style: AppTextStyles.h1Mobile.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              // TODO: Phase 6 - Edit Clinic Quota settings
            },
          ),
        ],
      ),
      body: SafeArea(
        child: clinicReqsAsync.when(
          data: (requirements) => _buildContent(context, ref, requirements),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
          error: (error, stackTrace) {
            AppLogger.error(
              '[ClinicDetailsScreen] Failed to load requirements for clinic ${clinic.id}: $error',
              error,
              stackTrace,
            );
            return DenteraErrorState(
              title: 'Requirements Unavailable',
              message: error.toString(),
              onRetry: () => ref.invalidate(requirementsByClinicProvider(clinic.id)),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_clinic_details',
        onPressed: () {
          AppLogger.info('Opened AddRequirementModal for clinic: ${clinic.id}');
          AddRequirementModal.show(
            context,
            clinicId: clinic.id,
            clinicName: clinic.name,
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.add_rounded,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<Requirement> requirements) {
    if (requirements.isEmpty) {
      AppLogger.debug('Clinic details screen rendering zero state - SQLite returned 0 records for clinic ${clinic.id}');
    }

    final allCasesAsync = ref.watch(allCasesProvider);

    final int totalTarget = requirements.fold(0, (sum, item) => sum + item.targetCount);
    final int totalCompleted = requirements.fold(0, (sum, item) => sum + item.completedCount);
    final double overallProgress = totalTarget > 0 ? (totalCompleted / totalTarget) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 1. Overall Clinic Progress Summary Card
              BaseCard(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: <Widget>[
                    CircularProgressRing(
                      progress: overallProgress,
                      size: 80,
                      strokeWidth: 8,
                      progressColor: _clinicColor,
                      trackColor: AppColors.surfaceContainerHigh,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Overall Progress',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.outline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalCompleted of $totalTarget Requirements Met',
                            style: AppTextStyles.h2.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 13,
                                  color: AppColors.onSecondaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  overallProgress >= 0.5 ? 'On Track' : 'Needs Focus',
                                  style: AppTextStyles.labelCaps.copyWith(
                                    color: AppColors.onSecondaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Section Header: Granular Requirements
              Text(
                'Procedural Requirements',
                style: AppTextStyles.h2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),

              // 3. Requirements List or Zero State
              if (requirements.isEmpty)
                BaseCard(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Column(
                      children: <Widget>[
                        const Icon(
                          Icons.checklist_rounded,
                          size: 40,
                          color: AppColors.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No requirements added yet',
                          style: AppTextStyles.h2.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Define clinical quotas and procedural targets for ${clinic.name}.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requirements.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final req = requirements[index];
                    final List<LinkedPatientCase> linkedCases = _resolveLinkedCases(
                      allCasesAsync.value,
                      req,
                    );

                    return RequirementDetailCard(
                      requirement: req,
                      accentColor: _clinicColor,
                      linkedCases: linkedCases,
                      onTap: () {
                        AppLogger.info('Opened requirement cases bottom sheet for requirement: ${req.id}');
                        RequirementCasesBottomSheet.show(
                          context,
                          requirement: req,
                          accentColor: _clinicColor,
                        );
                      },
                    );
                  },
                ),
              const SizedBox(height: 80), // Padding for FAB
            ],
          ),
        ),
      ),
    );
  }
}
