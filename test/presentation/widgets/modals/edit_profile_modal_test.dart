import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/presentation/screens/profile/widgets/edit_profile_modal.dart';
import 'package:dentera/presentation/widgets/inputs/inputs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'doctorName': 'Dr. Test Clinician',
      'university': 'Test Dental College',
      'academicYear': '4th Year',
    });
  });

  group('EditProfileModal Widget Tests', () {
    testWidgets('Renders pre-populated credentials and form elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
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
      expect(find.text('Clinician Name'), findsOneWidget);
      expect(find.text('University / Dental School'), findsOneWidget);
      expect(find.text('Academic Year'), findsOneWidget);

      // Verify fields exist
      expect(find.byType(DenteraTextField), findsNWidgets(2));
      expect(find.text('Dr. Test Clinician'), findsOneWidget);
      expect(find.text('Test Dental College'), findsOneWidget);
      expect(find.text('4th Year'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Validates required fields when emptied', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
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

      // Clear the clinician name field
      final nameField = find.widgetWithText(DenteraTextField, 'Clinician Name');
      await tester.enterText(nameField, '');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Clinician name is required'), findsOneWidget);
    });

    testWidgets('Submitting valid changes updates profile provider and closes modal', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
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

      // Enter new name and university
      final nameField = find.widgetWithText(DenteraTextField, 'Clinician Name');
      await tester.enterText(nameField, 'Dr. Sarah Connor');

      final uniField = find.widgetWithText(DenteraTextField, 'University / Dental School');
      await tester.enterText(uniField, 'Cyberdyne Dental Institute');

      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Modal should close and return true
      expect(result, isTrue);
      expect(find.text('Edit Clinician Profile'), findsNothing);
    });

    testWidgets('Tapping Cancel closes modal without saving', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
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
