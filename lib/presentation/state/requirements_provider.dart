import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database_providers.dart';
import '../../domain/entities/entities.dart';

/// Provides the list of requirements for a specific clinic.
///
/// **Error Propagation Architecture:**
/// Database exceptions are allowed to propagate to Riverpod's [FutureProvider.family],
/// wrapping errors into [AsyncError] rather than masking database failures with empty lists.
final requirementsByClinicProvider =
    FutureProvider.family<List<Requirement>, String>((ref, clinicId) async {
  final repository = ref.watch(requirementRepositoryProvider);
  return await repository.getRequirementsByClinicId(clinicId);
});

/// Provides all clinical requirements across all departments.
///
/// **Error Propagation Architecture:**
/// Exceptions thrown by [RequirementRepository.getAllRequirements] propagate naturally
/// to Riverpod, transitioning the provider to [AsyncError] and allowing [globalQuotaSummaryProvider]
/// and consumer widgets to display actionable error interfaces.
final allRequirementsProvider = FutureProvider<List<Requirement>>((ref) async {
  final repository = ref.watch(requirementRepositoryProvider);
  return await repository.getAllRequirements();
});

/// Aggregate quota stats across the entire application.
class GlobalQuotaStats {
  const GlobalQuotaStats({
    required this.totalTarget,
    required this.totalCompleted,
    required this.progressFraction,
  });

  final int totalTarget;
  final int totalCompleted;
  final double progressFraction;
}

/// Provides overall aggregate quota completion statistics for the dashboard and clinics overview.
final globalQuotaSummaryProvider = Provider<AsyncValue<GlobalQuotaStats>>((ref) {
  final allReqsAsync = ref.watch(allRequirementsProvider);

  return allReqsAsync.whenData((requirements) {
    int totalTarget = 0;
    int totalCompleted = 0;

    for (final req in requirements) {
      totalTarget += req.targetCount;
      totalCompleted += req.completedCount;
    }

    final double progress = totalTarget > 0 ? (totalCompleted / totalTarget).clamp(0.0, 1.0) : 0.0;

    return GlobalQuotaStats(
      totalTarget: totalTarget,
      totalCompleted: totalCompleted,
      progressFraction: progress,
    );
  });
});

/// Sorting criteria for clinical requirements / cases within a clinic.
enum ClinicRequirementSortOption {
  title,
  progress,
  targetCount,
}

/// Tracks the active sorting preference for requirements of a clinic.
final clinicRequirementSortOptionProvider =
    StateProvider.family<ClinicRequirementSortOption, String>(
  (ref, clinicId) => ClinicRequirementSortOption.title,
);

/// Tracks selection mode on ClinicDetailsScreen for batch requirement deletion.
final clinicRequirementSelectionModeProvider =
    StateProvider.family<bool, String>((ref, clinicId) => false);

/// Tracks selected requirement IDs for batch deletion in a clinic.
final selectedClinicRequirementIdsProvider =
    StateProvider.family<Set<String>, String>((ref, clinicId) => <String>{});

