import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/database/database_providers.dart';
import 'package:dentera/data/repositories/preferences_repository.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/l10n/l10n.dart';
import 'package:dentera/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:dentera/presentation/screens/onboarding/welcome_page.dart';
import 'package:dentera/presentation/screens/root_navigation_screen.dart';
import 'package:dentera/presentation/state/state.dart';
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
      expect(await repo.getDoctorFirstName(), 'John');
      expect(await repo.getDoctorLastName(), 'Watson');
      expect(await repo.getDoctorName(), 'Dr. John Watson');
      expect(await repo.getUniversity(), 'London Dental School');
      expect(await repo.getAcademicYear(), '5th Year');

      await repo.clearAll();
      expect(await repo.hasCompletedOnboarding(), isFalse);
    });

    test('saveUserProfile for guest user initializes default values', () async {
      final repo = PreferencesRepository();
      await repo.saveUserProfile(
        firstName: 'Guest',
        lastName: '',
        university: 'Guest Dental University',
        academicYear: '5th Year',
        isGuest: true,
      );

      expect(await repo.hasCompletedOnboarding(), isTrue);
      expect(await repo.getDoctorName(), 'Dr. Guest');
      expect(await repo.getUniversity(), 'Guest Dental University');
      expect(await repo.getAcademicYear(), '5th Year');
      expect(await repo.isGuest(), isTrue);
    });
  });

  group('Onboarding Flow Widget Tests', () {
    testWidgets('Welcome page enforces non-empty first and last name validation', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyAppointmentsProvider.overrideWith((ref, date) => <Appointment>[]),
            upcomingAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
            patientListProvider.overrideWith((ref) => <Patient>[]),
            allCasesProvider.overrideWith((ref) => <CaseRecord>[]),
            allRequirementsProvider.overrideWith((ref) => <Requirement>[]),
            clinicListProvider.overrideWith((ref) => <Clinic>[]),
            onboardingSeederProvider.overrideWithValue(({required isGuest, required academicYear}) async {}),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const OnboardingScreen(),
          ),
        ),
      );

      // Verify Step 1 is displayed with Dr. badge and separate First/Last Name inputs
      expect(find.text('Welcome, Doctor.'), findsOneWidget);
      expect(find.text('Dr.'), findsOneWidget);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('First name is required'), findsNothing);

      // Attempt to continue with blank fields
      await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));
      await tester.pumpAndSettle();

      // Verify validation error is shown and page has NOT advanced
      expect(find.text('First name is required'), findsOneWidget);
      expect(find.text('Your Institution'), findsNothing);

      // Enter only whitespace
      final firstField = find.widgetWithText(DenteraTextField, 'First Name');
      final lastField = find.widgetWithText(DenteraTextField, 'Last Name');

      await tester.enterText(firstField, '   ');
      await tester.enterText(lastField, '   ');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));
      await tester.pumpAndSettle();

      // Verify validation error remains and still on Step 1
      expect(find.text('First name is required'), findsOneWidget);
      expect(find.text('Your Institution'), findsNothing);

      // Enter valid name (with accidental Dr. typed which will be stripped)
      await tester.enterText(firstField, 'Dr. Stephen');
      await tester.enterText(lastField, 'Strange');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));
      await tester.pumpAndSettle();

      // Now successfully advanced to Step 2
      expect(find.text('First name is required'), findsNothing);
      expect(find.text('Your Institution'), findsOneWidget);
    });

    testWidgets('Continue as a guest sets default guest preferences and transitions immediately', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyAppointmentsProvider.overrideWith((ref, date) => <Appointment>[]),
            upcomingAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
            patientListProvider.overrideWith((ref) => <Patient>[]),
            allCasesProvider.overrideWith((ref) => <CaseRecord>[]),
            allRequirementsProvider.overrideWith((ref) => <Requirement>[]),
            clinicListProvider.overrideWith((ref) => <Clinic>[]),
            onboardingSeederProvider.overrideWithValue(({required isGuest, required academicYear}) async {}),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const OnboardingScreen(),
          ),
        ),
      );

      // Verify "Continue as a guest" button is visible on Step 1
      final guestButtonFinder = find.widgetWithText(TextButton, 'Continue as a guest');
      expect(guestButtonFinder, findsOneWidget);

      // Tap "Continue as a guest"
      await tester.tap(guestButtonFinder);
      await tester.pumpAndSettle();

      // Verify immediately transitioned to RootNavigationScreen
      expect(find.byType(RootNavigationScreen), findsOneWidget);

      // Verify SharedPreferences persisted values match exact requirements
      final repo = PreferencesRepository();
      expect(await repo.hasCompletedOnboarding(), isTrue);
      expect(await repo.getDoctorName(), 'Dr. Guest');
      expect(await repo.getUniversity(), 'Guest Dental University');
      expect(await repo.getAcademicYear(), '5th Year');
      expect(await repo.isGuest(), isTrue);
    });

    testWidgets('Full 3-step onboarding flow navigation and submission with First and Last Name', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyAppointmentsProvider.overrideWith((ref, date) => <Appointment>[]),
            upcomingAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
            patientListProvider.overrideWith((ref) => <Patient>[]),
            allCasesProvider.overrideWith((ref) => <CaseRecord>[]),
            allRequirementsProvider.overrideWith((ref) => <Requirement>[]),
            clinicListProvider.overrideWith((ref) => <Clinic>[]),
            onboardingSeederProvider.overrideWithValue(({required isGuest, required academicYear}) async {}),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const OnboardingScreen(),
          ),
        ),
      );

      // Step 1: Welcome
      expect(find.text('Welcome, Doctor.'), findsOneWidget);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);

      // Fill in First Name (with accidental Dr. typed) and Last Name
      final firstField = find.widgetWithText(DenteraTextField, 'First Name');
      final lastField = find.widgetWithText(DenteraTextField, 'Last Name');

      await tester.enterText(firstField, 'Dr. Alexander');
      await tester.enterText(lastField, 'Fleming');
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
      expect(await repo.getDoctorFirstName(), 'Alexander');
      expect(await repo.getDoctorLastName(), 'Fleming');
      expect(await repo.getDoctorName(), 'Dr. Alexander Fleming');
      expect(await repo.getUniversity(), "St Mary's Hospital Medical School");
      expect(await repo.getAcademicYear(), '5th Year');
    });
  });

  group('WelcomePage Component Tests', () {
    testWidgets('triggers validator and does not call onContinue when empty', (WidgetTester tester) async {
      bool continueCalled = false;
      bool guestCalled = false;
      final firstController = TextEditingController();
      final lastController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: WelcomePage(
              firstNameController: firstController,
              lastNameController: lastController,
              onContinue: () => continueCalled = true,
              onContinueAsGuest: () => guestCalled = true,
            ),
          ),
        ),
      );

      // Tap Continue with empty input
      await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(continueCalled, isFalse);
      expect(find.text('First name is required'), findsOneWidget);

      // Tap Continue as a guest
      await tester.tap(find.widgetWithText(TextButton, 'Continue as a guest'));
      await tester.pumpAndSettle();

      expect(guestCalled, isTrue);

      // Enter first and last name and tap Continue
      await tester.enterText(find.widgetWithText(DenteraTextField, 'First Name'), 'Sarah');
      await tester.enterText(find.widgetWithText(DenteraTextField, 'Last Name'), 'Connor');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(continueCalled, isTrue);
    });
  });
}
