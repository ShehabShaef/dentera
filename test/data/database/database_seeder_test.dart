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
              FOREIGN KEY (clinicId) REFERENCES clinics (id) ON DELETE CASCADE
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
      expect(reqsResult.length, equals(12));

      // 3. Verify foreign key relationship via relational JOIN
      final joinResult = await db.rawQuery('''
        SELECT r.id AS reqId, r.title AS reqTitle, c.name AS clinicName
        FROM requirements r
        JOIN clinics c ON r.clinicId = c.id
      ''');
      expect(joinResult.length, equals(12));

      // 4. Verify specific baseline clinical quotas
      final prosthReqs = await db.query(
        'requirements',
        where: 'clinicId = ?',
        whereArgs: ['clinic-prosth'],
      );
      expect(prosthReqs.length, equals(2));
      final cdReq = prosthReqs.firstWhere((r) => r['title'] == 'Complete Denture');
      expect(cdReq['targetCount'], equals(2));
      expect(cdReq['completedCount'], equals(0));

      final opReqs = await db.query(
        'requirements',
        where: 'clinicId = ?',
        whereArgs: ['clinic-operative'],
      );
      expect(opReqs.length, equals(2));
      final amalgamReq = opReqs.firstWhere((r) => r['title'] == 'Class II Amalgam');
      expect(amalgamReq['targetCount'], equals(4));
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
      expect(secondReqsCount, equals(12));
    });
  });
}
