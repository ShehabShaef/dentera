import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/repositories/preferences_repository.dart';
import 'package:dentera/l10n/l10n.dart';
import 'package:dentera/presentation/screens/profile/widgets/edit_profile_modal.dart';
import 'package:dentera/presentation/widgets/inputs/inputs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'doctorName': 'Dr. Test Clinician',
      'doctorFirstName': 'Test',
      'doctorLastName': 'Clinician',
      'university': 'Test Dental College',
      'academicYear': '4th Year',
    });
  });

  group('EditProfileModal Widget Tests', () {
    testWidgets('Renders pre-populated credentials, Dr. prefix indicator, and split name fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => EditProfileModal.show(
                    context,
                    initialName: 'Dr. Test Clinician',
                    initialUniversity: 'Test Dental College',
                    initialAcademicYear: '4th Year',
                  ),
                  child: const Text('Edit'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Clinician Profile'), findsOneWidget);
      expect(find.text('Dr.'), findsOneWidget);
      expect(find.text('Prefix added automatically. Please enter your first and last name.'), findsOneWidget);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('University / Dental School'), findsOneWidget);
      expect(find.text('Academic Year'), findsOneWidget);

      // Verify fields exist: First Name, Last Name, University = 3 text fields
      expect(find.byType(DenteraTextField), findsNWidgets(3));
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Clinician'), findsOneWidget);
      expect(find.text('Test Dental College'), findsOneWidget);
      expect(find.text('4th Year'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Validates required name fields when emptied', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => EditProfileModal.show(context),
                  child: const Text('Edit'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Clear the first name field
      final firstNameField = find.widgetWithText(DenteraTextField, 'First Name');
      await tester.enterText(firstNameField, '');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('First name is required'), findsOneWidget);
    });

    testWidgets('Submitting valid changes strips accidental Dr. prefix, updates profile provider, and closes modal', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await EditProfileModal.show(context);
                  },
                  child: const Text('Edit'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Enter new first name (with accidental Dr. typed) and last name
      final firstField = find.widgetWithText(DenteraTextField, 'First Name');
      await tester.enterText(firstField, 'Dr. Sarah');

      final lastField = find.widgetWithText(DenteraTextField, 'Last Name');
      await tester.enterText(lastField, 'Connor');

      final uniField = find.widgetWithText(DenteraTextField, 'University / Dental School');
      await tester.enterText(uniField, 'Cyberdyne Dental Institute');

      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Modal should close and return true
      expect(result, isTrue);
      expect(find.text('Edit Clinician Profile'), findsNothing);

      // Verify persisted in preferences
      final repo = PreferencesRepository();
      expect(await repo.getDoctorFirstName(), 'Sarah');
      expect(await repo.getDoctorLastName(), 'Connor');
      expect(await repo.getDoctorName(), 'Dr. Sarah Connor');
    });

    testWidgets('Tapping Cancel closes modal without saving', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await EditProfileModal.show(context);
                  },
                  child: const Text('Edit'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Clinician Profile'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Clinician Profile'), findsNothing);
      expect(result, isFalse);
    });
  });
}
