import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/repositories/preferences_repository.dart';
import 'package:dentera/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:dentera/presentation/screens/root_navigation_screen.dart';
import 'package:dentera/presentation/widgets/widgets.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PreferencesRepository Unit Tests', () {
    test('saveUserProfile and retrieve values', () async {
      final repo = PreferencesRepository();

      expect(await repo.hasCompletedOnboarding(), isFalse);

      await repo.saveUserProfile(
        name: 'Dr. John Watson',
        university: 'London Dental School',
        academicYear: '5th Year',
      );

      expect(await repo.hasCompletedOnboarding(), isTrue);
      expect(await repo.getDoctorName(), 'Dr. John Watson');
      expect(await repo.getUniversity(), 'London Dental School');
      expect(await repo.getAcademicYear(), '5th Year');

      await repo.clearAll();
      expect(await repo.hasCompletedOnboarding(), isFalse);
    });
  });

  group('Onboarding Flow Widget Tests', () {
    testWidgets('Full 3-step onboarding flow navigation and submission', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const OnboardingScreen(),
          ),
        ),
      );

      // Step 1: Welcome
      expect(find.text('Welcome, Doctor.'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);

      // Fill in Name
      await tester.enterText(find.byType(DenteraTextField), 'Dr. Alexander Fleming');
      await tester.pumpAndSettle();

      // Tap Continue to Step 2
      await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));
      await tester.pumpAndSettle();

      // Step 2: Institution
      expect(find.text('Your Institution'), findsOneWidget);
      expect(find.text('University / School'), findsOneWidget);

      // Fill in University
      await tester.enterText(find.byType(DenteraTextField), "St Mary's Hospital Medical School");
      await tester.pumpAndSettle();

      // Tap Continue to Step 3
      await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));
      await tester.pumpAndSettle();

      // Step 3: Clinical Year
      expect(find.text('Clinical Year'), findsOneWidget);
      expect(find.text('3rd Year'), findsOneWidget);
      expect(find.text('4th Year'), findsOneWidget);
      expect(find.text('5th Year'), findsOneWidget);
      expect(find.text('Internship'), findsOneWidget);

      // Select 5th Year
      await tester.tap(find.text('5th Year'));
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.widgetWithText(PrimaryButton, 'Enter Workspace'));
      await tester.pumpAndSettle();

      // Verify transitioned to RootNavigationScreen
      expect(find.byType(RootNavigationScreen), findsOneWidget);

      // Verify SharedPreferences persisted values
      final repo = PreferencesRepository();
      expect(await repo.hasCompletedOnboarding(), isTrue);
      expect(await repo.getDoctorName(), 'Dr. Alexander Fleming');
      expect(await repo.getUniversity(), "St Mary's Hospital Medical School");
      expect(await repo.getAcademicYear(), '5th Year');
    });
  });
}
