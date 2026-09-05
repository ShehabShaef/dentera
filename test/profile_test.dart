import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/core/services/database_backup_service.dart';
import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/presentation/screens/profile/profile_screen.dart';
import 'package:dentera/presentation/screens/profile/widgets/widgets.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'doctorName': 'Dr. Shehab Shaif',
      'academicYear': '5th Year',
      'university': "University of Sana'a",
      'hasCompletedOnboarding': true,
    });
  });

  group('Profile & Settings Screen Widget Tests', () {
    testWidgets('ProfileHeaderCard renders doctor profile info and initial', (WidgetTester tester) async {
      bool editTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ProfileHeaderCard(
              name: 'Dr. Shehab Shaif',
              subtitle: '5th Year Clinical Student',
              onEdit: () => editTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Dr. Shehab Shaif'), findsOneWidget);
      expect(find.text('5th Year Clinical Student'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      expect(editTapped, isTrue);
    });

    testWidgets('SettingsListTile renders title, subtitle, and handles onTap', (WidgetTester tester) async {
      bool tileTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SettingsListTile(
              icon: Icons.download_rounded,
              title: 'Export Local Backup',
              subtitle: 'Save an encrypted SQLite copy to your device',
              onTap: () => tileTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Export Local Backup'), findsOneWidget);
      expect(find.text('Save an encrypted SQLite copy to your device'), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);

      await tester.tap(find.text('Export Local Backup'));
      expect(tileTapped, isTrue);
    });

    testWidgets('ProfileScreen renders all sections and switches', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Dr. Shehab Shaif'), findsOneWidget);
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('App Theme'), findsOneWidget);
      expect(find.text('LOCAL NOTIFICATIONS'), findsOneWidget);
      expect(find.text('Next-Day Agenda Reminders'), findsOneWidget);
      expect(find.text('DATA & OFFLINE BACKUP'), findsOneWidget);
      expect(find.text('Export Local Backup'), findsOneWidget);
      expect(find.text('Restore from Backup'), findsOneWidget);
      expect(find.text('Reset All Clinical Data'), findsOneWidget);

      // Toggle switch
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));
      await tester.tap(switches.first);
      await tester.pumpAndSettle();
    });

    testWidgets('Tapping Export Local Backup executes service and shows SnackBar', (WidgetTester tester) async {
      final fakeService = FakeDatabaseBackupService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseBackupServiceProvider.overrideWithValue(fakeService),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final exportTile = find.text('Export Local Backup');
      await tester.ensureVisible(exportTile);
      await tester.tap(exportTile);
      await tester.pumpAndSettle();

      expect(fakeService.exportCalled, isTrue);
      expect(find.text('Database backup created successfully.'), findsOneWidget);
    });

    testWidgets('Tapping Restore from Backup shows confirmation dialog and restores upon confirm', (WidgetTester tester) async {
      final fakeService = FakeDatabaseBackupService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseBackupServiceProvider.overrideWithValue(fakeService),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap restore tile
      final restoreTile = find.text('Restore from Backup');
      await tester.ensureVisible(restoreTile);
      await tester.tap(restoreTile);
      await tester.pumpAndSettle();

      // Dialog should be present
      expect(find.text('Restore Database Backup?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);

      // Tap Cancel first
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(fakeService.importCalled, isFalse);
      expect(find.text('Restore Database Backup?'), findsNothing);

      // Tap restore tile again
      await tester.ensureVisible(restoreTile);
      await tester.tap(restoreTile);
      await tester.pumpAndSettle();

      // Tap Restore button
      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();

      expect(fakeService.importCalled, isTrue);
      expect(find.text('Database restored successfully. Clinical records reloaded.'), findsOneWidget);
    });
  });
}

class FakeDatabaseBackupService extends DatabaseBackupService {
  FakeDatabaseBackupService({
    this.exportResult,
    this.restoreResult,
  });

  final BackupResult? exportResult;
  final RestoreResult? restoreResult;

  bool exportCalled = false;
  bool importCalled = false;

  @override
  Future<BackupResult> exportDatabase({
    String? destinationDirectoryPath,
    bool shareViaSystemDialog = true,
  }) async {
    exportCalled = true;
    return exportResult ?? BackupResult.success('/mock/export.db');
  }

  @override
  Future<RestoreResult> importDatabase({String? customSourcePath}) async {
    importCalled = true;
    return restoreResult ?? RestoreResult.success('/mock/dentera.db');
  }
}

