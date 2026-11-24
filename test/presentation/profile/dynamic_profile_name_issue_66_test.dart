import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/core/services/report_generator_service.dart';
import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/repositories/preferences_repository.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/l10n/l10n.dart';
import 'package:dentera/presentation/screens/dashboard/widgets/dashboard_header.dart';
import 'package:dentera/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:dentera/presentation/screens/profile/profile_screen.dart';
import 'package:dentera/presentation/screens/profile/widgets/edit_profile_modal.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Issue #66: Dynamic Real User Name Propagation Tests', () {
    testWidgets('Real user onboarding propagates dynamic name to ProfileScreen without hardcoded fallback', (WidgetTester tester) async {
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
      await tester.pumpAndSettle();

      // Step 1: Enter custom doctor name "Dr. Alexander Fleming"
      final firstField = find.widgetWithText(DenteraTextField, 'First Name');
      final lastField = find.widgetWithText(DenteraTextField, 'Last Name');
      await tester.enterText(firstField, 'Alexander');
      await tester.enterText(lastField, 'Fleming');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));
      await tester.pumpAndSettle();

      // Step 2: Enter institution
      final uniField = find.widgetWithText(DenteraTextField, 'University / School');
      await tester.enterText(uniField, "St Mary's Hospital Medical School");
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));
      await tester.pumpAndSettle();

      // Step 3: Select year and submit
      await tester.tap(find.text('5th Year'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(PrimaryButton, 'Enter Workspace'));
      await tester.pumpAndSettle();

      // Switch to Profile tab
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();

      // Verify ProfileScreen displays dynamic clinician name and university
      expect(find.text('Dr. Alexander Fleming'), findsOneWidget);
      expect(find.text('Shehab Shaif'), findsNothing);
      expect(find.text('Dr. Shehab Shaif'), findsNothing);
      expect(find.textContaining('St Mary\'s Hospital Medical School'), findsWidgets);
    });

    testWidgets('DashboardHeader formats real user in English and Arabic cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const Scaffold(
              body: DashboardHeader(
                doctorName: 'Dr. Alexander Fleming',
                academicYear: '5th Year',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Dr. Alexander Fleming'), findsOneWidget);
      expect(find.textContaining('Shehab'), findsNothing);

      // Now pump Arabic
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ar'),
            home: const Scaffold(
              body: DashboardHeader(
                doctorName: 'Dr. Alexander Fleming',
                academicYear: '5th Year',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('د. Alexander Fleming'), findsOneWidget);
      expect(find.textContaining('شهاب'), findsNothing);
    });
  });

  group('Issue #66: Guest Mode Name Propagation & Profile Resolution Tests', () {
    testWidgets('Guest entry sets Dr. Guest across ProfileScreen in English and Arabic with zero Shehab Shaif', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      // Set guest mode preferences
      final repo = PreferencesRepository();
      await repo.saveUserProfile(
        firstName: 'Guest',
        lastName: '',
        university: 'Guest Dental University',
        academicYear: '5th Year',
        isGuest: true,
      );

      final containerEn = ProviderContainer();
      await containerEn.read(userProfileProvider.notifier).loadProfile();

      // Verify English ProfileScreen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: containerEn,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dr. Guest'), findsOneWidget);
      expect(find.text('Shehab Shaif'), findsNothing);
      expect(find.text('Dr. Shehab Shaif'), findsNothing);

      // Verify Arabic ProfileScreen
      await repo.setLocale('ar');
      final containerAr = ProviderContainer();
      await containerAr.read(userProfileProvider.notifier).loadProfile();
      await containerAr.read(localeProvider.notifier).setLocale('ar');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: containerAr,
          child: MaterialApp(
            theme: AppTheme.lightThemeForLocale(const Locale('ar')),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ar'),
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('د. ضيف'), findsOneWidget);
      expect(find.text('شهاب'), findsNothing);
      expect(find.text('Shehab Shaif'), findsNothing);
    });

    testWidgets('Guest DashboardHeader renders Dr. Guest in EN and د. ضيف in AR', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const Scaffold(
              body: DashboardHeader(
                doctorName: 'Guest',
                academicYear: '5th Year',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Dr. Guest'), findsOneWidget);
      expect(find.textContaining('Shehab'), findsNothing);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ar'),
            home: const Scaffold(
              body: DashboardHeader(
                doctorName: 'Guest',
                academicYear: '5th Year',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('د. ضيف'), findsOneWidget);
      expect(find.textContaining('Shehab'), findsNothing);
    });

    testWidgets('EditProfileModal for Guest pre-populates Guest without falling back to Shehab Shaif', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final repo = PreferencesRepository();
      await repo.saveUserProfile(
        firstName: 'Guest',
        lastName: '',
        university: 'Guest Dental University',
        academicYear: '5th Year',
        isGuest: true,
      );

      final container = ProviderContainer();
      await container.read(userProfileProvider.notifier).loadProfile();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => EditProfileModal.show(context),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('Shehab'), findsNothing);
      expect(find.text('Shaif'), findsNothing);
    });
  });

  group('Issue #66: Exported Report Name & Metadata Tests', () {
    test('Report generator injects dynamic user credentials and zero Shehab Shaif into CSV and PDF data', () async {
      final realUserData = QuotaReportData(
        doctorName: 'Dr. Alexander Fleming',
        university: "St Mary's Hospital Medical School",
        academicYear: '5th Year',
        generatedDate: DateTime(2026, 11, 24),
        clinics: const <Clinic>[],
        requirements: const <Requirement>[],
        cases: const <CaseRecord>[],
        patients: const <Patient>[],
      );

      const service = ReportGeneratorService();
      final csv = service.generateCsvReport(realUserData);

      expect(csv, contains('"Clinician Name","Dr. Alexander Fleming"'));
      expect(csv, contains('"Institution","St Mary\'s Hospital Medical School"'));
      expect(csv, contains('"Academic Year","5th Year"'));
      expect(csv.contains('Shehab'), isFalse);
      expect(csv.contains('Shaif'), isFalse);
    });

    test('Report generator for Guest mode injects Dr. Guest with zero Shehab Shaif', () async {
      final guestData = QuotaReportData(
        doctorName: 'Dr. Guest',
        university: 'Guest Dental University',
        academicYear: '5th Year',
        generatedDate: DateTime(2026, 11, 24),
        clinics: const <Clinic>[],
        requirements: const <Requirement>[],
        cases: const <CaseRecord>[],
        patients: const <Patient>[],
      );

      const service = ReportGeneratorService();
      final csv = service.generateCsvReport(guestData);

      expect(csv, contains('"Clinician Name","Dr. Guest"'));
      expect(csv, contains('"Institution","Guest Dental University"'));
      expect(csv.contains('Shehab'), isFalse);
      expect(csv.contains('Shaif'), isFalse);
    });
  });
}
