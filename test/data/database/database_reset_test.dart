import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/data/database/app_database.dart';
import 'package:dentera/data/models/models.dart';
import 'package:dentera/data/repositories/preferences_repository.dart';

import '../../setup/test_setup.dart';

void main() {
  setUpAll(() {
    setupDatabaseTests();
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  group('AppDatabase - Destructive Data Reset Tests (sqflite_common_ffi)', () {
    late AppDatabase appDatabase;
    late PreferencesRepository preferencesRepository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'doctorName': 'Dr. Shehab Shaif',
        'university': 'University of Sanaa',
        'academicYear': '5th Year',
        'hasCompletedOnboarding': true,
      });

      preferencesRepository = PreferencesRepository();
      appDatabase = AppDatabase.instance;
    });

    test('populates all 5 operational tables, resets, and asserts all counts are 0', () async {
      final db = await appDatabase.database;

      // 1. Populate Clinic
      final clinic = Clinic(
        id: 'clinic-test-prostho',
        name: 'Prosthodontics',
        academicYear: '5th Year',
        colorHex: '#003E6F',
      );
      await db.insert('clinics', clinic.toMap());

      // 2. Populate Requirement
      final requirement = Requirement(
        id: 'req-test-cd-1',
        clinicId: clinic.id,
        title: 'Complete Denture',
        targetCount: 5,
        completedCount: 1,
      );
      await db.insert('requirements', requirement.toMap());

      // 3. Populate Patient
      final patient = Patient(
        id: 'patient-test-1',
        name: 'Patient Test Zero',
        age: 35,
        gender: 'Female',
        phoneNumber: '123-456-7890',
        medicalHistory: 'Hypertension',
        createdAt: DateTime.now(),
      );
      await db.insert('patients', patient.toMap());

      // 4. Populate Case Record
      final caseRecord = CaseRecord(
        id: 'case-test-1',
        patientId: patient.id,
        requirementId: requirement.id,
        status: 'In Progress',
        notes: 'Preliminary impressions taken',
        dateStarted: DateTime.now(),
      );
      await db.insert('case_records', caseRecord.toMap());

      // 5. Populate Appointment
      final appointment = Appointment(
        id: 'apt-test-1',
        patientId: patient.id,
        clinicId: clinic.id,
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
        status: 'Scheduled',
        procedureDescription: 'Border molding',
      );
      await db.insert('appointments', appointment.toMap());

      // Verify that all tables have populated records
      final countAppointmentsBefore = (await db.rawQuery('SELECT COUNT(*) as count FROM appointments;')).first['count'] as int;
      final countCasesBefore = (await db.rawQuery('SELECT COUNT(*) as count FROM case_records;')).first['count'] as int;
      final countReqsBefore = (await db.rawQuery('SELECT COUNT(*) as count FROM requirements;')).first['count'] as int;
      final countClinicsBefore = (await db.rawQuery('SELECT COUNT(*) as count FROM clinics;')).first['count'] as int;
      final countPatientsBefore = (await db.rawQuery('SELECT COUNT(*) as count FROM patients;')).first['count'] as int;

      expect(countAppointmentsBefore, greaterThan(0));
      expect(countCasesBefore, greaterThan(0));
      expect(countReqsBefore, greaterThan(0));
      expect(countClinicsBefore, greaterThan(0));
      expect(countPatientsBefore, greaterThan(0));

      // Verify preferences are active
      expect(await preferencesRepository.getDoctorName(), equals('Dr. Shehab Shaif'));
      expect(await preferencesRepository.hasCompletedOnboarding(), isTrue);

      // 6. Execute Destructive Data Reset
      await appDatabase.resetAllData(preferencesRepository: preferencesRepository);

      // 7. Strictly assert that SELECT COUNT(*) on all operational tables is 0
      final countAppointmentsAfter = (await db.rawQuery('SELECT COUNT(*) as count FROM appointments;')).first['count'] as int;
      final countCasesAfter = (await db.rawQuery('SELECT COUNT(*) as count FROM case_records;')).first['count'] as int;
      final countReqsAfter = (await db.rawQuery('SELECT COUNT(*) as count FROM requirements;')).first['count'] as int;
      final countClinicsAfter = (await db.rawQuery('SELECT COUNT(*) as count FROM clinics;')).first['count'] as int;
      final countPatientsAfter = (await db.rawQuery('SELECT COUNT(*) as count FROM patients;')).first['count'] as int;

      expect(countAppointmentsAfter, equals(0), reason: 'appointments table must be empty');
      expect(countCasesAfter, equals(0), reason: 'case_records table must be empty');
      expect(countReqsAfter, equals(0), reason: 'requirements table must be empty');
      expect(countClinicsAfter, equals(0), reason: 'clinics table must be empty');
      expect(countPatientsAfter, equals(0), reason: 'patients table must be empty');

      // 8. Assert user preferences and onboarding state are cleared
      expect(await preferencesRepository.getDoctorName(), isNull);
      expect(await preferencesRepository.getUniversity(), isNull);
      expect(await preferencesRepository.getAcademicYear(), isNull);
      expect(await preferencesRepository.hasCompletedOnboarding(), isFalse);
    });
  });
}
