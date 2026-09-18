import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../data/database/database_providers.dart';
import '../../../domain/entities/entities.dart';
import '../../../l10n/l10n.dart';
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
/// - **Clinic Editing ([EditClinicModal]):** Tapping "Edit Clinic" in the 3-dot popup menu
///   opens [EditClinicModal] to modify name, academic year, and color in-place.
/// - **Requirement Definition ([AddRequirementModal]):** Tapping the screen's Floating Action Button
///   opens [AddRequirementModal], allowing dental students to define new clinical procedures and target quotas.
/// - **Requirement Editing ([EditRequirementModal]):** Tapping the edit icon on any [RequirementDetailCard]
///   opens [EditRequirementModal] to adjust title and targetCount in-place.
/// - **Sorting ([SortClinicCasesModal]):** Tapping "Sort Cases" allows sorting requirements by Name (A-Z),
///   Quota Progress, or Target Quota.
/// - **Batch Deletion:** Tapping "Delete Cases" enters selection mode, allowing multi-select requirement deletion
///   with cascade warning.
/// - **Relational Case Inspection ([RequirementCasesBottomSheet]):** Tapping any [RequirementDetailCard]
///   triggers [RequirementCasesBottomSheet], fetching and displaying all clinical [CaseRecord] entries.
class ClinicDetailsScreen extends ConsumerWidget {
  const ClinicDetailsScreen({
    super.key,
    required this.clinic,
  });

  final Clinic clinic;

  Color _resolveClinicColor(Clinic clinic) {
    try {
      final hex = clinic.colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  List<LinkedPatientCase> _resolveLinkedCases(
    List<CaseRecord>? cases,
    Requirement req, [
    Map<String, String>? patientMap,
  ]) {
    if (cases != null && cases.isNotEmpty) {
      final matched = cases.where((c) => c.requirementId == req.id).toList();
      if (matched.isNotEmpty) {
        return matched
            .map((c) => LinkedPatientCase(
                  patientName: patientMap?[c.patientId] ?? 'Patient #${c.patientId}',
                  status: c.status,
                  isCompleted: c.status.toLowerCase().contains('completed') ||
                      c.status.toLowerCase().contains('evaluated'),
                ))
            .toList();
      }
    }

    return const <LinkedPatientCase>[];
  }

  Future<void> _confirmBatchDeleteRequirements(
    BuildContext context,
    WidgetRef ref,
    String clinicId,
    Set<String> selectedIds,
  ) async {
    if (selectedIds.isEmpty) return;

    final count = selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Selected Requirements?'),
        content: Text(
          'Deleting $count procedural requirement${count > 1 ? 's' : ''} will permanently remove all associated student case records due to cascade deletion.\n\nThis action cannot be undone. Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(requirementRepositoryProvider);
      await repository.deleteRequirements(selectedIds.toList());

      ref.read(clinicRequirementSelectionModeProvider(clinicId).notifier).state = false;
      ref.read(selectedClinicRequirementIdsProvider(clinicId).notifier).state = <String>{};

      ref.invalidate(requirementsByClinicProvider(clinicId));
      ref.invalidate(allRequirementsProvider);
      ref.invalidate(allCasesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully deleted $count requirement${count > 1 ? 's' : ''}.',
            ),
          ),
        );
      }
    } catch (e, st) {
      AppLogger.error('Failed to batch delete requirements: $selectedIds', e, st);
      if (context.mounted) {
        DenteraSnackBar.showError(
          context,
          message: 'Failed to delete selected requirements',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dynamically track current clinic from repository list to reflect edits immediately
    final allClinics = ref.watch(clinicListProvider).valueOrNull;
    final currentClinic = allClinics?.where((c) => c.id == clinic.id).firstOrNull ?? clinic;
    final clinicColor = _resolveClinicColor(currentClinic);

    final clinicReqsAsync = ref.watch(requirementsByClinicProvider(currentClinic.id));
    final isSelectionMode = ref.watch(clinicRequirementSelectionModeProvider(currentClinic.id));
    final selectedIds = ref.watch(selectedClinicRequirementIdsProvider(currentClinic.id));
    final sortOption = ref.watch(clinicRequirementSortOptionProvider(currentClinic.id));

    // Sort requirements if available
    final rawRequirements = clinicReqsAsync.valueOrNull ?? const <Requirement>[];
    final sortedRequirements = [...rawRequirements];
    switch (sortOption) {
      case ClinicRequirementSortOption.title:
        sortedRequirements.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case ClinicRequirementSortOption.progress:
        sortedRequirements.sort((a, b) {
          final progA = a.targetCount > 0 ? (a.completedCount / a.targetCount) : 0.0;
          final progB = b.targetCount > 0 ? (b.completedCount / b.targetCount) : 0.0;
          return progB.compareTo(progA);
        });
        break;
      case ClinicRequirementSortOption.targetCount:
        sortedRequirements.sort((a, b) => b.targetCount.compareTo(a.targetCount));
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  ref.read(clinicRequirementSelectionModeProvider(currentClinic.id).notifier).state = false;
                  ref.read(selectedClinicRequirementIdsProvider(currentClinic.id).notifier).state = <String>{};
                },
              ),
              title: Text(
                context.l10n.selectedCount(selectedIds.length),
                style: AppTextStyles.h1Mobile.copyWith(
                  color: isDark ? AppDarkColors.textPrimary : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: sortedRequirements.isEmpty
                      ? null
                      : () {
                          final allIds = sortedRequirements.map((r) => r.id).toSet();
                          if (selectedIds.length == sortedRequirements.length) {
                            ref.read(selectedClinicRequirementIdsProvider(currentClinic.id).notifier).state = <String>{};
                          } else {
                            ref.read(selectedClinicRequirementIdsProvider(currentClinic.id).notifier).state = allIds;
                          }
                        },
                  child: Text(
                    selectedIds.length == sortedRequirements.length ? context.l10n.deselectAll : context.l10n.selectAll,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  tooltip: context.l10n.deleteSelected,
                  onPressed: selectedIds.isEmpty
                      ? null
                      : () => _confirmBatchDeleteRequirements(context, ref, currentClinic.id, selectedIds),
                ),
              ],
            )
          : AppBar(
              title: Text(
                currentClinic.name,
                style: AppTextStyles.h1Mobile.copyWith(
                  color: isDark ? AppDarkColors.textPrimary : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  tooltip: context.l10n.generateQuotaReport,
                  onPressed: () => GenerateQuotaReportModal.show(context, clinic: currentClinic),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  tooltip: 'Options',
                  onSelected: (value) async {
                    switch (value) {
                      case 'generate_report':
                        await GenerateQuotaReportModal.show(context, clinic: currentClinic);
                        break;
                      case 'edit_clinic':
                        await EditClinicModal.show(context, clinic: currentClinic);
                        break;
                      case 'sort_cases':
                        await SortClinicCasesModal.show(context, clinicId: currentClinic.id);
                        break;
                      case 'delete_cases':
                        ref.read(clinicRequirementSelectionModeProvider(currentClinic.id).notifier).state = true;
                        ref.read(selectedClinicRequirementIdsProvider(currentClinic.id).notifier).state = <String>{};
                        break;
                    }
                  },
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'generate_report',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf_outlined, size: 20, color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.l10n.generateQuotaReport,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'edit_clinic',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20, color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface),
                          const SizedBox(width: 12),
                          Text(context.l10n.editClinic),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'sort_cases',
                      child: Row(
                        children: [
                          Icon(Icons.sort_rounded, size: 20, color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface),
                          const SizedBox(width: 12),
                          Text(context.l10n.sortCases),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'delete_cases',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_sweep_outlined, size: 20, color: AppColors.error),
                          const SizedBox(width: 12),
                          Text(
                            context.l10n.deleteCases,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
      body: SafeArea(
        child: clinicReqsAsync.when(
          data: (_) => _buildContent(
            context,
            ref,
            currentClinic,
            clinicColor,
            sortedRequirements,
            isSelectionMode,
            selectedIds,
          ),
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
              '[ClinicDetailsScreen] Failed to load requirements for clinic ${currentClinic.id}: $error',
              error,
              stackTrace,
            );
            return DenteraErrorState(
              title: 'Requirements Unavailable',
              message: error.toString(),
              onRetry: () => ref.invalidate(requirementsByClinicProvider(currentClinic.id)),
            );
          },
        ),
      ),
      floatingActionButton: isSelectionMode
          ? null
          : FloatingActionButton(
              heroTag: 'fab_clinic_details',
              onPressed: () {
                AppLogger.info('Opened AddRequirementModal for clinic: ${currentClinic.id}');
                AddRequirementModal.show(
                  context,
                  clinicId: currentClinic.id,
                  clinicName: currentClinic.name,
                );
              },
              backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor ?? (isDark ? AppDarkColors.primaryTeal : AppColors.primary),
              foregroundColor: Theme.of(context).floatingActionButtonTheme.foregroundColor ?? (isDark ? AppDarkColors.onPrimary : AppColors.onPrimary),
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

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Clinic currentClinic,
    Color clinicColor,
    List<Requirement> requirements,
    bool isSelectionMode,
    Set<String> selectedIds,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (requirements.isEmpty) {
      AppLogger.debug('Clinic details screen rendering zero state - SQLite returned 0 records for clinic ${currentClinic.id}');
    }

    final allCasesAsync = ref.watch(allCasesProvider);
    final patientsAsync = ref.watch(patientListProvider);
    final patientMap = {
      for (final p in patientsAsync.valueOrNull ?? const <Patient>[]) p.id: p.name,
    };

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
                      progressColor: clinicColor,
                      trackColor: isDark ? AppDarkColors.progressTrack : AppColors.surfaceContainerHigh,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            context.l10n.overallProgress,
                            style: AppTextStyles.caption.copyWith(
                              color: isDark ? AppDarkColors.textMuted : AppColors.outline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.requirementsMet(totalCompleted, totalTarget),
                            style: AppTextStyles.h2.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? AppDarkColors.primaryTeal.withValues(alpha: 0.15) : AppColors.secondaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 13,
                                  color: isDark ? AppDarkColors.primaryTeal : AppColors.onSecondaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  overallProgress >= 0.5 ? context.l10n.onTrack : context.l10n.needsFocus,
                                  style: AppTextStyles.labelCaps.copyWith(
                                    color: isDark ? AppDarkColors.primaryTeal : AppColors.onSecondaryContainer,
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
                context.l10n.proceduralRequirements,
                style: AppTextStyles.h2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppDarkColors.textPrimary : AppColors.primary,
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
                        Icon(
                          Icons.checklist_rounded,
                          size: 40,
                          color: isDark ? AppDarkColors.textMuted : AppColors.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.noRequirementsAddedYet,
                          style: AppTextStyles.h2.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.defineClinicalQuotasForClinic(currentClinic.name),
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
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
                      allCasesAsync.valueOrNull,
                      req,
                      patientMap,
                    );
                    final isSelected = selectedIds.contains(req.id);

                    if (isSelectionMode) {
                      return InkWell(
                        onTap: () {
                          final newSelected = Set<String>.from(selectedIds);
                          if (isSelected) {
                            newSelected.remove(req.id);
                          } else {
                            newSelected.add(req.id);
                          }
                          ref.read(selectedClinicRequirementIdsProvider(currentClinic.id).notifier).state = newSelected;
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: CircularCheckbox(
                                isSelected: isSelected,
                                onChanged: (_) {
                                  final newSelected = Set<String>.from(selectedIds);
                                  if (isSelected) {
                                    newSelected.remove(req.id);
                                  } else {
                                    newSelected.add(req.id);
                                  }
                                  ref.read(selectedClinicRequirementIdsProvider(currentClinic.id).notifier).state = newSelected;
                                },
                              ),
                            ),
                            Expanded(
                              child: RequirementDetailCard(
                                requirement: req,
                                accentColor: clinicColor,
                                linkedCases: linkedCases,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RequirementDetailCard(
                      requirement: req,
                      accentColor: clinicColor,
                      linkedCases: linkedCases,
                      onTap: () {
                        AppLogger.info('Opened requirement cases bottom sheet for requirement: ${req.id}');
                        RequirementCasesBottomSheet.show(
                          context,
                          requirement: req,
                          accentColor: clinicColor,
                        );
                      },
                      onEdit: () {
                        AppLogger.info('Opened EditRequirementModal for requirement: ${req.id}');
                        EditRequirementModal.show(
                          context,
                          requirement: req,
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
