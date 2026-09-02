import '../entities/entities.dart';

/// Contract for clinical case record persistence and retrieval.
abstract class CaseRecordRepository {
  Future<void> addCaseRecord(CaseRecord caseRecord);
  Future<void> updateCaseRecord(CaseRecord caseRecord);
  Future<List<CaseRecord>> getCaseRecordsByPatientId(String patientId);
  Future<List<CaseRecord>> getCaseRecordsByRequirementId(String requirementId);
  Future<List<CaseRecord>> getAllCaseRecords();
  Future<void> deleteCaseRecord(String id);
}
