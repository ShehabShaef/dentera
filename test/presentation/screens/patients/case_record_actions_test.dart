import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/database/database_providers.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/domain/repositories/case_record_repository.dart';
import 'package:dentera/domain/repositories/patient_repository.dart';
import 'package:dentera/domain/repositories/requirement_repository.dart';
import 'package:dentera/presentation/screens/patients/patient_case_sheet_screen.dart';
import 'package:dentera/presentation/screens/patients/widgets/case_record_card.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/modals/evaluate_case_modal.dart';

class MockCaseRecordRepository implements CaseRecordRepository {
  final List<CaseRecord> cases = [];
  String? lastDeletedId;

  @override
  Future<void> addCaseRecord(CaseRecord caseRecord) async => cases.add(caseRecord);

  @override
  Future<List<CaseRecord>> getAllCaseRecords() async => List.from(cases);

  @override
  Future<List<CaseRecord>> getCaseRecordsByPatientId(String patientId) async =>
      cases.where((c) => c.patientId == patientId).toList();

  @override
  Future<List<CaseRecord>> getCaseRecordsByRequirementId(String requirementId) async =>
      cases.where((c) => c.requirementId == requirementId).toList();

  @override
  Future<void> updateCaseRecord(CaseRecord caseRecord) async {
    final idx = cases.indexWhere((c) => c.id == caseRecord.id);
    if (idx != -1) cases[idx] = caseRecord;
  }

  @override
  Future<void> deleteCaseRecord(String id) async {
    lastDeletedId = id;
    cases.removeWhere((c) => c.id == id);
  }
}

class MockRequirementRepository implements RequirementRepository {
  final List<Requirement> requirements = [];

  @override
  Future<void> addRequirement(Requirement requirement) async => requirements.add(requirement);

  @override
  Future<List<Requirement>> getAllRequirements() async => List.from(requirements);

  @override
  Future<List<Requirement>> getRequirementsByClinicId(String clinicId) async =>
      requirements.where((r) => r.clinicId == clinicId).toList();

  @override
  Future<void> updateRequirement(Requirement requirement) async {
    final idx = requirements.indexWhere((r) => r.id == requirement.id);
    if (idx != -1) requirements[idx] = requirement;
  }

  @override
  Future<void> updateRequirementProgress(String requirementId, int completedCount) async {
    final idx = requirements.indexWhere((r) => r.id == requirementId);
    if (idx != -1) {
      requirements[idx] = requirements[idx].copyWith(completedCount: completedCount);
    }
  }

  @override
  Future<void> deleteRequirement(String id) async => requirements.removeWhere((r) => r.id == id);

  @override
  Future<void> deleteRequirements(List<String> ids) async =>
      requirements.removeWhere((r) => ids.contains(r.id));
}

class MockPatientRepository implements PatientRepository {
  final List<Patient> patients = [];

  @override
  Future<void> addPatient(Patient patient) async => patients.add(patient);

  @override
  Future<List<Patient>> getAllPatients() async => List.from(patients);

  @override
  Future<Patient?> getPatientById(String id) async =>
      patients.where((p) => p.id == id).firstOrNull;

  @override
  Future<void> updatePatient(Patient patient) async {
    final idx = patients.indexWhere((p) => p.id == patient.id);
    if (idx != -1) patients[idx] = patient;
  }

  @override
  Future<void> deletePatient(String id) async => patients.removeWhere((p) => p.id == id);

  @override
  Future<void> deletePatients(List<String> ids) async =>
      patients.removeWhere((p) => ids.contains(p.id));
}

void main() {
  group('PatientCaseSheetScreen CaseRecord Actions Tests', () {
    late MockCaseRecordRepository mockCasesRepo;
    late MockRequirementRepository mockReqsRepo;
    late MockPatientRepository mockPatientsRepo;

    final now = DateTime.now();

    final testPatient = Patient(
      id: 'patient-101',
      name: 'Hussein Tariq',
      age: 42,
      gender: 'Male',
      createdAt: now,
    );

    final testClinic = const Clinic(
      id: 'clinic-endo',
      name: 'Endodontics',
      academicYear: '5th Year',
      colorHex: '#1E568C',
    );

    final testRequirement = const Requirement(
      id: 'req-endo-anterior',
      clinicId: 'clinic-endo',
      title: 'Anterior Root Canal',
      targetCount: 5,
      completedCount: 2,
    );

    final testCaseRecord = CaseRecord(
      id: 'case-rec-1',
      patientId: 'patient-101',
      requirementId: 'req-endo-anterior',
      dateStarted: DateTime(2026, 3, 1),
      dateCompleted: DateTime(2026, 3, 5),
      status: 'Completed',
      notes: 'Initial access and instrumentation done smoothly.',
    );

    setUp(() {
      mockCasesRepo = MockCaseRecordRepository();
      mockReqsRepo = MockRequirementRepository();
      mockPatientsRepo = MockPatientRepository();

      mockPatientsRepo.patients.add(testPatient);
      mockReqsRepo.requirements.add(testRequirement);
      mockCasesRepo.cases.add(testCaseRecord);
    });

    Widget createWidget() {
      return ProviderScope(
        overrides: [
          caseRecordRepositoryProvider.overrideWithValue(mockCasesRepo),
          requirementRepositoryProvider.overrideWithValue(mockReqsRepo),
          patientRepositoryProvider.overrideWithValue(mockPatientsRepo),
          allClinicsProvider.overrideWith((ref) async => [testClinic]),
          allRequirementsProvider.overrideWith((ref) async => mockReqsRepo.getAllRequirements()),
          casesByPatientProvider.overrideWith((ref, id) async => mockCasesRepo.getCaseRecordsByPatientId(id)),
          patientByIdProvider.overrideWith((ref, id) async => testPatient),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: PatientCaseSheetScreen(
            patient: testPatient,
          ),
        ),
      );
    }

    testWidgets('Tapping edit action on CaseRecordCard opens EvaluateCaseModal',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CaseRecordCard), findsOneWidget);
      expect(find.text('Anterior Root Canal'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // Open popup menu on CaseRecordCard
      final actionMenu = find.byTooltip('Case actions');
      expect(actionMenu, findsOneWidget);
      await tester.tap(actionMenu);
      await tester.pumpAndSettle();

      // Tap Edit Case
      final editOption = find.text('Edit Case');
      expect(editOption, findsOneWidget);
      await tester.tap(editOption);
      await tester.pumpAndSettle();

      // Verify EvaluateCaseModal opened
      expect(find.byType(EvaluateCaseModal), findsOneWidget);
      expect(find.text('Evaluate Case Record'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(EvaluateCaseModal), matching: find.textContaining('Hussein Tariq')),
        findsOneWidget,
      );
    });

    testWidgets('Tapping delete action shows confirmation dialog and cancels without deletion',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final actionMenu = find.byTooltip('Case actions');
      await tester.tap(actionMenu);
      await tester.pumpAndSettle();

      final deleteOption = find.text('Delete Case');
      expect(deleteOption, findsOneWidget);
      await tester.tap(deleteOption);
      await tester.pumpAndSettle();

      // Confirmation dialog verification
      expect(find.text('Delete Case Record'), findsOneWidget);
      expect(
        find.textContaining('If this case was marked as completed, your requirement completed count will automatically be decremented.'),
        findsOneWidget,
      );

      // Cancel deletion
      final cancelBtn = find.widgetWithText(TextButton, 'Cancel');
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      expect(mockCasesRepo.lastDeletedId, isNull);
      expect(mockCasesRepo.cases.length, 1);
    });

    testWidgets('Confirming delete invokes deleteCaseRecord on repository and removes card',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final actionMenu = find.byTooltip('Case actions');
      await tester.tap(actionMenu);
      await tester.pumpAndSettle();

      final deleteOption = find.text('Delete Case');
      await tester.tap(deleteOption);
      await tester.pumpAndSettle();

      // Confirm delete
      final deleteBtn = find.widgetWithText(TextButton, 'Delete');
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Verify repository delete was invoked
      expect(mockCasesRepo.lastDeletedId, 'case-rec-1');
      expect(mockCasesRepo.cases.isEmpty, isTrue);
    });
  });
}
