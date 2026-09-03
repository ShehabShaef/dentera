import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/data/database/app_database.dart';

import '../../setup/test_setup.dart';

void main() {
  setUpAll(() {
    setupDatabaseTests();
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  group('AppDatabase FFI Baseline Integration', () {
    test('opens singleton database instance and initializes relational schema', () async {
      final appDatabase = AppDatabase.instance;
      final db = await appDatabase.database;

      // Verify the SQLite database is open
      expect(db.isOpen, isTrue);

      // Verify PRAGMA foreign_keys is enabled
      final foreignKeysPragma = await db.rawQuery('PRAGMA foreign_keys;');
      expect(foreignKeysPragma.first.values.first, equals(1));

      // Query sqlite_master to verify that all core tables were created
      final tablesResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
      );
      final tableNames = tablesResult.map((row) => row['name'] as String).toSet();

      expect(
        tableNames,
        containsAll([
          'patients',
          'clinics',
          'requirements',
          'case_records',
          'appointments',
        ]),
      );
    });
  });
}
