import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/repositories/repositories.dart';
import '../repositories/repositories.dart';
import 'app_database.dart';
import 'database_seeder.dart';

/// Signature for onboarding database initialization (Guest demo vs. clean Real User slate).
typedef OnboardingSeeder = Future<void> Function({
  required bool isGuest,
  required String academicYear,
});

/// Riverpod provider for the singleton SQLite [AppDatabase] instance.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

/// Riverpod provider coordinating initial SQLite seeding after onboarding completes.
///
/// - When `isGuest == true`, populates [DatabaseSeeder.seedGuestDemoData].
/// - When `isGuest == false`, ensures [DatabaseSeeder.seedRealUserBaseline] with
///   zero sample patients, zero sample cases, and zero sample appointments.
final onboardingSeederProvider = Provider<OnboardingSeeder>((ref) {
  return ({required bool isGuest, required String academicYear}) async {
    final db = await ref.read(appDatabaseProvider).database;
    if (isGuest) {
      AppLogger.info('[onboardingSeederProvider] Completing Guest onboarding — seeding demo showcase dataset.');
      await DatabaseSeeder.seedGuestDemoData(db);
    } else {
      AppLogger.info('[onboardingSeederProvider] Completing Real User onboarding — enforcing clean clinical slate.');
      await DatabaseSeeder.seedRealUserBaseline(db, academicYear: academicYear);
    }
  };
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

/// Riverpod provider for the [CaseVisitRepository].
final caseVisitRepositoryProvider = Provider<CaseVisitRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return SqliteCaseVisitRepository(database);
});

/// Riverpod provider for the [TreatmentPlanRepository].
final treatmentPlanRepositoryProvider = Provider<TreatmentPlanRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return SqliteTreatmentPlanRepository(database);
});

/// Riverpod provider for the [RadiographRepository].
final radiographRepositoryProvider = Provider<RadiographRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return SqliteRadiographRepository(database);
});

