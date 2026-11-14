import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/core/services/report_generator_service.dart';
import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/repositories/preferences_repository.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/screens/dashboard/widgets/dashboard_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Doctor Name Formatting & Prefix Enforcement Unit Tests (Issue #53)', () {
    test('stripDoctorPrefix strips English and Arabic variants cleanly', () {
      expect(PreferencesRepository.stripDoctorPrefix('Dr. Shehab Shaif'), equals('Shehab Shaif'));
      expect(PreferencesRepository.stripDoctorPrefix('dr. shehab shaif'), equals('shehab shaif'));
      expect(PreferencesRepository.stripDoctorPrefix('Dr Shehab'), equals('Shehab'));
      expect(PreferencesRepository.stripDoctorPrefix('Doctor Shehab'), equals('Shehab'));
      expect(PreferencesRepository.stripDoctorPrefix('د. شهاب شائف'), equals('شهاب شائف'));
      expect(PreferencesRepository.stripDoctorPrefix('د/ شهاب شائف'), equals('شهاب شائف'));
      expect(PreferencesRepository.stripDoctorPrefix('د شهاب'), equals('شهاب'));
      expect(PreferencesRepository.stripDoctorPrefix('Dr. Dr. Shehab'), equals('Shehab'));
      expect(PreferencesRepository.stripDoctorPrefix('Shehab Shaif'), equals('Shehab Shaif'));
      expect(PreferencesRepository.stripDoctorPrefix('   '), equals(''));
    });

    test('splitFullName parses first and last name after stripping prefixes', () {
      final (first1, last1) = PreferencesRepository.splitFullName('Dr. Shehab Shaif');
      expect(first1, equals('Shehab'));
      expect(last1, equals('Shaif'));

      final (first2, last2) = PreferencesRepository.splitFullName('د. شهاب الدين شائف');
      expect(first2, equals('شهاب'));
      expect(last2, equals('الدين شائف'));

      final (first3, last3) = PreferencesRepository.splitFullName('Stephen');
      expect(first3, equals('Stephen'));
      expect(last3, equals(''));

      final (first4, last4) = PreferencesRepository.splitFullName('');
      expect(first4, equals(''));
      expect(last4, equals(''));
    });

    test('UserProfile formats full and short doctor names with programmatic prefix', () {
      const profile = UserProfile(
        firstName: 'Shehab',
        lastName: 'Shaif',
        university: 'Sana\'a Dental',
        academicYear: '5th Year',
      );

      // English defaults
      expect(profile.formattedFullDoctorName(), equals('Dr. Shehab Shaif'));
      expect(profile.formattedShortDoctorName(), equals('Dr. Shehab'));
      expect(profile.name, equals('Dr. Shehab Shaif'));

      // Arabic locale
      expect(profile.formattedFullDoctorName('ar'), equals('د. Shehab Shaif'));
      expect(profile.formattedShortDoctorName('ar'), equals('د. Shehab'));
    });

    test('UserProfile strips accidental Dr. prefix inside fields', () {
      const profile = UserProfile(
        firstName: 'Dr. Sarah',
        lastName: 'Connor',
        university: 'Cyberdyne',
        academicYear: '4th Year',
      );

      expect(profile.formattedFullDoctorName(), equals('Dr. Sarah Connor'));
      expect(profile.formattedShortDoctorName(), equals('Dr. Sarah'));
    });

    test('PreferencesRepository migrates legacy doctorName into split keys', () async {
      SharedPreferences.setMockInitialValues({
        'doctorName': 'Dr. Gregory House',
        'university': 'Princeton-Plainsboro',
        'academicYear': 'Internship',
      });

      final repo = PreferencesRepository();

      // Verify automatic migration split on first access
      expect(await repo.getDoctorFirstName(), equals('Gregory'));
      expect(await repo.getDoctorLastName(), equals('House'));
      expect(await repo.getDoctorName(), equals('Dr. Gregory House'));
      expect(await repo.getFormattedShortDoctorName(), equals('Dr. Gregory'));
      expect(await repo.getFormattedFullDoctorName(), equals('Dr. Gregory House'));
    });

    test('PreferencesRepository saves split first and last names and maintains legacy doctorName', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = PreferencesRepository();

      await repo.saveUserProfile(
        firstName: 'Dr. Lisa',
        lastName: 'Cuddy',
        university: 'Medical University',
        academicYear: '5th Year',
      );

      expect(await repo.getDoctorFirstName(), equals('Lisa'));
      expect(await repo.getDoctorLastName(), equals('Cuddy'));
      expect(await repo.getDoctorName(), equals('Dr. Lisa Cuddy'));
      expect(await repo.getFormattedShortDoctorName(), equals('Dr. Lisa'));
      expect(await repo.getFormattedFullDoctorName(), equals('Dr. Lisa Cuddy'));
    });
  });

  group('Doctor Name Rendering Widget & Report Tests (Issue #53)', () {
    testWidgets('DashboardHeader renders programmatic Dr. prefix without duplicating', (WidgetTester tester) async {
      // Test with raw un-prefixed name
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: DashboardHeader(
                doctorName: 'Shehab Shaif',
                academicYear: '5th Year',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good morning, Dr. Shehab Shaif'), findsOneWidget);
      expect(find.text('SS'), findsOneWidget);

      // Test with existing Dr. prefix (should NOT become Dr. Dr.)
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: DashboardHeader(
                doctorName: 'Dr. Shehab',
                academicYear: '5th Year',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good morning, Dr. Shehab'), findsOneWidget);
    });

    test('ReportGeneratorService enforces Dr. prefix in PDF and CSV exports', () async {
      const service = ReportGeneratorService();
      final data = QuotaReportData(
        doctorName: 'Shehab Shaif', // passed without prefix
        university: 'Faculty of Dentistry',
        academicYear: '5th Year',
        generatedDate: DateTime(2026, 11, 14),
        clinics: <Clinic>[],
        requirements: <Requirement>[],
        cases: <CaseRecord>[],
        patients: <Patient>[],
      );

      // Verify PDF generates with valid bytes
      final pdfBytes = await service.generatePdfReport(data);
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));

      // Verify CSV export contains formatted clinician name
      final csv = service.generateCsvReport(data);
      expect(csv, contains('"Clinician Name","Dr. Shehab Shaif"'));
    });
  });
}
