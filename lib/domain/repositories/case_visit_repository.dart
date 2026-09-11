import '../entities/entities.dart';

/// Contract for multi-visit case tracking and milestone persistence.
abstract class CaseVisitRepository {
  Future<void> addCaseVisit(CaseVisit caseVisit);
  Future<void> addCaseVisits(List<CaseVisit> caseVisits);
  Future<void> updateCaseVisit(CaseVisit caseVisit);
  Future<void> deleteCaseVisit(String id);
  Future<List<CaseVisit>> getVisitsByCaseRecordId(String caseRecordId);
  Future<List<CaseVisit>> getAllVisits();
}
