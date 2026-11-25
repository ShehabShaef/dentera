import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:dentera/core/services/report_generator_service.dart';
import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/database/app_database.dart';
import 'package:dentera/data/database/database_providers.dart';
import 'package:dentera/data/database/database_seeder.dart';
import 'package:dentera/data/repositories/preferences_repository.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/l10n/l10n.dart';
import 'package:dentera/presentation/screens/profile/profile_screen.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/modals/generate_quota_report_modal.dart';

import '../../setup/test_setup.dart';

class _CapturingReportGeneratorService extends ReportGeneratorService {
  bool previewCalled = false;
  bool sharePdfCalled = false;
  bool shareCsvCalled = false;
  QuotaReportData? lastData;

  @override
  Future<void> previewAndPrintPdf(
    QuotaReportData data, {
    String title = 'Dentera_Quota_Report',
  }) async {
    previewCalled = true;
    lastData = data;
  }

  @override
  Future<void> sharePdf(
    QuotaReportData data, {
    String filename = 'dentera_quota_report.pdf',
  }) async {
    sharePdfCalled = true;
    lastData = data;
  }

  @override
  Future<void> shareCsv(
    QuotaReportData data, {
    String filename = 'dentera_quota_report.csv',
  }) async {
    shareCsvCalled = true;
    lastData = data;
  }
}

void main() {
  setUpAll(() {
    setupDatabaseTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  group('Issue #67: SQLite FFI Strict Data Isolation (Real User vs. Guest)', () {
    test('Real User onboarding starts with 0 patients, 0 case records, and 0 appointments', () async {
      final db = await AppDatabase.instance.database;
      // Start from a clean empty slate (simulating post-reset onboarding too)
      await AppDatabase.instance.resetAllData();

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Run production onboarding seeder for Real User
      await container.read(onboardingSeederProvider)(
        isGuest: false,
        academicYear: '4th Year',
      );

      final clinics = await db.query('clinics');
      final requirements = await db.query('requirements');
      final patients = await db.query('patients');
      final cases = await db.query('case_records');
      final appointments = await db.query('appointments');
      final visits = await db.query('case_visits');
      final plans = await db.query('treatment_plans');

      // Structural defaults exist with selected academicYear and 0 completed counts
      expect(clinics.length, equals(6));
      for (final clinic in clinics) {
        expect(clinic['academicYear'], equals('4th Year'));
      }
      expect(requirements.length, equals(16));
      for (final req in requirements) {
        expect(req['completedCount'], equals(0));
      }

      // Clinical tables MUST remain 100% empty for Real User
      expect(patients.length, equals(0), reason: 'Real user must start with 0 fake patients');
      expect(cases.length, equals(0), reason: 'Real user must start with 0 fake cases');
      expect(appointments.length, equals(0), reason: 'Real user must start with 0 fake appointments');
      expect(visits.length, equals(0));
      expect(plans.length, equals(0));
    });

    test('Real User baseline preserves 0 clinical records even when DB was initialized by onCreate', () async {
      await AppDatabase.instance.close();
      final db = await AppDatabase.instance.database;

      await DatabaseSeeder.seedRealUserBaseline(db, academicYear: '3rd Year');

      final patientsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM patients;'),
      );
      final casesCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM case_records;'),
      );
      final apptsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM appointments;'),
      );
      final clinics = await db.query('clinics');

      expect(patientsCount, equals(0));
      expect(casesCount, equals(0));
      expect(apptsCount, equals(0));
      expect(clinics.length, equals(6));
      expect(clinics.first['academicYear'], equals('3rd Year'));
    });

    test('Guest onboarding populates rich demo dataset covering all statuses, overdue cases, and appointment timelines', () async {
      await AppDatabase.instance.resetAllData();

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(onboardingSeederProvider)(
        isGuest: true,
        academicYear: '5th Year',
      );

      final db = await AppDatabase.instance.database;
      final fixedNow = DateTime.now();

      final clinics = await db.query('clinics');
      final requirements = await db.query('requirements');
      final patients = await db.query('patients');
      final cases = await db.query('case_records');
      final appointments = await db.query('appointments');
      final visits = await db.query('case_visits');
      final plans = await db.query('treatment_plans');

      expect(clinics.length, equals(6));
      expect(requirements.length, equals(16));
      expect(patients.length, greaterThanOrEqualTo(5));
      expect(cases.length, greaterThanOrEqualTo(10));
      expect(appointments.length, greaterThanOrEqualTo(6));
      expect(visits.length, greaterThan(0));
      expect(plans.length, greaterThan(0));

      // Verify case statuses: Evaluated, Completed, In Progress, and Overdue (>= 14 days In Progress)
      final caseModels = cases.map((m) => CaseRecord.fromMap(m)).toList();
      expect(caseModels.any((c) => c.status == 'Evaluated'), isTrue);
      expect(caseModels.any((c) => c.status == 'Completed'), isTrue);
      expect(caseModels.any((c) => c.status == 'In Progress'), isTrue);

      final overdueCases = caseModels.where((c) {
        return c.status == 'In Progress' &&
            c.dateCompleted == null &&
            fixedNow.difference(c.dateStarted).inDays >= 14;
      }).toList();
      expect(
        overdueCases.length,
        greaterThanOrEqualTo(2),
        reason: 'Guest demo dataset must contain >=2 overdue/delayed cases (>=14 days in progress)',
      );

      // Verify synced requirement completedCounts match Completed/Evaluated demo cases
      final completedByReq = <String, int>{};
      for (final c in caseModels) {
        final s = c.status.toLowerCase();
        if (s == 'completed' || s == 'evaluated') {
          completedByReq[c.requirementId] = (completedByReq[c.requirementId] ?? 0) + 1;
        }
      }
      for (final reqRow in requirements) {
        final req = Requirement.fromMap(reqRow);
        expect(req.completedCount, equals(completedByReq[req.id] ?? 0));
      }

      // Verify appointments span past/completed, today, tomorrow, and upcoming future
      final aptModels = appointments.map((m) => Appointment.fromMap(m)).toList();
      final todayStart = DateTime(fixedNow.year, fixedNow.month, fixedNow.day);
      final tomorrowStart = todayStart.add(const Duration(days: 1));
      final dayAfterTomorrow = todayStart.add(const Duration(days: 2));

      expect(
        aptModels.any((a) => a.scheduledDate.isBefore(todayStart) && a.status == 'Completed'),
        isTrue,
        reason: 'Must have past completed appointments',
      );
      expect(
        aptModels.any((a) => !a.scheduledDate.isBefore(todayStart) && a.scheduledDate.isBefore(tomorrowStart)),
        isTrue,
        reason: 'Must have today appointments',
      );
      expect(
        aptModels.any((a) => !a.scheduledDate.isBefore(tomorrowStart) && a.scheduledDate.isBefore(dayAfterTomorrow)),
        isTrue,
        reason: 'Must have tomorrow appointments',
      );
      expect(
        aptModels.any((a) => !a.scheduledDate.isBefore(dayAfterTomorrow)),
        isTrue,
        reason: 'Must have future upcoming appointments',
      );

      // Verify idempotency when calling seedGuestDemoData a second time
      await DatabaseSeeder.seedGuestDemoData(db);
      final patientsCountAfterSecond = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM patients;'),
      );
      expect(patientsCountAfterSecond, equals(patients.length));
    });
  });

  group('Issue #67: Watermarked Demo Report Generation Service Tests', () {
    test('buildGuestDemoReportData populates rich demo data and enforces isDemoReport = true', () {
      final enData = ReportGeneratorService.buildGuestDemoReportData(
        localeCode: 'en',
        generatedDate: DateTime(2026, 11, 24),
      );
      expect(enData.isDemoReport, isTrue);
      expect(enData.doctorName, equals('Dr. Guest'));
      expect(enData.university, equals('Guest Dental University'));
      expect(enData.clinics.length, equals(6));
      expect(enData.patients.length, greaterThanOrEqualTo(5));
      expect(enData.cases.length, greaterThanOrEqualTo(10));

      final arData = ReportGeneratorService.buildGuestDemoReportData(
        localeCode: 'ar',
        generatedDate: DateTime(2026, 11, 24),
      );
      expect(arData.isDemoReport, isTrue);
      expect(arData.doctorName, equals('د. ضيف'));
    });

    test('generateCsvReport renders explicit DEMO REPORT watermarks only when isDemoReport is true', () {
      const service = ReportGeneratorService();

      final guestEnData = ReportGeneratorService.buildGuestDemoReportData(
        localeCode: 'en',
        generatedDate: DateTime(2026, 11, 24),
      );
      final guestCsvEn = service.generateCsvReport(guestEnData);
      expect(guestCsvEn, contains('DEMO REPORT — FOR SHOWCASE ONLY (DEMO DATA)'));
      expect(guestCsvEn, contains('DEMO REPORT — SAMPLE DATA ONLY'));
      expect(guestCsvEn, contains('"Clinician Name","Dr. Guest"'));
      expect(guestCsvEn, contains('Layla Al-Harbi'));

      final guestArData = ReportGeneratorService.buildGuestDemoReportData(
        localeCode: 'ar',
        generatedDate: DateTime(2026, 11, 24),
      );
      final guestCsvAr = service.generateCsvReport(guestArData);
      expect(guestCsvAr, contains('DEMO REPORT — FOR SHOWCASE ONLY (DEMO DATA)'));
      expect(guestCsvAr, contains('DEMO REPORT — SAMPLE DATA ONLY'));
      expect(guestCsvAr, contains('تقرير تجريبي — للعرض فقط (بيانات تجريبية)'));
      expect(guestCsvAr, contains('د. ضيف'));

      // Live report for registered student MUST NOT contain demo watermarks
      final liveData = QuotaReportData(
        doctorName: 'Dr. Ahmed Nasser',
        university: "Sana'a University",
        academicYear: '5th Year',
        generatedDate: DateTime(2026, 11, 24),
        clinics: const <Clinic>[],
        requirements: const <Requirement>[],
        cases: const <CaseRecord>[],
        patients: const <Patient>[],
        isDemoReport: false,
      );
      final liveCsv = service.generateCsvReport(liveData);
      expect(liveCsv.contains('DEMO REPORT'), isFalse);
      expect(liveCsv.contains('تقرير تجريبي'), isFalse);
    });

    test('generatePdfReport builds valid watermarked PDF bytes for Guest Mode in EN and AR', () async {
      const service = ReportGeneratorService();

      final enData = ReportGeneratorService.buildGuestDemoReportData(
        localeCode: 'en',
        generatedDate: DateTime(2026, 11, 24),
      );
      final Uint8List enBytes = await service.generatePdfReport(enData);
      expect(enBytes.length, greaterThan(1000));
      expect(String.fromCharCodes(enBytes.take(4)), equals('%PDF'));

      final arData = ReportGeneratorService.buildGuestDemoReportData(
        localeCode: 'ar',
        generatedDate: DateTime(2026, 11, 24),
      );
      final Uint8List arBytes = await service.generatePdfReport(arData);
      expect(arBytes.length, greaterThan(1000));
      expect(String.fromCharCodes(arBytes.take(4)), equals('%PDF'));
    });
  });

  group('Issue #67: Guest Report Export UI Restriction & Dialog Flow Tests', () {
    testWidgets('Guest Mode renders demo notice in ProfileScreen and GenerateQuotaReportModal, and enforces Demo Dialog before export', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final repo = PreferencesRepository();
      await repo.saveUserProfile(
        firstName: 'Guest',
        lastName: '',
        university: 'Guest Dental University',
        academicYear: '5th Year',
        isGuest: true,
      );

      final fakeService = _CapturingReportGeneratorService();
      final container = ProviderContainer(
        overrides: [
          clinicListProvider.overrideWith((ref) async => const <Clinic>[]),
          allRequirementsProvider.overrideWith((ref) async => const <Requirement>[]),
          allCasesProvider.overrideWith((ref) async => const <CaseRecord>[]),
          patientListProvider.overrideWith((ref) async => const <Patient>[]),
          reportGeneratorServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);
      await container.read(userProfileProvider.notifier).loadProfile();

      // 1. Verify ProfileScreen indicates Demo Report Showcase for Guest
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
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
      expect(find.text('Demo Report Showcase'), findsOneWidget);

      // 2. Tap Generate Quota Report to open modal
      final reportTile = find.text('Generate Quota Report');
      await tester.ensureVisible(reportTile);
      await tester.tap(reportTile);
      await tester.pumpAndSettle();

      // Verify Guest notice banner and Demo button labels appear inside modal
      expect(
        find.text("Guest Mode: Exporting generates a Demo Report with sample showcase data to preview Dentera's report layout."),
        findsOneWidget,
      );
      expect(find.text('Preview & Print Demo PDF'), findsOneWidget);
      expect(find.text('Share Demo PDF Report'), findsOneWidget);
      expect(find.text('Export Demo Tabular CSV'), findsOneWidget);

      // 3. Tap Share Demo PDF Report -> confirmation dialog MUST block immediate export
      final shareDemoBtn = find.text('Share Demo PDF Report');
      await tester.ensureVisible(shareDemoBtn);
      await tester.tap(shareDemoBtn);
      await tester.pumpAndSettle();

      expect(fakeService.sharePdfCalled, isFalse);
      expect(find.text('Demo Report Showcase'), findsWidgets);
      expect(find.text('Generate Demo Report'), findsOneWidget);

      // Cancel dialog -> export must NOT execute
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(fakeService.sharePdfCalled, isFalse);

      // 4. Tap Export Demo Tabular CSV and confirm dialog
      final exportCsvBtn = find.text('Export Demo Tabular CSV');
      await tester.ensureVisible(exportCsvBtn);
      await tester.tap(exportCsvBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate Demo Report'));
      await tester.pumpAndSettle();

      expect(fakeService.shareCsvCalled, isTrue);
      expect(fakeService.lastData, isNotNull);
      expect(fakeService.lastData!.isDemoReport, isTrue);
      expect(fakeService.lastData!.doctorName, equals('Dr. Guest'));
      expect(fakeService.lastData!.patients.length, greaterThanOrEqualTo(5));
      expect(fakeService.lastData!.cases.length, greaterThanOrEqualTo(10));
    });

    testWidgets('Real User exports live report directly without Demo warning banner or Guest dialog', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final repo = PreferencesRepository();
      await repo.saveUserProfile(
        firstName: 'Ahmed',
        lastName: 'Nasser',
        university: "Sana'a University",
        academicYear: '5th Year',
        isGuest: false,
      );

      final fakeService = _CapturingReportGeneratorService();
      final container = ProviderContainer(
        overrides: [
          clinicListProvider.overrideWith((ref) async => const <Clinic>[]),
          allRequirementsProvider.overrideWith((ref) async => const <Requirement>[]),
          allCasesProvider.overrideWith((ref) async => const <CaseRecord>[]),
          patientListProvider.overrideWith((ref) async => const <Patient>[]),
          reportGeneratorServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);
      await container.read(userProfileProvider.notifier).loadProfile();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const Scaffold(
              body: GenerateQuotaReportModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dr. Ahmed Nasser'), findsOneWidget);
      expect(find.text('Preview & Print PDF'), findsOneWidget);
      expect(find.text('Preview & Print Demo PDF'), findsNothing);

      final shareBtn = find.text('Share PDF Report');
      await tester.ensureVisible(shareBtn);
      await tester.tap(shareBtn);
      await tester.pumpAndSettle();

      // Executes directly without Demo dialog
      expect(find.text('Demo Report Showcase'), findsNothing);
      expect(fakeService.sharePdfCalled, isTrue);
      expect(fakeService.lastData!.isDemoReport, isFalse);
      expect(fakeService.lastData!.doctorName, equals('Dr. Ahmed Nasser'));
    });

    testWidgets('Arabic Guest Mode displays Arabic Demo notices, confirmation dialog, and sets localeCode = ar', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final repo = PreferencesRepository();
      await repo.setLocale('ar');
      await repo.saveUserProfile(
        firstName: 'Guest',
        lastName: '',
        university: 'Guest Dental University',
        academicYear: '5th Year',
        isGuest: true,
      );

      final fakeService = _CapturingReportGeneratorService();
      final container = ProviderContainer(
        overrides: [
          clinicListProvider.overrideWith((ref) async => const <Clinic>[]),
          allRequirementsProvider.overrideWith((ref) async => const <Requirement>[]),
          allCasesProvider.overrideWith((ref) async => const <CaseRecord>[]),
          patientListProvider.overrideWith((ref) async => const <Patient>[]),
          reportGeneratorServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);
      await container.read(localeProvider.notifier).setLocale('ar');
      await container.read(userProfileProvider.notifier).loadProfile();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightThemeForLocale(const Locale('ar')),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ar'),
            home: const Scaffold(
              body: GenerateQuotaReportModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('د. ضيف'), findsOneWidget);
      expect(find.text('مشاركة تقرير PDF التجريبي'), findsOneWidget);

      final shareBtn = find.text('مشاركة تقرير PDF التجريبي');
      await tester.ensureVisible(shareBtn);
      await tester.tap(shareBtn);
      await tester.pumpAndSettle();

      expect(find.text('عرض التقرير التجريبي'), findsOneWidget);
      expect(fakeService.sharePdfCalled, isFalse);

      await tester.tap(find.text('إنشاء التقرير التجريبي'));
      await tester.pumpAndSettle();

      expect(fakeService.sharePdfCalled, isTrue);
      expect(fakeService.lastData!.isDemoReport, isTrue);
      expect(fakeService.lastData!.localeCode, equals('ar'));
      expect(fakeService.lastData!.doctorName, equals('د. ضيف'));
    });

    test('Guest demo dataset triggers clinicalRemindersProvider overdue case & imminent appointment reminders', () async {
      final referenceNow = DateTime(2026, 11, 24, 14, 0);
      final demo = DatabaseSeeder.buildGuestDemoDataset(referenceNow: referenceNow);

      final today = DateTime(referenceNow.year, referenceNow.month, referenceNow.day);
      final todayApts = demo.appointments.where((a) =>
          a.scheduledDate.year == today.year &&
          a.scheduledDate.month == today.month &&
          a.scheduledDate.day == today.day).toList();
      final futureApts = demo.appointments.where((a) => a.scheduledDate.isAfter(today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)))).toList();

      final container = ProviderContainer(
        overrides: [
          clinicalRemindersClockProvider.overrideWithValue(referenceNow),
          clinicListProvider.overrideWith((ref) async => demo.clinics),
          allRequirementsProvider.overrideWith((ref) async => demo.requirements),
          allCasesProvider.overrideWith((ref) async => demo.caseRecords),
          patientListProvider.overrideWith((ref) async => demo.patients),
          allAppointmentsProvider.overrideWith((ref) async => demo.appointments),
          dailyAppointmentsProvider.overrideWith((ref, date) async => todayApts),
          upcomingAppointmentsProvider.overrideWith((ref) async => futureApts),
        ],
      );
      addTearDown(container.dispose);

      // Await future providers so synchronous clinicalRemindersProvider observes data
      await container.read(clinicListProvider.future);
      await container.read(allRequirementsProvider.future);
      await container.read(allCasesProvider.future);
      await container.read(patientListProvider.future);
      await container.read(allAppointmentsProvider.future);
      await container.read(dailyAppointmentsProvider(today).future);
      await container.read(upcomingAppointmentsProvider.future);

      final reminders = container.read(clinicalRemindersProvider);
      expect(
        reminders.any((r) => r.category == ReminderCategory.overdueCase),
        isTrue,
        reason: 'Guest demo cases must trigger overdue reminder pills',
      );
      expect(
        reminders.any((r) => r.category == ReminderCategory.imminentAppointment),
        isTrue,
        reason: 'Guest demo today appointment must trigger imminent reminder pill',
      );
      expect(
        reminders.any((r) => r.category == ReminderCategory.laggingQuota),
        isTrue,
        reason: 'Guest demo quotas must trigger quota pacing pills',
      );
    });
  });
}
