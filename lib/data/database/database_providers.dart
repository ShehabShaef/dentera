import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/repositories.dart';
import '../repositories/repositories.dart';
import 'app_database.dart';

/// Riverpod provider for the singleton SQLite [AppDatabase] instance.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

/// Riverpod provider for the [PatientRepository].
final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return SqlitePatientRepository(database);
});

/// Riverpod provider for the [ClinicRepository].
final clinicRepositoryProvider = Provider<ClinicRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return SqliteClinicRepository(database);
});

/// Riverpod provider for the [RequirementRepository].
final requirementRepositoryProvider = Provider<RequirementRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return SqliteRequirementRepository(database);
});

/// Riverpod provider for the [CaseRecordRepository].
final caseRecordRepositoryProvider = Provider<CaseRecordRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return SqliteCaseRecordRepository(database);
});

/// Riverpod provider for the [AppointmentRepository].
final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return SqliteAppointmentRepository(database);
});
