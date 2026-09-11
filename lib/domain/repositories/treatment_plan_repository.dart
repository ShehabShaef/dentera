import '../entities/entities.dart';

/// Contract for patient phased treatment staging and care persistence.
abstract class TreatmentPlanRepository {
  Future<void> addTreatmentPlan(TreatmentPlan plan);
  Future<void> updateTreatmentPlan(TreatmentPlan plan);
  Future<void> deleteTreatmentPlan(String id);
  Future<TreatmentPlan?> getTreatmentPlanById(String id);
  Future<List<TreatmentPlan>> getTreatmentPlansByPatient(String patientId);
  Future<List<TreatmentPlan>> getAllTreatmentPlans();
}
