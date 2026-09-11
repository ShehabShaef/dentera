import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database_providers.dart';
import '../../domain/entities/entities.dart';
import 'cases_provider.dart';
import 'requirements_provider.dart';

/// Provides the list of [TreatmentPlan] items associated with a specific patient,
/// sorted strictly by academic phase and creation date.
final treatmentPlansByPatientProvider =
    FutureProvider.family<List<TreatmentPlan>, String>((ref, patientId) async {
  final repository = ref.watch(treatmentPlanRepositoryProvider);
  return await repository.getTreatmentPlansByPatient(patientId);
});

/// Provides all treatment plans across all patients.
final allTreatmentPlansProvider = FutureProvider<List<TreatmentPlan>>((ref) async {
  final repository = ref.watch(treatmentPlanRepositoryProvider);
  return await repository.getAllTreatmentPlans();
});

/// Controller providing clinical mutations and actions for phased treatment staging.
class TreatmentPlansController {
  TreatmentPlansController(this._ref);

  final Ref _ref;

  /// Inserts a new staged treatment plan item and invalidates the cached family provider.
  Future<void> addPlan(TreatmentPlan plan) async {
    final repo = _ref.read(treatmentPlanRepositoryProvider);
    await repo.addTreatmentPlan(plan);
    _ref.invalidate(treatmentPlansByPatientProvider(plan.patientId));
    _ref.invalidate(allTreatmentPlansProvider);
  }

  /// Updates an existing treatment plan item and refreshes the cache.
  Future<void> updatePlan(TreatmentPlan plan) async {
    final repo = _ref.read(treatmentPlanRepositoryProvider);
    await repo.updateTreatmentPlan(plan);
    _ref.invalidate(treatmentPlansByPatientProvider(plan.patientId));
    _ref.invalidate(allTreatmentPlansProvider);
  }

  /// Marks a proposed treatment plan item as faculty-approved.
  Future<void> approvePlan(TreatmentPlan plan) async {
    final updated = plan.copyWith(status: TreatmentPlan.statusApproved);
    await updatePlan(updated);
  }

  /// Marks a treatment plan item as converted into an active case record.
  Future<void> markConverted(TreatmentPlan plan) async {
    final updated = plan.copyWith(status: TreatmentPlan.statusConverted);
    await updatePlan(updated);
    _ref.invalidate(casesByPatientProvider(plan.patientId));
    _ref.invalidate(allCasesProvider);
    _ref.invalidate(globalQuotaSummaryProvider);
  }

  /// Deletes a specific treatment plan item and refreshes the provider cache.
  Future<void> deletePlan(String planId, String patientId) async {
    final repo = _ref.read(treatmentPlanRepositoryProvider);
    await repo.deleteTreatmentPlan(planId);
    _ref.invalidate(treatmentPlansByPatientProvider(patientId));
    _ref.invalidate(allTreatmentPlansProvider);
  }
}

/// Provider exposing the [TreatmentPlansController].
final treatmentPlansControllerProvider = Provider<TreatmentPlansController>((ref) {
  return TreatmentPlansController(ref);
});
