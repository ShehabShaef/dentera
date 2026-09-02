import '../entities/entities.dart';

/// Contract for clinic department persistence and retrieval.
abstract class ClinicRepository {
  Future<List<Clinic>> getAllClinics();
  Future<Clinic?> getClinicById(String id);
  Future<void> addClinic(Clinic clinic);
}
