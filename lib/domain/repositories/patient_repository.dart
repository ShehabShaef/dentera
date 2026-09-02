import '../entities/entities.dart';

/// Contract for patient persistence and retrieval.
abstract class PatientRepository {
  Future<void> addPatient(Patient patient);
  Future<void> updatePatient(Patient patient);
  Future<void> deletePatient(String id);
  Future<List<Patient>> getAllPatients();
  Future<Patient?> getPatientById(String id);
}
