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
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/inputs/circular_checkbox.dart';
import 'package:dentera/presentation/widgets/modals/edit_clinic_modal.dart';
import 'package:dentera/presentation/widgets/modals/edit_requirement_modal.dart';
import 'package:dentera/presentation/widgets/modals/sort_clinic_cases_modal.dart';

class MockClinicRepository implements ClinicRepository {
  final List<Clinic> clinics = [];
  Clinic? lastUpdatedClinic;

  @override
  Future<void> addClinic(Clinic clinic) async {
    clinics.add(clinic);
  }

  @override
  Future<List<Clinic>> getAllClinics() async => clinics;

  @override
  Future<Clinic?> getClinicById(String id) async =>
      clinics.where((c) => c.id == id).firstOrNull;

  @override
  Future<void> updateClinic(Clinic clinic) async {
    lastUpdatedClinic = clinic;
    final idx = clinics.indexWhere((c) => c.id == clinic.id);
    if (idx != -1) clinics[idx] = clinic;
  }

  @override
  Future<void> deleteClinic(String id) async => clinics.removeWhere((c) => c.id == id);

  @override
  Future<void> deleteClinics(List<String> ids) async => clinics.removeWhere((c) => ids.contains(c.id));
}

class MockRequirementRepository implements RequirementRepository {
  final List<Requirement> requirements = [];
  Requirement? lastUpdatedRequirement;
  List<String>? lastDeletedIds;

  @override
  Future<void> addRequirement(Requirement requirement) async {
    requirements.add(requirement);
  }

  @override
  Future<List<Requirement>> getAllRequirements() async => requirements;

  @override
  Future<List<Requirement>> getRequirementsByClinicId(String clinicId) async =>
      requirements.where((r) => r.clinicId == clinicId).toList();

  @override
  Future<void> updateRequirementProgress(String requirementId, int completedCount) async {}

  @override
  Future<void> updateRequirement(Requirement requirement) async {
    lastUpdatedRequirement = requirement;
    final idx = requirements.indexWhere((r) => r.id == requirement.id);
    if (idx != -1) requirements[idx] = requirement;
  }

  @override
  Future<void> deleteRequirement(String id) async {
    lastDeletedIds = [id];
    requirements.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> deleteRequirements(List<String> ids) async {
    lastDeletedIds = ids;
    requirements.removeWhere((r) => ids.contains(r.id));
  }
}

class MockCaseRecordRepository implements CaseRecordRepository {
  final List<CaseRecord> cases = [];

  @override
  Future<void> addCaseRecord(CaseRecord caseRecord) async => cases.add(caseRecord);

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
  group('Clinic Details & In-Place Editing Widget Tests (Issue #15)', () {
    const testClinic = Clinic(
      id: 'clinic-pros-15',
      name: 'Prosthodontics Dept',
      academicYear: '5th Year',
      colorHex: '#003E6F',
    );

    const testReq1 = Requirement(
      id: 'req-cd-15',
      clinicId: 'clinic-pros-15',
      title: 'Complete Denture',
      targetCount: 4,
      completedCount: 2,
    );

    const testReq2 = Requirement(
      id: 'req-rpd-15',
      clinicId: 'clinic-pros-15',
      title: 'Removable Partial Denture',
      targetCount: 6,
      completedCount: 1,
    );

    testWidgets('EditClinicModal pre-fills values and saves updated clinic', (WidgetTester tester) async {
      final mockClinicRepo = MockClinicRepository();
      mockClinicRepo.clinics.add(testClinic);

      Clinic? updatedResult;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicRepositoryProvider.overrideWithValue(mockClinicRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    updatedResult = await EditClinicModal.show(context, clinic: testClinic);
                  },
                  child: const Text('Open Edit Clinic'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Edit Clinic'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Clinic'), findsOneWidget);
      expect(find.text('Prosthodontics Dept'), findsOneWidget);

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Advanced Prosthodontics');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(mockClinicRepo.lastUpdatedClinic, isNotNull);
      expect(mockClinicRepo.lastUpdatedClinic!.name, equals('Advanced Prosthodontics'));
      expect(updatedResult?.name, equals('Advanced Prosthodontics'));
    });

    testWidgets('EditRequirementModal pre-fills values and saves updated requirement', (WidgetTester tester) async {
      final mockReqRepo = MockRequirementRepository();
      mockReqRepo.requirements.add(testReq1);

      Requirement? updatedResult;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            requirementRepositoryProvider.overrideWithValue(mockReqRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    updatedResult = await EditRequirementModal.show(context, requirement: testReq1);
                  },
                  child: const Text('Open Edit Requirement'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Edit Requirement'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Requirement'), findsOneWidget);
      expect(find.text('Complete Denture'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'Special Complete Denture');
      await tester.enterText(textFields.last, '8');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(mockReqRepo.lastUpdatedRequirement, isNotNull);
      expect(mockReqRepo.lastUpdatedRequirement!.title, equals('Special Complete Denture'));
      expect(mockReqRepo.lastUpdatedRequirement!.targetCount, equals(8));
      expect(updatedResult?.title, equals('Special Complete Denture'));
      expect(updatedResult?.targetCount, equals(8));
    });

    testWidgets('SortClinicCasesModal allows selecting sorting criteria', (WidgetTester tester) async {
      ClinicRequirementSortOption? selectedOption;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    selectedOption = await SortClinicCasesModal.show(context, clinicId: testClinic.id);
                  },
                  child: const Text('Open Sort Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sort Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Sort Cases & Requirements'), findsOneWidget);
      expect(find.text('Name (A to Z)'), findsOneWidget);
      expect(find.text('Quota Progress'), findsOneWidget);
      expect(find.text('Target Quota'), findsOneWidget);

      await tester.tap(find.text('Quota Progress'));
      await tester.pumpAndSettle();

      expect(selectedOption, equals(ClinicRequirementSortOption.progress));
    });

    testWidgets('ClinicDetailsScreen 3-dot menu presents Edit Clinic, Sort Cases, and Delete Cases', (WidgetTester tester) async {
      final mockClinicRepo = MockClinicRepository();
      mockClinicRepo.clinics.add(testClinic);

      final mockReqRepo = MockRequirementRepository();
      mockReqRepo.requirements.addAll([testReq1, testReq2]);

      final mockCaseRepo = MockCaseRecordRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicRepositoryProvider.overrideWithValue(mockClinicRepo),
            clinicListProvider.overrideWith((ref) async => mockClinicRepo.clinics),
            requirementRepositoryProvider.overrideWithValue(mockReqRepo),
            requirementsByClinicProvider(testClinic.id).overrideWith((ref) async => mockReqRepo.requirements),
            caseRecordRepositoryProvider.overrideWithValue(mockCaseRepo),
            allCasesProvider.overrideWith((ref) async => <CaseRecord>[]),
            patientListProvider.overrideWith((ref) async => <Patient>[]),
          ],
          child: const MaterialApp(
            home: ClinicDetailsScreen(clinic: testClinic),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap 3-dot popup menu
      final popupFinder = find.byType(PopupMenuButton<String>);
      expect(popupFinder, findsOneWidget);
      await tester.tap(popupFinder);
      await tester.pumpAndSettle();

      // Verify all 3 menu actions are displayed
      expect(find.text('Edit Clinic'), findsOneWidget);
      expect(find.text('Sort Cases'), findsOneWidget);
      expect(find.text('Delete Cases'), findsOneWidget);
    });

    testWidgets('Tapping inline edit icon on RequirementDetailCard opens EditRequirementModal', (WidgetTester tester) async {
      final mockClinicRepo = MockClinicRepository();
      mockClinicRepo.clinics.add(testClinic);

      final mockReqRepo = MockRequirementRepository();
      mockReqRepo.requirements.add(testReq1);

      final mockCaseRepo = MockCaseRecordRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicRepositoryProvider.overrideWithValue(mockClinicRepo),
            clinicListProvider.overrideWith((ref) async => mockClinicRepo.clinics),
            requirementRepositoryProvider.overrideWithValue(mockReqRepo),
            requirementsByClinicProvider(testClinic.id).overrideWith((ref) async => mockReqRepo.requirements),
            caseRecordRepositoryProvider.overrideWithValue(mockCaseRepo),
            allCasesProvider.overrideWith((ref) async => <CaseRecord>[]),
            patientListProvider.overrideWith((ref) async => <Patient>[]),
          ],
          child: const MaterialApp(
            home: ClinicDetailsScreen(clinic: testClinic),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the inline edit button on the requirement card
      final editIconFinder = find.byTooltip('Edit Requirement');
      expect(editIconFinder, findsOneWidget);

      await tester.tap(editIconFinder);
      await tester.pumpAndSettle();

      // Verify EditRequirementModal opened
      expect(find.byType(EditRequirementModal), findsOneWidget);
      expect(find.text('Edit Requirement'), findsOneWidget);
      expect(find.text('Complete Denture'), findsWidgets);
    });

    testWidgets('Delete Cases activates multi-select mode and batch deletes requirements with confirmation', (WidgetTester tester) async {
      final mockClinicRepo = MockClinicRepository();
      mockClinicRepo.clinics.add(testClinic);

      final mockReqRepo = MockRequirementRepository();
      mockReqRepo.requirements.addAll([testReq1, testReq2]);

      final mockCaseRepo = MockCaseRecordRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicRepositoryProvider.overrideWithValue(mockClinicRepo),
            clinicListProvider.overrideWith((ref) async => mockClinicRepo.clinics),
            requirementRepositoryProvider.overrideWithValue(mockReqRepo),
            requirementsByClinicProvider(testClinic.id).overrideWith((ref) async => mockReqRepo.requirements),
            caseRecordRepositoryProvider.overrideWithValue(mockCaseRepo),
            allCasesProvider.overrideWith((ref) async => <CaseRecord>[]),
            patientListProvider.overrideWith((ref) async => <Patient>[]),
          ],
          child: const MaterialApp(
            home: ClinicDetailsScreen(clinic: testClinic),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 3-dot popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap Delete Cases
      await tester.tap(find.text('Delete Cases'));
      await tester.pumpAndSettle();

      // Verify contextual action bar is displayed
      expect(find.text('0 Selected'), findsOneWidget);
      expect(find.text('Select All'), findsOneWidget);

      // Verify CircularCheckboxes are shown for requirements
      final checkboxes = find.byType(CircularCheckbox);
      expect(checkboxes, findsNWidgets(2));

      // Tap first checkbox
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      expect(find.text('1 Selected'), findsOneWidget);

      // Tap Select All
      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();

      expect(find.text('2 Selected'), findsOneWidget);
      expect(find.text('Deselect All'), findsOneWidget);

      // Tap delete icon button in app bar
      final deleteBtnFinder = find.byTooltip('Delete Selected');
      expect(deleteBtnFinder, findsOneWidget);
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      // Verify safety confirmation dialog
      expect(find.text('Delete Selected Requirements?'), findsOneWidget);
      expect(
        find.text(
          'Deleting 2 procedural requirements will permanently remove all associated student case records due to cascade deletion.\n\nThis action cannot be undone. Are you sure you want to proceed?',
        ),
        findsOneWidget,
      );

      // Confirm deletion
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify repository deleteRequirements was invoked with both requirement IDs
      expect(mockReqRepo.lastDeletedIds, containsAll(['req-cd-15', 'req-rpd-15']));
    });
  });
}
