import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  });
}
