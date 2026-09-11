import '../entities/entities.dart';

/// Contract for patient radiograph (X-ray) persistence and retrieval.
abstract class RadiographRepository {
  Future<void> addRadiograph(PatientRadiograph radiograph);
  Future<void> updateRadiograph(PatientRadiograph radiograph);
  Future<void> deleteRadiograph(String id);
  Future<PatientRadiograph?> getRadiographById(String id);
  Future<List<PatientRadiograph>> getRadiographsByPatient(String patientId);
  Future<List<PatientRadiograph>> getAllRadiographs();
}
