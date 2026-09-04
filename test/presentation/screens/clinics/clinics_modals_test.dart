import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/database/database_providers.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/domain/repositories/case_record_repository.dart';
import 'package:dentera/domain/repositories/clinic_repository.dart';
import 'package:dentera/domain/repositories/requirement_repository.dart';
import 'package:dentera/presentation/screens/clinics/clinic_details_screen.dart';
import 'package:dentera/presentation/screens/clinics/clinics_screen.dart';
import 'package:dentera/presentation/screens/clinics/widgets/widgets.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/modals/add_clinic_modal.dart';
import 'package:dentera/presentation/widgets/modals/add_requirement_modal.dart';
import 'package:dentera/presentation/widgets/modals/requirement_cases_bottom_sheet.dart';

class MockClinicRepository implements ClinicRepository {
  final List<Clinic> clinics = [];
  Clinic? lastAddedClinic;

  @override
  Future<void> addClinic(Clinic clinic) async {
    lastAddedClinic = clinic;
    clinics.add(clinic);
  }

  @override
  Future<List<Clinic>> getAllClinics() async => clinics;

  @override
  Future<Clinic?> getClinicById(String id) async =>
      clinics.where((c) => c.id == id).firstOrNull;
}

class MockRequirementRepository implements RequirementRepository {
  final List<Requirement> requirements = [];
  Requirement? lastAddedRequirement;

  @override
  Future<void> addRequirement(Requirement requirement) async {
    lastAddedRequirement = requirement;
    requirements.add(requirement);
  }

  @override
  Future<List<Requirement>> getAllRequirements() async => requirements;

  @override
  Future<List<Requirement>> getRequirementsByClinicId(String clinicId) async =>
      requirements.where((r) => r.clinicId == clinicId).toList();

  @override
  Future<void> updateRequirementProgress(String requirementId, int completedCount) async {}
}

class MockCaseRecordRepository implements CaseRecordRepository {
  final List<CaseRecord> cases = [];

  @override
  Future<void> addCaseRecord(CaseRecord caseRecord) async {
    cases.add(caseRecord);
  }

  @override
  Future<List<CaseRecord>> getAllCaseRecords() async => cases;

  @override
  Future<List<CaseRecord>> getCaseRecordsByPatientId(String patientId) async =>
      cases.where((c) => c.patientId == patientId).toList();

  @override
  Future<List<CaseRecord>> getCaseRecordsByRequirementId(String requirementId) async =>
      cases.where((c) => c.requirementId == requirementId).toList();

  @override
  Future<void> updateCaseRecord(CaseRecord caseRecord) async {}

  @override
  Future<void> deleteCaseRecord(String id) async {}
}

void main() {
  group('ClinicsScreen and ClinicDetailsScreen Modal Integration Tests', () {
    const testClinic = Clinic(
      id: 'clinic-prosth',
      name: 'Prosthodontics',
      academicYear: '5th Year',
      colorHex: '#003E6F',
    );

    const testRequirement = Requirement(
      id: 'req-cd',
      clinicId: 'clinic-prosth',
      title: 'Complete Denture',
      targetCount: 3,
      completedCount: 1,
    );

    final testPatients = [
      Patient(
        id: 'p-101',
        name: 'Ali Nasser',
        age: 35,
        gender: 'Male',
        createdAt: DateTime.now(),
      ),
    ];

    final testCases = [
      CaseRecord(
        id: 'case-01',
        patientId: 'p-101',
        requirementId: 'req-cd',
        status: 'In Progress',
        notes: 'Primary impressions poured in plaster.',
        dateStarted: DateTime(2026, 9, 1),
      ),
    ];

    testWidgets('Tapping FAB on ClinicsScreen renders AddClinicModal and submits new clinic',
        (WidgetTester tester) async {
      final mockClinicRepo = MockClinicRepository();
      mockClinicRepo.clinics.add(testClinic);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicRepositoryProvider.overrideWithValue(mockClinicRepo),
            clinicListProvider.overrideWith((ref) => mockClinicRepo.getAllClinics()),
            allRequirementsProvider.overrideWith((ref) async => [testRequirement]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ClinicsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify ClinicsScreen renders
      expect(find.text('Clinics & Requirements'), findsOneWidget);

      // 2. Programmatically tap FAB on ClinicsScreen
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // 3. Verify AddClinicModal bottom sheet is displayed
      expect(find.byType(AddClinicModal), findsOneWidget);
      expect(find.text('Add Dental Clinic'), findsOneWidget);
      expect(find.text('Save Clinic'), findsOneWidget);

      // 4. Fill form and submit
      final nameFieldFinder = find.widgetWithText(TextField, '');
      await tester.enterText(nameFieldFinder.first, 'Orthodontics');
      await tester.pumpAndSettle();

      final saveButtonFinder = find.text('Save Clinic');
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      // 5. Verify modal dismissed and state mutation triggered on repository
      expect(find.byType(AddClinicModal), findsNothing);
      expect(mockClinicRepo.lastAddedClinic, isNotNull);
      expect(mockClinicRepo.lastAddedClinic!.name, 'Orthodontics');
      expect(mockClinicRepo.lastAddedClinic!.academicYear, '5th Year');
    });

    testWidgets('AddClinicModal displays validation error when clinic name is empty',
        (WidgetTester tester) async {
      final mockClinicRepo = MockClinicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicRepositoryProvider.overrideWithValue(mockClinicRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: AddClinicModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Save Clinic with empty name
      await tester.tap(find.text('Save Clinic'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a clinic name'), findsOneWidget);
      expect(mockClinicRepo.lastAddedClinic, isNull);
    });

    testWidgets('Tapping FAB on ClinicDetailsScreen renders AddRequirementModal and submits new requirement',
        (WidgetTester tester) async {
      final mockReqRepo = MockRequirementRepository();
      mockReqRepo.requirements.add(testRequirement);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            requirementRepositoryProvider.overrideWithValue(mockReqRepo),
            requirementsByClinicProvider(testClinic.id)
                .overrideWith((ref) => mockReqRepo.getRequirementsByClinicId(testClinic.id)),
            allCasesProvider.overrideWith((ref) async => testCases),
          ],
          child: const MaterialApp(
            home: ClinicDetailsScreen(clinic: testClinic),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify ClinicDetailsScreen renders
      expect(find.text('Prosthodontics'), findsOneWidget);

      // 2. Programmatically tap FAB on ClinicDetailsScreen
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // 3. Verify AddRequirementModal bottom sheet is displayed
      expect(find.byType(AddRequirementModal), findsOneWidget);
      expect(find.text('Add Requirement'), findsOneWidget);
      expect(find.text('Save Requirement'), findsOneWidget);

      // 4. Fill form: enter Title and Quota
      final textFields = find.byType(TextField);
      // First is title, second is quota count
      await tester.enterText(textFields.first, 'Removable Partial Denture');
      await tester.enterText(textFields.last, '4');
      await tester.pumpAndSettle();

      // 5. Submit form
      await tester.tap(find.text('Save Requirement'));
      await tester.pumpAndSettle();

      // 6. Verify modal dismissed and requirement added
      expect(find.byType(AddRequirementModal), findsNothing);
      expect(mockReqRepo.lastAddedRequirement, isNotNull);
      expect(mockReqRepo.lastAddedRequirement!.title, 'Removable Partial Denture');
      expect(mockReqRepo.lastAddedRequirement!.targetCount, 4);
      expect(mockReqRepo.lastAddedRequirement!.clinicId, testClinic.id);
    });

    testWidgets('AddRequirementModal displays validation error for empty title or zero quota',
        (WidgetTester tester) async {
      final mockReqRepo = MockRequirementRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            requirementRepositoryProvider.overrideWithValue(mockReqRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AddRequirementModal(clinicId: 'clinic-test'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, '');
      await tester.enterText(textFields.last, '0');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Requirement'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a requirement title'), findsOneWidget);
      expect(find.text('Quota must be greater than 0'), findsOneWidget);
      expect(mockReqRepo.lastAddedRequirement, isNull);
    });

    testWidgets('Tapping RequirementDetailCard triggers RequirementCasesBottomSheet with matched case records',
        (WidgetTester tester) async {
      final mockCaseRepo = MockCaseRecordRepository();
      mockCaseRepo.cases.addAll(testCases);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            caseRecordRepositoryProvider.overrideWithValue(mockCaseRepo),
            casesByRequirementProvider(testRequirement.id)
                .overrideWith((ref) => mockCaseRepo.getCaseRecordsByRequirementId(testRequirement.id)),
            requirementsByClinicProvider(testClinic.id).overrideWith((ref) async => [testRequirement]),
            allCasesProvider.overrideWith((ref) async => testCases),
            patientListProvider.overrideWith((ref) async => testPatients),
          ],
          child: const MaterialApp(
            home: ClinicDetailsScreen(clinic: testClinic),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify RequirementDetailCard is present
      final reqCardFinder = find.byType(RequirementDetailCard);
      expect(reqCardFinder, findsOneWidget);

      // Programmatically tap RequirementDetailCard
      await tester.tap(reqCardFinder);
      await tester.pumpAndSettle();

      // Verify RequirementCasesBottomSheet renders
      expect(find.byType(RequirementCasesBottomSheet), findsOneWidget);
      expect(find.text('Complete Denture'), findsWidgets);
      expect(find.text('Ali Nasser'), findsWidgets);
      expect(find.text('In Progress'), findsWidgets);
      expect(find.text('Primary impressions poured in plaster.'), findsOneWidget);

      // Dismiss bottom sheet via close button
      final closeBtnFinder = find.byIcon(Icons.close_rounded);
      expect(closeBtnFinder, findsOneWidget);
      await tester.tap(closeBtnFinder);
      await tester.pumpAndSettle();

      expect(find.byType(RequirementCasesBottomSheet), findsNothing);
    });

    testWidgets('RequirementCasesBottomSheet displays empty zero-state when no cases match requirement',
        (WidgetTester tester) async {
      final mockCaseRepo = MockCaseRecordRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            caseRecordRepositoryProvider.overrideWithValue(mockCaseRepo),
            casesByRequirementProvider(testRequirement.id).overrideWith((ref) async => <CaseRecord>[]),
            patientListProvider.overrideWith((ref) async => testPatients),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RequirementCasesBottomSheet(requirement: testRequirement),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Case Records Logged'), findsOneWidget);
      expect(
        find.text(
          'No clinical cases have been logged for this requirement yet. Cases logged in Patient Case Sheets will appear here automatically.',
        ),
        findsOneWidget,
      );
    });
  });
}
