import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/error/exceptions.dart';
import 'package:dentera/core/logging/app_provider_observer.dart';
import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/database/database_providers.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/domain/repositories/repositories.dart';
import 'package:dentera/presentation/screens/appointments/appointments_screen.dart';
import 'package:dentera/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:dentera/presentation/screens/patients/patients_screen.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/feedback/error_state_widget.dart';

/// Test mock of [PatientRepository] throwing simulated SQLite exceptions.
class ThrowingPatientRepository implements PatientRepository {
  ThrowingPatientRepository([this.error]);

  final Object? error;

  @override
  Future<List<Patient>> getAllPatients() async {
    throw error ?? const LocalDatabaseException('Simulated SQLite disk I/O failure');
  }

  @override
  Future<Patient?> getPatientById(String id) async => null;

  @override
  Future<void> addPatient(Patient patient) async {}

  @override
  Future<void> updatePatient(Patient patient) async {}

  @override
  Future<void> deletePatient(String id) async {}
}

/// Test mock of [ClinicRepository] throwing simulated SQLite exceptions.
class ThrowingClinicRepository implements ClinicRepository {
  @override
  Future<List<Clinic>> getAllClinics() async {
    throw const LocalDatabaseException('Simulated SQLite table lock contention');
  }

  @override
  Future<Clinic?> getClinicById(String id) async => null;

  @override
  Future<void> addClinic(Clinic clinic) async {}
}

/// Test mock of [RequirementRepository] throwing simulated SQLite exceptions.
class ThrowingRequirementRepository implements RequirementRepository {
  @override
  Future<List<Requirement>> getAllRequirements() async {
    throw const LocalDatabaseException('Simulated SQLite requirement query error');
  }

  @override
  Future<List<Requirement>> getRequirementsByClinicId(String clinicId) async {
    throw const LocalDatabaseException('Simulated SQLite clinic requirements error');
  }

  @override
  Future<void> addRequirement(Requirement requirement) async {}

  @override
  Future<void> updateRequirementProgress(String requirementId, int completedCount) async {}
}

/// Test mock of [AppointmentRepository] throwing simulated SQLite exceptions.
class ThrowingAppointmentRepository implements AppointmentRepository {
  @override
  Future<List<Appointment>> getAppointmentsByDate(DateTime date) async {
    throw const LocalDatabaseException('Simulated SQLite daily appointments query error');
  }

  @override
  Future<List<Appointment>> getAllAppointments() async {
    throw const LocalDatabaseException('Simulated SQLite all appointments query error');
  }

  @override
  Future<List<Appointment>> getAppointmentsByPatientId(String patientId) async => <Appointment>[];

  @override
  Future<void> addAppointment(Appointment appointment) async {}

  @override
  Future<void> updateAppointment(Appointment appointment) async {}

  @override
  Future<void> deleteAppointment(String id) async {}
}

/// Test spy observer capturing failures reported to [providerDidFail].
class TestProviderFailureObserver extends ProviderObserver {
  final List<ProviderBase<Object?>> failedProviders = <ProviderBase<Object?>>[];
  final List<Object> caughtErrors = <Object>[];

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    failedProviders.add(provider);
    caughtErrors.add(error);
  }
}

void main() {
  group('Provider Error Propagation Unit Tests', () {
    test('patientListProvider transitions to AsyncError when repository throws', () async {
      final container = ProviderContainer(
        overrides: [
          patientRepositoryProvider.overrideWithValue(ThrowingPatientRepository()),
        ],
      );
      addTearDown(container.dispose);

      // Verify that the provider evaluates to AsyncError and does NOT swallow error as empty list
      try {
        await container.read(patientListProvider.future);
      } catch (_) {}

      final asyncValue = container.read(patientListProvider);
      expect(asyncValue.hasError, isTrue);
      expect(asyncValue.error, isA<LocalDatabaseException>());
      expect((asyncValue.error as LocalDatabaseException).message, contains('SQLite disk I/O failure'));

      // Also verify filteredPatientListProvider propagates the error
      final filteredVal = container.read(filteredPatientListProvider);
      expect(filteredVal.hasError, isTrue);
      expect(filteredVal.error, isA<LocalDatabaseException>());
    });

    test('clinicListProvider transitions to AsyncError on database exception', () async {
      final container = ProviderContainer(
        overrides: [
          clinicRepositoryProvider.overrideWithValue(ThrowingClinicRepository()),
        ],
      );
      addTearDown(container.dispose);

      try {
        await container.read(clinicListProvider.future);
      } catch (_) {}

      final asyncValue = container.read(clinicListProvider);
      expect(asyncValue.hasError, isTrue);
      expect(asyncValue.error, isA<LocalDatabaseException>());
      expect((asyncValue.error as LocalDatabaseException).message, contains('table lock contention'));
    });

    test('allRequirementsProvider transitions to AsyncError and propagates to globalQuotaSummaryProvider', () async {
      final container = ProviderContainer(
        overrides: [
          requirementRepositoryProvider.overrideWithValue(ThrowingRequirementRepository()),
        ],
      );
      addTearDown(container.dispose);

      try {
        await container.read(allRequirementsProvider.future);
      } catch (_) {}

      final asyncValue = container.read(allRequirementsProvider);
      expect(asyncValue.hasError, isTrue);
      expect(asyncValue.error, isA<LocalDatabaseException>());

      // Verify globalQuotaSummaryProvider also reflects error
      final quotaStats = container.read(globalQuotaSummaryProvider);
      expect(quotaStats.hasError, isTrue);
    });

    test('dailyAppointmentsProvider transitions to AsyncError on database exception', () async {
      final today = DateTime(2026, 9, 4);
      final container = ProviderContainer(
        overrides: [
          appointmentRepositoryProvider.overrideWithValue(ThrowingAppointmentRepository()),
        ],
      );
      addTearDown(container.dispose);

      try {
        await container.read(dailyAppointmentsProvider(today).future);
      } catch (_) {}

      final asyncValue = container.read(dailyAppointmentsProvider(today));
      expect(asyncValue.hasError, isTrue);
      expect(asyncValue.error, isA<LocalDatabaseException>());
      expect((asyncValue.error as LocalDatabaseException).message, contains('daily appointments query error'));
    });

    test('AppProviderObserver intercepts providerDidFail on repository exception', () async {
      final failureObserver = TestProviderFailureObserver();
      final container = ProviderContainer(
        observers: [
          const AppProviderObserver(),
          failureObserver,
        ],
        overrides: [
          patientRepositoryProvider.overrideWithValue(ThrowingPatientRepository()),
        ],
      );
      addTearDown(container.dispose);

      try {
        await container.read(patientListProvider.future);
      } catch (_) {
        // Expected exception
      }

      // Assert that observer intercepted the failed provider and exact exception
      expect(failureObserver.failedProviders, isNotEmpty);
      expect(failureObserver.failedProviders.first, equals(patientListProvider));
      expect(failureObserver.caughtErrors.first, isA<LocalDatabaseException>());
    });
  });

  group('UI Screen Error State Widget Tests', () {
    testWidgets('PatientsScreen renders DenteraErrorState with Retry button on error', (WidgetTester tester) async {
      int retryCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientListProvider.overrideWith((ref) {
              if (retryCount == 0) {
                throw const LocalDatabaseException('Connection lost to local SQLite DB');
              }
              return <Patient>[];
            }),
            allCasesProvider.overrideWith((ref) => <CaseRecord>[]),
          ],
          child: const MaterialApp(
            home: PatientsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify DenteraErrorState is rendered
      expect(find.byType(DenteraErrorState), findsOneWidget);
      expect(find.text('Failed to load patients'), findsOneWidget);
      expect(find.textContaining('Connection lost to local SQLite DB'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Tap Retry to trigger invalidation
      retryCount++;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Should now transition to zero state after retry succeeds
      expect(find.byType(DenteraErrorState), findsNothing);
      expect(find.text('Add First Patient'), findsOneWidget);
    });

    testWidgets('AppointmentsScreen renders DenteraErrorState with Retry button on error', (WidgetTester tester) async {
      int retryCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyAppointmentsProvider.overrideWith((ref, date) {
              if (retryCount == 0) {
                throw const LocalDatabaseException('Disk read failure in appointments');
              }
              return <Appointment>[];
            }),
            patientListProvider.overrideWith((ref) => <Patient>[]),
            clinicListProvider.overrideWith((ref) => <Clinic>[]),
          ],
          child: const MaterialApp(
            home: AppointmentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify DenteraErrorState is displayed instead of empty schedule
      expect(find.byType(DenteraErrorState), findsOneWidget);
      expect(find.text('Failed to load schedule'), findsOneWidget);
      expect(find.textContaining('Disk read failure in appointments'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Tap Retry
      retryCount++;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // After successful retry, zero state prompt is shown
      expect(find.byType(DenteraErrorState), findsNothing);
      expect(find.text('No appointments scheduled'), findsOneWidget);
    });

    testWidgets('DashboardScreen renders compact DenteraErrorState cards on section failure', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allRequirementsProvider.overrideWith((ref) {
              throw const LocalDatabaseException('Requirements quota failure');
            }),
            dailyAppointmentsProvider.overrideWith((ref, date) {
              throw const LocalDatabaseException('Appointments failure');
            }),
            upcomingAppointmentsProvider.overrideWith((ref) {
              throw const LocalDatabaseException('Upcoming failure');
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify compact error states are rendered for failed dashboard sections
      expect(find.byType(DenteraErrorState), findsNWidgets(3));
      expect(find.text('Quota Statistics Unavailable'), findsOneWidget);
      expect(find.text('Appointments Unavailable'), findsOneWidget);
      expect(find.text('Upcoming Patients Unavailable'), findsOneWidget);
    });
  });
}
