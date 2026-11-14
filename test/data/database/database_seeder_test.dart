import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dentera/data/database/database_seeder.dart';

import '../../setup/test_setup.dart';

void main() {
  setUpAll(() {
    setupDatabaseTests();
  });

  late Database db;

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
              notes TEXT,
              FOREIGN KEY (clinicId) REFERENCES clinics (id) ON DELETE CASCADE
            );
          ''');
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
          await batch.commit();
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('DatabaseSeeder Automated Tests', () {
    test('seeds exact default academic clinics and baseline requirements', () async {
      // Execute seeder
      await DatabaseSeeder.seedInitialData(db);

      // 1. Verify clinics count and contents
      final clinicsResult = await db.query('clinics');
      expect(clinicsResult.length, equals(6));

      final clinicNames = clinicsResult.map((row) => row['name'] as String).toList();
      expect(
        clinicNames,
        containsAll([
          'Prosthodontics',
          'Operative Dentistry',
          'Endodontics',
          'Oral Surgery',
          'Periodontics',
          'Pediatric Dentistry',
        ]),
      );

      // Verify each clinic has non-empty colorHex and academicYear
      for (final clinic in clinicsResult) {
        expect(clinic['colorHex'], isNotNull);
        expect((clinic['colorHex'] as String).startsWith('#'), isTrue);
        expect(clinic['academicYear'], equals('5th Year'));
      }

      // 2. Verify requirements count
      final reqsResult = await db.query('requirements');
      expect(reqsResult.length, equals(DatabaseSeeder.defaultRequirements.length));
      expect(reqsResult.length, equals(16));

      // 3. Verify foreign key relationship via relational JOIN
      final joinResult = await db.rawQuery('''
        SELECT r.id AS reqId, r.title AS reqTitle, c.name AS clinicName
        FROM requirements r
        JOIN clinics c ON r.clinicId = c.id
      ''');
      expect(joinResult.length, equals(16));

      // 4. Verify specific baseline clinical quotas
      // Prosthodontics (3 requirements)
      final prosthReqs = await db.query(
        'requirements',
        where: 'clinicId = ?',
        whereArgs: ['clinic-prosth'],
      );
      expect(prosthReqs.length, equals(3));
      final cdReq = prosthReqs.firstWhere((r) => r['title'] == 'Complete Denture');
      expect(cdReq['targetCount'], equals(2));
      expect(cdReq['completedCount'], equals(0));
      final spdReq = prosthReqs.firstWhere((r) => r['title'] == 'Single Partial Denture');
      expect(spdReq['targetCount'], equals(2));

      // Operative Dentistry (3 requirements)
      final opReqs = await db.query(
        'requirements',
        where: 'clinicId = ?',
        whereArgs: ['clinic-operative'],
      );
      expect(opReqs.length, equals(3));
      final amalgamReq = opReqs.firstWhere((r) => r['title'] == 'Class II Amalgam');
      expect(amalgamReq['targetCount'], equals(4));
      final class1AmalgamReq = opReqs.firstWhere((r) => r['title'] == 'Class I Amalgam');
      expect(class1AmalgamReq['targetCount'], equals(6));

      // Periodontics (2 requirements: Scaling and Polishing, Gingivectomy)
      final perioReqs = await db.query(
        'requirements',
        where: 'clinicId = ?',
        whereArgs: ['clinic-perio'],
      );
      expect(perioReqs.length, equals(2));
      expect(perioReqs.any((r) => r['title'] == 'Scaling and Polishing'), isTrue);
      expect(perioReqs.any((r) => r['title'] == 'Gingivectomy'), isTrue);

      // Pediatric Dentistry (4 requirements)
      final pedsReqs = await db.query(
        'requirements',
        where: 'clinicId = ?',
        whereArgs: ['clinic-pediatric'],
      );
      expect(pedsReqs.length, equals(4));
      expect(pedsReqs.any((r) => r['title'] == 'Primary Pulpotomy'), isTrue);
      expect(pedsReqs.any((r) => r['title'] == 'Primary Pulpectomy'), isTrue);
      expect(pedsReqs.any((r) => r['title'] == 'Stainless Steel Crown'), isTrue);
      expect(pedsReqs.any((r) => r['title'] == 'Composite Restoration'), isTrue);
    });

    test('seeding is idempotent when executed multiple times (ConflictAlgorithm.replace)', () async {
      // Run seeder first time
      await DatabaseSeeder.seedInitialData(db);
      final firstClinicsCount =
          (await db.rawQuery('SELECT COUNT(*) as count FROM clinics;')).first['count'] as int;
      final firstReqsCount =
          (await db.rawQuery('SELECT COUNT(*) as count FROM requirements;')).first['count'] as int;

      // Run seeder second time
      await DatabaseSeeder.seedInitialData(db);
      final secondClinicsCount =
          (await db.rawQuery('SELECT COUNT(*) as count FROM clinics;')).first['count'] as int;
      final secondReqsCount =
          (await db.rawQuery('SELECT COUNT(*) as count FROM requirements;')).first['count'] as int;

      expect(secondClinicsCount, equals(firstClinicsCount));
      expect(secondReqsCount, equals(firstReqsCount));
      expect(secondClinicsCount, equals(6));
      expect(secondReqsCount, equals(16));
    });

    group('syncCurriculumRequirements Migration Tests', () {
      test('renames legacy procedure titles in-place preserving progress and foreign keys', () async {
        // Setup initial clinic
        await db.insert('clinics', {
          'id': 'clinic-perio-legacy',
          'name': 'Periodontics',
          'academicYear': '4th Year',
          'colorHex': '#10B981',
        });

        // Insert requirement with legacy title
        await db.insert('requirements', {
          'id': 'req-perio-legacy',
          'clinicId': 'clinic-perio-legacy',
          'title': 'Scaling & Root Planing',
          'targetCount': 10,
          'completedCount': 4,
        });

        // Run curriculum sync
        await DatabaseSeeder.syncCurriculumRequirements(db);

        // Verify title renamed in-place and completedCount/id preserved
        final updated = await db.query(
          'requirements',
          where: 'id = ?',
          whereArgs: ['req-perio-legacy'],
        );
        expect(updated.length, equals(1));
        expect(updated.first['title'], equals('Scaling and Polishing'));
        expect(updated.first['completedCount'], equals(4));
        expect(updated.first['targetCount'], equals(10));
      });

      test('removes unused retired requirements when 0 case records exist', () async {
        await db.insert('clinics', {
          'id': 'clinic-prosth-rem',
          'name': 'Removable Prosthodontics',
          'academicYear': '5th Year',
          'colorHex': '#3B82F6',
        });

        // Insert retired requirement with no cases
        await db.insert('requirements', {
          'id': 'req-retired-rpi',
          'clinicId': 'clinic-prosth-rem',
          'title': 'RPI Clasp Assembly',
          'targetCount': 2,
          'completedCount': 0,
        });

        await DatabaseSeeder.syncCurriculumRequirements(db);

        final result = await db.query(
          'requirements',
          where: 'id = ?',
          whereArgs: ['req-retired-rpi'],
        );
        expect(result, isEmpty);
      });

      test('preserves retired requirements if student has logged case records against them', () async {
        await db.insert('clinics', {
          'id': 'clinic-perio-test',
          'name': 'Periodontics',
          'academicYear': '5th Year',
          'colorHex': '#10B981',
        });

        await db.insert('requirements', {
          'id': 'req-flap-logged',
          'clinicId': 'clinic-perio-test',
          'title': 'Periodontal Flap Surgery',
          'targetCount': 2,
          'completedCount': 1,
        });

        await db.insert('patients', {
          'id': 'pat-1',
          'name': 'John Doe',
          'age': 30,
          'gender': 'Male',
          'createdAt': DateTime.now().toIso8601String(),
        });

        // Log a case record against the retired requirement
        await db.insert('case_records', {
          'id': 'case-1',
          'patientId': 'pat-1',
          'requirementId': 'req-flap-logged',
          'status': 'Completed',
          'dateStarted': DateTime.now().toIso8601String(),
        });

        await DatabaseSeeder.syncCurriculumRequirements(db);

        // Verify the retired requirement was NOT deleted because of logged case
        final result = await db.query(
          'requirements',
          where: 'id = ?',
          whereArgs: ['req-flap-logged'],
        );
        expect(result.length, equals(1));
        expect(result.first['title'], equals('Periodontal Flap Surgery'));
      });

      test('removes Space Maintainer from Orthodontics while strictly keeping Pedodontics Space Maintainer', () async {
        await db.insert('clinics', {
          'id': 'c-ortho',
          'name': 'Orthodontics',
          'academicYear': '5th Year',
          'colorHex': '#8B5CF6',
        });
        await db.insert('clinics', {
          'id': 'c-peds',
          'name': 'Pediatric Dentistry',
          'academicYear': '5th Year',
          'colorHex': '#F59E0B',
        });

        await db.insert('requirements', {
          'id': 'req-ortho-sm',
          'clinicId': 'c-ortho',
          'title': 'Space Maintainer',
          'targetCount': 2,
          'completedCount': 0,
        });
        await db.insert('requirements', {
          'id': 'req-peds-sm',
          'clinicId': 'c-peds',
          'title': 'Space Maintainer',
          'targetCount': 3,
          'completedCount': 0,
        });

        await DatabaseSeeder.syncCurriculumRequirements(db);

        // Ortho Space Maintainer should be removed
        final orthoCheck = await db.query(
          'requirements',
          where: 'id = ?',
          whereArgs: ['req-ortho-sm'],
        );
        expect(orthoCheck, isEmpty);

        // Pedodontics Space Maintainer MUST be preserved
        final pedsCheck = await db.query(
          'requirements',
          where: 'id = ?',
          whereArgs: ['req-peds-sm'],
        );
        expect(pedsCheck.length, equals(1));
        expect(pedsCheck.first['title'], equals('Space Maintainer'));
      });

      test('adds newly introduced requirements for standard clinics', () async {
        await db.insert('clinics', {
          'id': 'c-ortho-new',
          'name': 'Orthodontics',
          'academicYear': '5th Year',
          'colorHex': '#8B5CF6',
        });
        await db.insert('clinics', {
          'id': 'c-op-new',
          'name': 'Operative Dentistry',
          'academicYear': '4th Year',
          'colorHex': '#3B82F6',
        });

        await DatabaseSeeder.syncCurriculumRequirements(db);

        // Orthodontics new procedures
        final orthoReqs = await db.query(
          'requirements',
          where: 'clinicId = ?',
          whereArgs: ['c-ortho-new'],
        );
        final orthoTitles = orthoReqs.map((r) => r['title'] as String).toList();
        expect(orthoTitles, containsAll([
          'Removable Appliance',
          'Habit Breaker',
          'Fixed Appliance',
          'Myofunctional Appliance (Functional)',
        ]));

        // Operative new procedures
        final opReqs = await db.query(
          'requirements',
          where: 'clinicId = ?',
          whereArgs: ['c-op-new'],
        );
        final opTitles = opReqs.map((r) => r['title'] as String).toList();
        expect(opTitles, contains('Class I Amalgam'));
      });
    });
  });
}
