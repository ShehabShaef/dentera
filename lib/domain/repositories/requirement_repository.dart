import '../entities/entities.dart';

/// Contract for clinical requirement quota tracking and retrieval.
abstract class RequirementRepository {
  Future<List<Requirement>> getRequirementsByClinicId(String clinicId);
  Future<List<Requirement>> getAllRequirements();
  Future<void> updateRequirementProgress(String requirementId, int completedCount);
  Future<void> addRequirement(Requirement requirement);
}
