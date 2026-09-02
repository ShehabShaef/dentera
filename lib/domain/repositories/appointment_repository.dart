import '../entities/entities.dart';

/// Contract for appointment scheduling and retrieval.
abstract class AppointmentRepository {
  Future<void> addAppointment(Appointment appointment);
  Future<void> updateAppointment(Appointment appointment);
  Future<void> deleteAppointment(String id);
  Future<List<Appointment>> getAppointmentsByDate(DateTime date);
  Future<List<Appointment>> getAppointmentsByPatientId(String patientId);
  Future<List<Appointment>> getAllAppointments();
}
