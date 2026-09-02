import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dentera/data/database/app_database.dart';
import 'package:dentera/data/models/models.dart';
import 'package:dentera/data/repositories/repositories.dart';

void main() {
  // Initialize sqflite ffi for desktop/test runner execution
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late AppDatabase appDatabase;
  late SqlitePatientRepository patientRepo;
  late SqliteClinicRepository clinicRepo;
  late SqliteRequirementRepository requirementRepo;
  late SqliteCaseRecordRepository caseRecordRepo;
  late SqliteAppointmentRepository appointmentRepo;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
          final batch = db.batch();
          batch.execute('''
            CREATE TABLE patients (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              age INTEGER NOT NULL,
              gender TEXT NOT NULL,
              phoneNumber TEXT,
              medicalHistory TEXT,
              createdAt TEXT NOT NULL
            );
          ''');
          batch.execute('''
            CREATE TABLE clinics (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              academicYear TEXT NOT NULL,
              colorHex TEXT NOT NULL
            );
          ''');
          batch.execute('''
            CREATE TABLE requirements (
              id TEXT PRIMARY KEY,
              clinicId TEXT NOT NULL,
              title TEXT NOT NULL,
              targetCount INTEGER NOT NULL,
              completedCount INTEGER NOT NULL DEFAULT 0,
              FOREIGN KEY (clinicId) REFERENCES clinics (id) ON DELETE CASCADE
            );
          ''');
          batch.execute('''
            CREATE TABLE case_records (
              id TEXT PRIMARY KEY,
              patientId TEXT NOT NULL,
              requirementId TEXT NOT NULL,
              status TEXT NOT NULL,
              notes TEXT,
              dateStarted TEXT NOT NULL,
              dateCompleted TEXT,
              FOREIGN KEY (patientId) REFERENCES patients (id) ON DELETE CASCADE,
              FOREIGN KEY (requirementId) REFERENCES requirements (id) ON DELETE CASCADE
            );
          ''');
          batch.execute('''
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
          await batch.commit();
        },
      ),
    );

    appDatabase = AppDatabase.withDatabase(db);
    patientRepo = SqlitePatientRepository(appDatabase);
    clinicRepo = SqliteClinicRepository(appDatabase);
    requirementRepo = SqliteRequirementRepository(appDatabase);
    caseRecordRepo = SqliteCaseRecordRepository(appDatabase);
    appointmentRepo = SqliteAppointmentRepository(appDatabase);
  });

  tearDown(() async {
    await db.close();
  });

  group('SQLite Repositories CRUD Integration', () {
    test('Patient CRUD operations', () async {
      final patient = Patient(
        id: 'p-1',
        name: 'Jane Doe',
        age: 24,
        gender: 'Female',
        phoneNumber: '555-0199',
        medicalHistory: 'None',
        createdAt: DateTime.parse('2026-09-01T10:00:00.000Z'),
      );

      // Add
      await patientRepo.addPatient(patient);
      final fetched = await patientRepo.getPatientById('p-1');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Jane Doe');

      // Update
      final updated = patient.copyWith(name: 'Jane Smith');
      await patientRepo.updatePatient(updated);
      final fetchedUpdated = await patientRepo.getPatientById('p-1');
      expect(fetchedUpdated!.name, 'Jane Smith');

      // Get All
      final all = await patientRepo.getAllPatients();
      expect(all.length, 1);

      // Delete
      await patientRepo.deletePatient('p-1');
      final afterDelete = await patientRepo.getPatientById('p-1');
      expect(afterDelete, isNull);
    });

    test('Clinic and Requirement operations with Foreign Key cascades', () async {
      const clinic = Clinic(
        id: 'c-1',
        name: 'Prosthodontics',
        academicYear: 'Year 4',
        colorHex: '#003E6F',
      );
      await clinicRepo.addClinic(clinic);

      const requirement = Requirement(
        id: 'r-1',
        clinicId: 'c-1',
        title: 'Complete Denture',
        targetCount: 5,
        completedCount: 1,
      );
      await requirementRepo.addRequirement(requirement);

      final reqs = await requirementRepo.getRequirementsByClinicId('c-1');
      expect(reqs.length, 1);
      expect(reqs.first.title, 'Complete Denture');

      // Update progress
      await requirementRepo.updateRequirementProgress('r-1', 2);
      final reqsUpdated = await requirementRepo.getRequirementsByClinicId('c-1');
      expect(reqsUpdated.first.completedCount, 2);
    });

    test('CaseRecord and Appointment operations', () async {
      // Seed parent records
      final patient = Patient(
        id: 'p-2',
        name: 'John Miller',
        age: 45,
        gender: 'Male',
        createdAt: DateTime.parse('2026-09-01T10:00:00.000Z'),
      );
      await patientRepo.addPatient(patient);

      const clinic = Clinic(
        id: 'c-2',
        name: 'Endodontics',
        academicYear: 'Year 4',
        colorHex: '#006A64',
      );
      await clinicRepo.addClinic(clinic);

      const requirement = Requirement(
        id: 'r-2',
        clinicId: 'c-2',
        title: 'Molar RCT',
        targetCount: 3,
        completedCount: 0,
      );
      await requirementRepo.addRequirement(requirement);

      // Case record
      final caseRecord = CaseRecord(
        id: 'case-10',
        patientId: 'p-2',
        requirementId: 'r-2',
        status: 'In Progress',
        notes: 'Access cavity prepared.',
        dateStarted: DateTime.parse('2026-09-01T11:00:00.000Z'),
      );
      await caseRecordRepo.addCaseRecord(caseRecord);

      final patientCases = await caseRecordRepo.getCaseRecordsByPatientId('p-2');
      expect(patientCases.length, 1);
      expect(patientCases.first.notes, 'Access cavity prepared.');

      // Appointment
      final appointment = Appointment(
        id: 'apt-10',
        patientId: 'p-2',
        clinicId: 'c-2',
        scheduledDate: DateTime.parse('2026-09-02T09:30:00.000Z'),
        status: 'Scheduled',
        procedureDescription: 'Root canal obturation',
      );
      await appointmentRepo.addAppointment(appointment);

      final dateAppts = await appointmentRepo.getAppointmentsByDate(DateTime.parse('2026-09-02'));
      expect(dateAppts.length, 1);
      expect(dateAppts.first.procedureDescription, 'Root canal obturation');
    });
  });
}
