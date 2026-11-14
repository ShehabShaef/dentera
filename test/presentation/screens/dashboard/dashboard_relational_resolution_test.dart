import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dentera/data/database/app_database.dart';
import 'package:dentera/data/repositories/sqlite_appointment_repository.dart';
import 'package:dentera/data/repositories/sqlite_patient_repository.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:dentera/presentation/state/state.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'doctorName': 'Dr. Shehab',
      'academicYear': '5th Year',
      'hasCompletedOnboarding': true,
    });
  });

  group('Relational Entity Resolution Tests (Issue #51)', () {
    test('SqliteAppointmentRepository populates patientName via LEFT JOIN patients', () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db.execute('''
        CREATE TABLE patients (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          age INTEGER NOT NULL,
          gender TEXT NOT NULL,
          phoneNumber TEXT,
          medicalHistory TEXT,
          chiefComplaint TEXT,
          historyOfChiefComplaint TEXT,
          dentalHistory TEXT,
          medications TEXT,
          diagnosticAids TEXT,
          createdAt TEXT NOT NULL
        );
      ''');
      await db.execute('''
        CREATE TABLE clinics (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          academicYear TEXT NOT NULL,
          colorHex TEXT NOT NULL
        );
      ''');
      await db.execute('''
        CREATE TABLE appointments (
          id TEXT PRIMARY KEY,
          patientId TEXT NOT NULL,
          clinicId TEXT NOT NULL,
          scheduledDate TEXT NOT NULL,
          status TEXT NOT NULL,
          procedureDescription TEXT,
          FOREIGN KEY (patientId) REFERENCES patients (id) ON DELETE CASCADE,
          FOREIGN KEY (clinicId) REFERENCES clinics (id) ON DELETE CASCADE
        );
      ''');

      final appDb = AppDatabase.withDatabase(db);
      final patientRepo = SqlitePatientRepository(appDb);
      final appointmentRepo = SqliteAppointmentRepository(appDb);

      // Insert patient
      final patient = Patient(
        id: 'patient-uuid-1234-5678',
        name: 'Mustafa Al-Hakimi',
        age: 32,
        gender: 'Male',
        phoneNumber: '+967-770000000',
        medicalHistory: 'None',
        createdAt: DateTime.now(),
      );
      await patientRepo.addPatient(patient);

      // Insert appointment
      final scheduledTime = DateTime.now();
      final appointment = Appointment(
        id: 'apt-001',
        patientId: patient.id,
        clinicId: 'clinic-01',
        scheduledDate: scheduledTime,
        status: 'Scheduled',
        procedureDescription: 'Root Canal Preparation',
      );
      await appointmentRepo.addAppointment(appointment);

      // Query appointments for today
      final apts = await appointmentRepo.getAppointmentsByDate(scheduledTime);
      expect(apts.length, equals(1));
      expect(apts.first.id, equals('apt-001'));
      expect(apts.first.patientId, equals('patient-uuid-1234-5678'));
      // Verify patientName is populated via the LEFT JOIN
      expect(apts.first.patientName, equals('Mustafa Al-Hakimi'));

      await db.close();
    });

    testWidgets('DashboardScreen displays resolved patient name for Today and Tomorrow appointments', (WidgetTester tester) async {
      final scheduledTime = DateTime.now();
      final tomorrowTime = scheduledTime.add(const Duration(days: 1));

      final patient1 = Patient(
        id: 'pt-uuid-999',
        name: 'Fatima Al-Zahra',
        age: 26,
        gender: 'Female',
        phoneNumber: '+967-771234567',
        medicalHistory: 'None',
        createdAt: DateTime.now(),
      );

      final patient2 = Patient(
        id: 'pt-uuid-888',
        name: 'Zaid Tareq',
        age: 40,
        gender: 'Male',
        phoneNumber: '+967-777654321',
        medicalHistory: 'None',
        createdAt: DateTime.now(),
      );

      final todayApt = Appointment(
        id: 'apt-today-01',
        patientId: patient1.id,
        clinicId: 'clinic-perio',
        scheduledDate: scheduledTime,
        status: 'Confirmed',
        procedureDescription: 'Deep Scaling & Root Planing',
        patientName: patient1.name,
      );

      final tomorrowApt = Appointment(
        id: 'apt-tmrw-01',
        patientId: patient2.id,
        clinicId: 'clinic-op',
        scheduledDate: tomorrowTime,
        status: 'Scheduled',
        procedureDescription: 'Composite Restoration',
        patientName: patient2.name,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyAppointmentsProvider(DateTime(scheduledTime.year, scheduledTime.month, scheduledTime.day))
                .overrideWith((ref) => <Appointment>[todayApt]),
            upcomingAppointmentsProvider.overrideWith((ref) => <Appointment>[tomorrowApt]),
            patientListProvider.overrideWith((ref) => <Patient>[patient1, patient2]),
            allCasesProvider.overrideWith((ref) => <CaseRecord>[]),
            allRequirementsProvider.overrideWith((ref) => <Requirement>[]),
            clinicListProvider.overrideWith((ref) => <Clinic>[]),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert that actual human-readable patient names are displayed, NOT raw UUIDs
      expect(find.text('Fatima Al-Zahra'), findsOneWidget);
      expect(find.text('Zaid Tareq'), findsOneWidget);
      expect(find.text('Patient #pt-uuid-999'), findsNothing);
      expect(find.text('Patient #pt-uuid-888'), findsNothing);
    });

    test('clinicalRemindersProvider resolves Requirement title and Patient name in overdue cases', () {
      final now = DateTime(2026, 11, 14, 10, 0);

      const requirement = Requirement(
        id: 'req-endo-01',
        clinicId: 'clinic-endo',
        title: 'Molar Endodontics',
        targetCount: 5,
        completedCount: 2,
      );

      final patient = Patient(
        id: 'pt-clinical-456',
        name: 'Bilal Mansoor',
        age: 35,
        gender: 'Male',
        phoneNumber: '+967-779988776',
        medicalHistory: 'None',
        createdAt: DateTime(2026, 10, 1),
      );

      final overdueCase = CaseRecord(
        id: 'case-record-uuid-bc9e85',
        patientId: patient.id,
        requirementId: requirement.id,
        status: 'In Progress',
        dateStarted: now.subtract(const Duration(days: 20)),
        dateCompleted: null,
      );

      final container = ProviderContainer(
        overrides: [
          clinicalRemindersClockProvider.overrideWithValue(now),
          allCasesProvider.overrideWith((ref) => <CaseRecord>[overdueCase]),
          allAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
          dailyAppointmentsProvider(DateTime(now.year, now.month, now.day))
              .overrideWith((ref) => <Appointment>[]),
          upcomingAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
          clinicListProvider.overrideWith((ref) => <Clinic>[]),
          allRequirementsProvider.overrideWith((ref) => <Requirement>[requirement]),
          patientListProvider.overrideWith((ref) => <Patient>[patient]),
        ],
      );
      addTearDown(container.dispose);

      final reminders = container.read(clinicalRemindersProvider);
      expect(reminders.length, equals(1));

      final overdueReminder = reminders.first;
      expect(overdueReminder.category, equals(ReminderCategory.overdueCase));

      // Must display "Molar Endodontics (Bilal Mansoor): overdue (20 days in progress)"
      // and NOT a raw ID like "#bc9e85"
      expect(overdueReminder.message, contains('Molar Endodontics (Bilal Mansoor)'));
      expect(overdueReminder.message, contains('overdue (20 days in progress)'));
      expect(overdueReminder.message, isNot(contains('#case-record-uuid-bc9e85')));
      expect(overdueReminder.message, isNot(contains('bc9e85')));
    });

    test('clinicalRemindersProvider falls back gracefully and warns on orphaned IDs', () {
      final now = DateTime(2026, 11, 14, 10, 0);

      // Case record with IDs that do not exist in requirements or patients list
      final orphanedCase = CaseRecord(
        id: 'case-orphan-1',
        patientId: 'pt-non-existent',
        requirementId: 'req-non-existent',
        status: 'In Progress',
        dateStarted: now.subtract(const Duration(days: 15)),
        dateCompleted: null,
      );

      final container = ProviderContainer(
        overrides: [
          clinicalRemindersClockProvider.overrideWithValue(now),
          allCasesProvider.overrideWith((ref) => <CaseRecord>[orphanedCase]),
          allAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
          dailyAppointmentsProvider(DateTime(now.year, now.month, now.day))
              .overrideWith((ref) => <Appointment>[]),
          upcomingAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
          clinicListProvider.overrideWith((ref) => <Clinic>[]),
          allRequirementsProvider.overrideWith((ref) => <Requirement>[]),
          patientListProvider.overrideWith((ref) => <Patient>[]),
        ],
      );
      addTearDown(container.dispose);

      final reminders = container.read(clinicalRemindersProvider);
      expect(reminders.length, equals(1));
      expect(reminders.first.category, equals(ReminderCategory.overdueCase));
      expect(reminders.first.message, contains('Case: overdue (15 days in progress)'));
    });
  });
}
