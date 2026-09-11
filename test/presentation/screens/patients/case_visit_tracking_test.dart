import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/database/database_providers.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/domain/repositories/case_record_repository.dart';
import 'package:dentera/domain/repositories/case_visit_repository.dart';
import 'package:dentera/domain/repositories/clinic_repository.dart';
import 'package:dentera/domain/repositories/patient_repository.dart';
import 'package:dentera/domain/repositories/requirement_repository.dart';
import 'package:dentera/presentation/screens/patients/widgets/case_record_card.dart';
import 'package:dentera/presentation/widgets/case_visits/case_visit_timeline_widget.dart';
import 'package:dentera/presentation/widgets/modals/evaluate_case_modal.dart';
import 'package:dentera/presentation/widgets/modals/log_case_record_modal.dart';

class MockCaseVisitRepository implements CaseVisitRepository {
  final List<CaseVisit> visits = [];

  @override
  Future<void> addCaseVisit(CaseVisit caseVisit) async {
    visits.removeWhere((v) => v.id == caseVisit.id);
    visits.add(caseVisit);
  }

  @override
  Future<void> addCaseVisits(List<CaseVisit> caseVisits) async {
    for (final v in caseVisits) {
      await addCaseVisit(v);
    }
  }

  @override
  Future<void> updateCaseVisit(CaseVisit caseVisit) async {
    final idx = visits.indexWhere((v) => v.id == caseVisit.id);
    if (idx != -1) {
      visits[idx] = caseVisit;
    }
  }

  @override
  Future<void> deleteCaseVisit(String id) async {
    visits.removeWhere((v) => v.id == id);
  }

  @override
  Future<List<CaseVisit>> getVisitsByCaseRecordId(String caseRecordId) async {
    final filtered = visits.where((v) => v.caseRecordId == caseRecordId).toList();
    filtered.sort((a, b) => a.visitNumber.compareTo(b.visitNumber));
    return filtered;
  }

  @override
  Future<List<CaseVisit>> getAllVisits() async {
    final copy = List<CaseVisit>.from(visits);
    copy.sort((a, b) => a.visitNumber.compareTo(b.visitNumber));
    return copy;
  }
}

class MockCaseRecordRepository implements CaseRecordRepository {
  final List<CaseRecord> cases = [];

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
    cases.removeWhere((c) => c.id == id);
  }
}

class MockClinicRepository implements ClinicRepository {
  final List<Clinic> clinics = [];

  @override
  Future<void> addClinic(Clinic clinic) async => clinics.add(clinic);

  @override
  Future<List<Clinic>> getAllClinics() async => List.from(clinics);

  @override
  Future<Clinic?> getClinicById(String id) async =>
      clinics.where((c) => c.id == id).firstOrNull;

  @override
  Future<void> updateClinic(Clinic clinic) async {}

  @override
  Future<void> deleteClinic(String id) async {}

  @override
  Future<void> deleteClinics(List<String> ids) async {}
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
  Future<void> updateRequirement(Requirement requirement) async {}

  @override
  Future<void> updateRequirementProgress(String requirementId, int completedCount) async {}

  @override
  Future<void> deleteRequirement(String id) async {}

  @override
  Future<void> deleteRequirements(List<String> ids) async {}
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
  Future<void> updatePatient(Patient patient) async {}

  @override
  Future<void> deletePatient(String id) async {}

  @override
  Future<void> deletePatients(List<String> ids) async {}
}

void main() {
  late MockCaseVisitRepository mockVisitRepo;
  late MockCaseRecordRepository mockCaseRepo;
  late MockClinicRepository mockClinicRepo;
  late MockRequirementRepository mockReqRepo;
  late MockPatientRepository mockPatientRepo;

  setUp(() {
    mockVisitRepo = MockCaseVisitRepository();
    mockCaseRepo = MockCaseRecordRepository();
    mockClinicRepo = MockClinicRepository();
    mockReqRepo = MockRequirementRepository();
    mockPatientRepo = MockPatientRepository();
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        caseVisitRepositoryProvider.overrideWithValue(mockVisitRepo),
        caseRecordRepositoryProvider.overrideWithValue(mockCaseRepo),
        clinicRepositoryProvider.overrideWithValue(mockClinicRepo),
        requirementRepositoryProvider.overrideWithValue(mockReqRepo),
        patientRepositoryProvider.overrideWithValue(mockPatientRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: child),
      ),
    );
  }

  group('Multi-Visit Tracking & Case Visits (Issue #17)', () {
    testWidgets('CaseRecordCard displays step indicator "Visit 2 of 4" when visits are logged', (tester) async {
      const caseId = 'case-test-visits-1';
      final testCase = CaseRecord(
        id: caseId,
        patientId: 'p-1',
        requirementId: 'req-1',
        status: 'In Progress',
        dateStarted: DateTime(2026, 9, 1),
      );

      mockVisitRepo.visits.addAll([
        const CaseVisit(
          id: 'v1',
          caseRecordId: caseId,
          visitNumber: 1,
          title: 'Primary Impression',
          status: 'Completed',
        ),
        const CaseVisit(
          id: 'v2',
          caseRecordId: caseId,
          visitNumber: 2,
          title: 'Final Impression',
          status: 'Completed',
        ),
        const CaseVisit(
          id: 'v3',
          caseRecordId: caseId,
          visitNumber: 3,
          title: 'Jaw Relation',
          status: 'Pending',
        ),
        const CaseVisit(
          id: 'v4',
          caseRecordId: caseId,
          visitNumber: 4,
          title: 'Delivery',
          status: 'Pending',
        ),
      ]);

      await tester.pumpWidget(
        buildTestableWidget(
          CaseRecordCard(
            caseRecord: testCase,
            requirementTitle: 'Complete Denture',
            clinicName: 'Prosthodontics',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step indicator must display "Visit 2 of 4"
      expect(find.text('Visit 2 of 4'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('LogCaseRecordModal allows specifying planned number of visits and labeling them', (tester) async {
      mockClinicRepo.clinics.add(
        const Clinic(id: 'c-prosth', name: 'Prosthodontics', academicYear: '5th Year', colorHex: '#003E6F'),
      );
      mockReqRepo.requirements.add(
        const Requirement(id: 'req-cd', clinicId: 'c-prosth', title: 'Complete Denture', targetCount: 2, completedCount: 0),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => LogCaseRecordModal.show(context, patientId: 'patient-123'),
              child: const Text('Open Modal'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Planned Number of Visits (1-10)'), findsOneWidget);
      expect(find.text('Visit 1 Label'), findsOneWidget);

      // Change planned visits to 3
      await tester.tap(find.text('1 Visit'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('3 Visits').last);
      await tester.pumpAndSettle();

      expect(find.text('Visit 1 Label'), findsOneWidget);
      expect(find.text('Visit 2 Label'), findsOneWidget);
      expect(find.text('Visit 3 Label'), findsOneWidget);

      // Customize label for Visit 2
      final visit2Field = find.widgetWithText(TextField, 'Visit 2');
      await tester.enterText(visit2Field, 'Border Molding & Secondary Impression');
      await tester.pumpAndSettle();

      // Submit the form
      await tester.ensureVisible(find.text('Log Case Record'));
      await tester.tap(find.text('Log Case Record'));
      await tester.pumpAndSettle();

      // Verify visits were saved to repository
      expect(mockCaseRepo.cases, hasLength(1));
      final createdCaseId = mockCaseRepo.cases.first.id;

      final savedVisits = await mockVisitRepo.getVisitsByCaseRecordId(createdCaseId);
      expect(savedVisits, hasLength(3));
      expect(savedVisits[0].visitNumber, equals(1));
      expect(savedVisits[0].title, equals('Visit 1'));
      expect(savedVisits[1].visitNumber, equals(2));
      expect(savedVisits[1].title, equals('Border Molding & Secondary Impression'));
      expect(savedVisits[2].visitNumber, equals(3));
    });

    testWidgets('EvaluateCaseModal embeds CaseVisitTimelineWidget and marks visit completed with notes', (tester) async {
      const caseId = 'case-eval-test-1';
      final testCase = CaseRecord(
        id: caseId,
        patientId: 'patient-1',
        requirementId: 'req-eval-1',
        status: 'In Progress',
        dateStarted: DateTime(2026, 9, 5),
      );

      mockVisitRepo.visits.addAll([
        const CaseVisit(
          id: 'vis-1',
          caseRecordId: caseId,
          visitNumber: 1,
          title: 'Diagnostic Casts',
          status: 'Completed',
          notes: 'Alginate taken with stock trays',
        ),
        const CaseVisit(
          id: 'vis-2',
          caseRecordId: caseId,
          visitNumber: 2,
          title: 'Custom Tray Try-in',
          status: 'Pending',
        ),
      ]);

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => EvaluateCaseModal.show(
                context,
                caseRecord: testCase,
                patientName: 'Test Patient',
                procedureTitle: 'Prosthodontic Case',
              ),
              child: const Text('Evaluate Case'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Evaluate Case'));
      await tester.pumpAndSettle();

      // Verify CaseVisitTimelineWidget is visible
      expect(find.byType(CaseVisitTimelineWidget), findsOneWidget);
      expect(find.text('Clinical Visit Milestones'), findsOneWidget);
      expect(find.text('Visit 1 of 2'), findsOneWidget);
      expect(find.text('Diagnostic Casts'), findsOneWidget);
      expect(find.text('Custom Tray Try-in'), findsOneWidget);

      // Visit 1 notes should be displayed
      expect(find.text('Alginate taken with stock trays'), findsOneWidget);

      // Complete button for visit 2 should be present
      final completeBtn = find.widgetWithText(TextButton, 'Complete');
      expect(completeBtn, findsOneWidget);

      await tester.tap(completeBtn);
      await tester.pumpAndSettle();

      // Dialog opens for completing Visit 2
      expect(find.text('Complete Visit 2'), findsOneWidget);

      // Enter clinical notes
      final notesField = find.widgetWithText(TextField, 'Enter clinical observations, findings, materials used...');
      expect(notesField, findsOneWidget);
      await tester.enterText(notesField, 'Green stick compound used for border molding');
      await tester.pumpAndSettle();

      // Tap Mark Completed button
      await tester.tap(find.text('Mark Completed'));
      await tester.pumpAndSettle();

      // Check visit 2 is now marked Completed in repository
      final updatedVisits = await mockVisitRepo.getVisitsByCaseRecordId(caseId);
      final v2 = updatedVisits.firstWhere((v) => v.id == 'vis-2');
      expect(v2.status, equals('Completed'));
      expect(v2.notes, equals('Green stick compound used for border molding'));
      expect(v2.dateCompleted, isNotNull);
    });
  });
}
