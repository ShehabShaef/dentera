import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/core/services/report_generator_service.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/modals/generate_quota_report_modal.dart';

class FakeReportGeneratorService extends ReportGeneratorService {
  bool previewAndPrintCalled = false;
  bool sharePdfCalled = false;
  bool shareCsvCalled = false;
  QuotaReportData? lastData;

  @override
  Future<void> previewAndPrintPdf(
    QuotaReportData data, {
    String title = 'Dentera_Quota_Report',
  }) async {
    previewAndPrintCalled = true;
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
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'doctorName': 'Dr. Shehab Shaif',
      'academicYear': '5th Year',
      'university': 'Dental School',
    });
  });

  final testClinics = <Clinic>[
    Clinic(
      id: 'clinic-endo',
      name: 'Endodontics',
      academicYear: '5th Year',
      colorHex: '#1E568C',
    ),
    Clinic(
      id: 'clinic-surgery',
      name: 'Oral Surgery',
      academicYear: '5th Year',
      colorHex: '#8C1D18',
    ),
  ];

  final testRequirements = <Requirement>[
    Requirement(
      id: 'req-1',
      clinicId: 'clinic-endo',
      title: 'Molar Root Canal',
      targetCount: 5,
      completedCount: 3,
    ),
  ];

  final testCases = <CaseRecord>[
    CaseRecord(
      id: 'case-1',
      patientId: 'pat-1',
      requirementId: 'req-1',
      status: 'Evaluated',
      dateStarted: DateTime(2026, 3, 1),
      dateCompleted: DateTime(2026, 3, 1),
    ),
  ];

  group('GenerateQuotaReportModal Widget Tests', () {
    testWidgets('Modal renders header, clinician info, scope, and action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicListProvider.overrideWith((ref) async => testClinics),
            allRequirementsProvider.overrideWith((ref) async => testRequirements),
            allCasesProvider.overrideWith((ref) async => testCases),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GenerateQuotaReportModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Generate Quota Report'), findsOneWidget);
      expect(find.text('Academic Supervisory Portfolio'), findsOneWidget);
      expect(find.text('Dr. Shehab Shaif'), findsOneWidget);
      expect(find.text('5th Year • Dental School'), findsOneWidget);
      expect(find.text('Department Scope'), findsOneWidget);
      expect(find.text('Case Date Range'), findsOneWidget);
      expect(find.text('All Time (Complete Record)'), findsOneWidget);

      expect(find.text('Preview & Print PDF'), findsOneWidget);
      expect(find.text('Share PDF Report'), findsOneWidget);
      expect(find.text('Export Tabular CSV (Grading Sheet)'), findsOneWidget);
    });

    testWidgets('Initial clinic pre-selects the department scope', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicListProvider.overrideWith((ref) async => testClinics),
            allRequirementsProvider.overrideWith((ref) async => testRequirements),
            allCasesProvider.overrideWith((ref) async => testCases),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GenerateQuotaReportModal(initialClinic: testClinics.first),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Endodontics'), findsOneWidget);
    });

    testWidgets('Tapping Preview & Print triggers service method', (WidgetTester tester) async {
      final fakeService = FakeReportGeneratorService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicListProvider.overrideWith((ref) async => testClinics),
            allRequirementsProvider.overrideWith((ref) async => testRequirements),
            allCasesProvider.overrideWith((ref) async => testCases),
            reportGeneratorServiceProvider.overrideWithValue(fakeService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GenerateQuotaReportModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final printButton = find.text('Preview & Print PDF');
      await tester.ensureVisible(printButton);
      await tester.tap(printButton);
      await tester.pumpAndSettle();

      expect(fakeService.previewAndPrintCalled, isTrue);
      expect(fakeService.lastData?.doctorName, equals('Dr. Shehab Shaif'));
    });

    testWidgets('Tapping Share PDF triggers service method', (WidgetTester tester) async {
      final fakeService = FakeReportGeneratorService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicListProvider.overrideWith((ref) async => testClinics),
            allRequirementsProvider.overrideWith((ref) async => testRequirements),
            allCasesProvider.overrideWith((ref) async => testCases),
            reportGeneratorServiceProvider.overrideWithValue(fakeService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GenerateQuotaReportModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sharePdfButton = find.text('Share PDF Report');
      await tester.ensureVisible(sharePdfButton);
      await tester.tap(sharePdfButton);
      await tester.pumpAndSettle();

      expect(fakeService.sharePdfCalled, isTrue);
    });

    testWidgets('Tapping Export CSV triggers service method', (WidgetTester tester) async {
      final fakeService = FakeReportGeneratorService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicListProvider.overrideWith((ref) async => testClinics),
            allRequirementsProvider.overrideWith((ref) async => testRequirements),
            allCasesProvider.overrideWith((ref) async => testCases),
            reportGeneratorServiceProvider.overrideWithValue(fakeService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GenerateQuotaReportModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final exportCsvButton = find.text('Export Tabular CSV (Grading Sheet)');
      await tester.ensureVisible(exportCsvButton);
      await tester.tap(exportCsvButton);
      await tester.pumpAndSettle();

      expect(fakeService.shareCsvCalled, isTrue);
    });
  });
}
