import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/repositories/preferences_repository.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/l10n/l10n.dart';
import 'package:dentera/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:dentera/presentation/screens/root_navigation_screen.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/widgets.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Issue #65: Locale Auto-Detection & Preferences Tests', () {
    test('defaultDeviceLanguageCode fallback returns en in non-ar test environment', () {
      final defaultLang = PreferencesRepository.defaultDeviceLanguageCode;
      expect(defaultLang == 'en' || defaultLang == 'ar', isTrue);
    });

    test('getLocale returns saved preference when available, otherwise defaults to device language', () async {
      final repo = PreferencesRepository();
      final initialLocale = await repo.getLocale();
      expect(initialLocale, equals(PreferencesRepository.defaultDeviceLanguageCode));

      // Explicitly set Arabic
      await repo.setLocale('ar');
      expect(await repo.getLocale(), 'ar');

      // Explicitly set English
      await repo.setLocale('en');
      expect(await repo.getLocale(), 'en');
    });

    test('UserProfile formats guest name cleanly for EN and AR', () {
      const guestEn = UserProfile(
        firstName: 'Guest',
        lastName: '',
        university: 'Guest Dental University',
        academicYear: '5th Year',
        isGuest: true,
      );
      expect(guestEn.name, 'Dr. Guest');
      expect(guestEn.formattedFullDoctorName('en'), 'Dr. Guest');
      expect(guestEn.formattedFullDoctorName('ar'), 'د. ضيف');

      const regularUser = UserProfile(
        firstName: 'Ahmed',
        lastName: 'Nasser',
        university: "Sana'a University",
        academicYear: '5th Year',
        isGuest: false,
      );
      expect(regularUser.name, 'Dr. Ahmed Nasser');
      expect(regularUser.formattedFullDoctorName('en'), 'Dr. Ahmed Nasser');
      expect(regularUser.formattedFullDoctorName('ar'), 'د. Ahmed Nasser');
    });
  });

  group('Issue #65: Arabic Onboarding Localization & Placeholders Widget Tests', () {
    Widget buildArabicOnboarding() {
      return ProviderScope(
        overrides: [
          dailyAppointmentsProvider.overrideWith((ref, date) => <Appointment>[]),
          upcomingAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
          patientListProvider.overrideWith((ref) => <Patient>[]),
          allCasesProvider.overrideWith((ref) => <CaseRecord>[]),
          allRequirementsProvider.overrideWith((ref) => <Requirement>[]),
          clinicListProvider.overrideWith((ref) => <Clinic>[]),
        ],
        child: MaterialApp(
          theme: AppTheme.lightThemeForLocale(const Locale('ar')),
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OnboardingScreen(),
        ),
      );
    }

    testWidgets('Step 1 renders Arabic prefix banner, labels, and placeholders', (WidgetTester tester) async {
      await tester.pumpWidget(buildArabicOnboarding());
      await tester.pumpAndSettle();

      // Check Arabic Dr prefix and explanation banner
      expect(find.text('د.'), findsOneWidget);
      expect(find.text('تتم إضافة اللقب تلقائيًا. يُرجى إدخال اسمك الأول واسم العائلة.'), findsOneWidget);

      // Check Arabic First & Last Name labels and placeholders
      expect(find.text('الاسم الأول'), findsOneWidget);
      expect(find.text('أحمد'), findsOneWidget);
      expect(find.text('اسم العائلة'), findsOneWidget);
      expect(find.text('ناصر'), findsOneWidget);
    });

    testWidgets('Step 2 & Step 3 render Arabic titles, hints, and academic stages', (WidgetTester tester) async {
      await tester.pumpWidget(buildArabicOnboarding());
      await tester.pumpAndSettle();

      // Enter names in Step 1
      final firstField = find.widgetWithText(DenteraTextField, 'الاسم الأول');
      final lastField = find.widgetWithText(DenteraTextField, 'اسم العائلة');
      await tester.enterText(firstField, 'أحمد');
      await tester.enterText(lastField, 'ناصر');
      await tester.pumpAndSettle();

      // Advance to Step 2
      await tester.tap(find.widgetWithText(PrimaryButton, 'متابعة'));
      await tester.pumpAndSettle();

      // Verify Step 2 Arabic content
      expect(find.text('جامعتك أو كليتك'), findsOneWidget);
      expect(find.text('ما هي الجامعة أو كلية طب الأسنان التي تدرس بها؟'), findsOneWidget);
      expect(find.text('الجامعة / الكلية'), findsOneWidget);
      expect(find.text('مثال: جامعة صنعاء'), findsOneWidget);

      // Enter university in Step 2
      final uniField = find.widgetWithText(DenteraTextField, 'الجامعة / الكلية');
      await tester.enterText(uniField, 'جامعة صنعاء');
      await tester.pumpAndSettle();

      // Advance to Step 3
      await tester.tap(find.widgetWithText(PrimaryButton, 'متابعة'));
      await tester.pumpAndSettle();

      // Verify Step 3 Arabic content
      expect(find.text('السنة الإكلينيكية'), findsOneWidget);
      expect(find.text('اختر مرحلتك الدراسية الحالية لتخصيص تتبع المتطلبات الإكلينيكية.'), findsOneWidget);
      expect(find.text('السنة الثالثة'), findsOneWidget);
      expect(find.text('السنة الرابعة'), findsOneWidget);
      expect(find.text('السنة الخامسة'), findsOneWidget);
      expect(find.text('سنة الامتياز'), findsOneWidget);
    });
  });

  group('Issue #65: Strict Required Validation (Real User vs. Guest) Tests', () {
    Widget buildEnglishOnboarding() {
      return ProviderScope(
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
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OnboardingScreen(),
        ),
      );
    }

    testWidgets('Step 2 blocks empty university with required error message', (WidgetTester tester) async {
      await tester.pumpWidget(buildEnglishOnboarding());
      await tester.pumpAndSettle();

      // Enter valid names in Step 1
      final firstField = find.widgetWithText(DenteraTextField, 'First Name');
      final lastField = find.widgetWithText(DenteraTextField, 'Last Name');
      await tester.enterText(firstField, 'Ahmed');
      await tester.enterText(lastField, 'Nasser');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));
      await tester.pumpAndSettle();

      // On Step 2: Try to continue with empty university
      expect(find.text('Your Institution'), findsOneWidget);
      await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));
      await tester.pumpAndSettle();

      // Expect validation error
      expect(find.text('University name is required'), findsOneWidget);
      expect(find.text('Clinical Year'), findsNothing);

      // Enter only whitespace
      final uniField = find.widgetWithText(DenteraTextField, 'University / School');
      await tester.enterText(uniField, '   ');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('University name is required'), findsOneWidget);
      expect(find.text('Clinical Year'), findsNothing);

      // Enter valid university
      await tester.enterText(uniField, "Sana'a University");
      await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));
      await tester.pumpAndSettle();

      // Successfully transitioned to Step 3
      expect(find.text('Clinical Year'), findsOneWidget);
    });

    testWidgets('Step 3 blocks submission if no academic stage is selected', (WidgetTester tester) async {
      await tester.pumpWidget(buildEnglishOnboarding());
      await tester.pumpAndSettle();

      // Fill Step 1
      await tester.enterText(find.widgetWithText(DenteraTextField, 'First Name'), 'Ahmed');
      await tester.enterText(find.widgetWithText(DenteraTextField, 'Last Name'), 'Nasser');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));
      await tester.pumpAndSettle();

      // Fill Step 2
      await tester.enterText(find.widgetWithText(DenteraTextField, 'University / School'), "Sana'a University");
      await tester.tap(find.widgetWithText(PrimaryButton, 'Continue'));
      await tester.pumpAndSettle();

      // On Step 3: No year is selected initially. Try submitting.
      expect(find.text('Clinical Year'), findsOneWidget);
      await tester.tap(find.widgetWithText(PrimaryButton, 'Enter Workspace'));
      await tester.pumpAndSettle();

      // Expect required academic year validation message
      expect(find.text('Please select an academic year'), findsOneWidget);
      expect(find.byType(RootNavigationScreen), findsNothing);

      // Now select 5th Year
      await tester.tap(find.text('5th Year'));
      await tester.pumpAndSettle();

      // Submit now succeeds
      await tester.tap(find.widgetWithText(PrimaryButton, 'Enter Workspace'));
      await tester.pumpAndSettle();

      expect(find.byType(RootNavigationScreen), findsOneWidget);

      final repo = PreferencesRepository();
      expect(await repo.hasCompletedOnboarding(), isTrue);
      expect(await repo.isGuest(), isFalse);
      expect(await repo.getDoctorName(), 'Dr. Ahmed Nasser');
      expect(await repo.getUniversity(), "Sana'a University");
      expect(await repo.getAcademicYear(), '5th Year');
    });

    testWidgets('Guest entry bypasses validation, assigns 5th Year, and sets isGuest = true', (WidgetTester tester) async {
      await tester.pumpWidget(buildEnglishOnboarding());
      await tester.pumpAndSettle();

      // Tap "Continue as a guest" without entering anything
      final guestButton = find.widgetWithText(TextButton, 'Continue as a guest');
      expect(guestButton, findsOneWidget);
      await tester.tap(guestButton);
      await tester.pumpAndSettle();

      // Immediately inside workspace
      expect(find.byType(RootNavigationScreen), findsOneWidget);

      final repo = PreferencesRepository();
      expect(await repo.hasCompletedOnboarding(), isTrue);
      expect(await repo.isGuest(), isTrue);
      expect(await repo.getDoctorName(), 'Dr. Guest');
      expect(await repo.getUniversity(), 'Guest Dental University');
      expect(await repo.getAcademicYear(), '5th Year');
    });
  });
}
