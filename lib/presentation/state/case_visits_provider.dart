import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database_providers.dart';
import '../../domain/entities/entities.dart';

/// Provides the list of milestone [CaseVisit]s associated with a specific [CaseRecord].
final caseVisitsByCaseRecordProvider =
    FutureProvider.family<List<CaseVisit>, String>((ref, caseRecordId) async {
  final repository = ref.watch(caseVisitRepositoryProvider);
  return await repository.getVisitsByCaseRecordId(caseRecordId);
});

/// Controller providing clinical mutations and actions for multi-visit tracking.
class CaseVisitsController {
  CaseVisitsController(this._ref);

  final Ref _ref;

  /// Inserts multiple planned visits for a case and invalidates the cached family provider.
  Future<void> addVisits(List<CaseVisit> visits) async {
    if (visits.isEmpty) return;
    final repo = _ref.read(caseVisitRepositoryProvider);
    await repo.addCaseVisits(visits);
    _ref.invalidate(caseVisitsByCaseRecordProvider(visits.first.caseRecordId));
  }

  /// Updates an existing visit's properties and refreshes the cache.
  Future<void> updateVisit(CaseVisit visit) async {
    final repo = _ref.read(caseVisitRepositoryProvider);
    await repo.updateCaseVisit(visit);
    _ref.invalidate(caseVisitsByCaseRecordProvider(visit.caseRecordId));
  }

  /// Marks a specific milestone visit as completed with clinical notes and timestamp.
  Future<void> completeVisit({
    required CaseVisit visit,
    required String notes,
    DateTime? dateCompleted,
  }) async {
    final updated = visit.copyWith(
      status: 'Completed',
      notes: notes,
      dateCompleted: dateCompleted ?? DateTime.now(),
    );
    await updateVisit(updated);
  }

  /// Deletes a specific visit and refreshes the provider.
  Future<void> deleteVisit(CaseVisit visit) async {
    final repo = _ref.read(caseVisitRepositoryProvider);
    await repo.deleteCaseVisit(visit.id);
    _ref.invalidate(caseVisitsByCaseRecordProvider(visit.caseRecordId));
  }
}

/// Provider exposing the [CaseVisitsController].
final caseVisitsControllerProvider = Provider<CaseVisitsController>((ref) {
  return CaseVisitsController(ref);
});
