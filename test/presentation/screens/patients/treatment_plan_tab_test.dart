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
import 'package:dentera/domain/repositories/treatment_plan_repository.dart';
import 'package:dentera/presentation/screens/patients/patient_case_sheet_screen.dart';
import 'package:dentera/presentation/screens/patients/widgets/treatment_plan_tab.dart';
import 'package:dentera/presentation/widgets/modals/add_treatment_plan_modal.dart';
import 'package:dentera/presentation/widgets/modals/log_case_record_modal.dart';

class MockTreatmentPlanRepository implements TreatmentPlanRepository {
  final List<TreatmentPlan> plans = [];

  @override
  Future<void> addTreatmentPlan(TreatmentPlan plan) async {
    plans.removeWhere((p) => p.id == plan.id);
    plans.add(plan);
  }

  @override
  Future<void> updateTreatmentPlan(TreatmentPlan plan) async {
    final idx = plans.indexWhere((p) => p.id == plan.id);
    if (idx != -1) {
      plans[idx] = plan;
    }
  }

  @override
  Future<void> deleteTreatmentPlan(String id) async {
    plans.removeWhere((p) => p.id == id);
  }

  @override
  Future<TreatmentPlan?> getTreatmentPlanById(String id) async {
    return plans.where((p) => p.id == id).firstOrNull;
  }

  @override
  Future<List<TreatmentPlan>> getTreatmentPlansByPatient(String patientId) async {
    final res = plans.where((p) => p.patientId == patientId).toList();
    res.sort((a, b) {
      final pCmp = a.phase.compareTo(b.phase);
      if (pCmp != 0) return pCmp;
      return a.createdAt.compareTo(b.createdAt);
    });
    return res;
  }

  @override
  Future<List<TreatmentPlan>> getAllTreatmentPlans() async {
    final copy = List<TreatmentPlan>.from(plans);
    copy.sort((a, b) => a.phase.compareTo(b.phase));
    return copy;
  }
}

class MockClinicRepository implements ClinicRepository {
  final List<Clinic> clinics = [
    const Clinic(
      id: 'clinic-endo',
      name: 'Endodontics',
      academicYear: '5th Year',
      colorHex: '#2E3F50',
    ),
    const Clinic(
      id: 'clinic-perio',
      name: 'Periodontics',
      academicYear: '5th Year',
      colorHex: '#006A64',
    ),
    const Clinic(
      id: 'clinic-op',
      name: 'Operative Dentistry',
      academicYear: '5th Year',
      colorHex: '#003E6F',
    ),
  ];

  @override
  Future<List<Clinic>> getAllClinics() async => clinics;

  @override
  Future<Clinic?> getClinicById(String id) async =>
      clinics.where((c) => c.id == id).firstOrNull;

  @override
  Future<void> addClinic(Clinic clinic) async => clinics.add(clinic);

  @override
  Future<void> updateClinic(Clinic clinic) async {}

  @override
  Future<void> deleteClinic(String id) async => clinics.removeWhere((c) => c.id == id);

  @override
  Future<void> deleteClinics(List<String> ids) async =>
      clinics.removeWhere((c) => ids.contains(c.id));
}

class MockRequirementRepository implements RequirementRepository {
  final List<Requirement> requirements = [
    const Requirement(
      id: 'req-endo-1',
      clinicId: 'clinic-endo',
      title: 'Anterior RCT',
      targetCount: 3,
      completedCount: 0,
    ),
    const Requirement(
      id: 'req-perio-1',
      clinicId: 'clinic-perio',
      title: 'Scaling & Root Planing',
      targetCount: 5,
      completedCount: 0,
    ),
  ];

  @override
  Future<List<Requirement>> getAllRequirements() async => requirements;

  @override
  Future<List<Requirement>> getRequirementsByClinicId(String clinicId) async =>
      requirements.where((r) => r.clinicId == clinicId).toList();

  @override
  Future<void> addRequirement(Requirement requirement) async => requirements.add(requirement);

  @override
  Future<void> updateRequirement(Requirement requirement) async {}

  @override
  Future<void> updateRequirementProgress(String requirementId, int completedCount) async {}

  @override
  Future<void> deleteRequirement(String id) async =>
      requirements.removeWhere((r) => r.id == id);

  @override
  Future<void> deleteRequirements(List<String> ids) async =>
      requirements.removeWhere((r) => ids.contains(r.id));
}

class MockCaseRecordRepository implements CaseRecordRepository {
  final List<CaseRecord> cases = [];

  @override
  Future<List<CaseRecord>> getAllCaseRecords() async => cases;

  @override
  Future<List<CaseRecord>> getCaseRecordsByPatientId(String patientId) async =>
      cases.where((c) => c.patientId == patientId).toList();

  @override
  Future<List<CaseRecord>> getCaseRecordsByRequirementId(String requirementId) async =>
      cases.where((c) => c.requirementId == requirementId).toList();


  @override
  Future<void> addCaseRecord(CaseRecord caseRecord) async => cases.add(caseRecord);

  @override
  Future<void> updateCaseRecord(CaseRecord caseRecord) async {}

  @override
  Future<void> deleteCaseRecord(String id) async => cases.removeWhere((c) => c.id == id);
}

class MockCaseVisitRepository implements CaseVisitRepository {
  final List<CaseVisit> visits = [];

  @override
  Future<void> addCaseVisit(CaseVisit caseVisit) async => visits.add(caseVisit);

  @override
  Future<void> addCaseVisits(List<CaseVisit> caseVisits) async => visits.addAll(caseVisits);

  @override
  Future<void> updateCaseVisit(CaseVisit caseVisit) async {}

  @override
  Future<void> deleteCaseVisit(String id) async => visits.removeWhere((v) => v.id == id);

  @override
  Future<List<CaseVisit>> getVisitsByCaseRecordId(String caseRecordId) async =>
      visits.where((v) => v.caseRecordId == caseRecordId).toList();

  @override
  Future<List<CaseVisit>> getAllVisits() async => visits;
}

class MockPatientRepository implements PatientRepository {
  final List<Patient> patients = [];

  @override
  Future<List<Patient>> getAllPatients() async => patients;

  @override
  Future<Patient?> getPatientById(String id) async =>
      patients.where((p) => p.id == id).firstOrNull;

  @override
  Future<void> addPatient(Patient patient) async => patients.add(patient);

  @override
  Future<void> updatePatient(Patient patient) async {}

  @override
  Future<void> deletePatient(String id) async => patients.removeWhere((p) => p.id == id);

  @override
  Future<void> deletePatients(List<String> ids) async =>
      patients.removeWhere((p) => ids.contains(p.id));

}

void main() {
  late MockTreatmentPlanRepository mockPlanRepo;
  late MockClinicRepository mockClinicRepo;
  late MockRequirementRepository mockReqRepo;
  late MockCaseRecordRepository mockCaseRepo;
  late MockCaseVisitRepository mockVisitRepo;
  late MockPatientRepository mockPatientRepo;

  final testPatient = Patient(
    id: 'pt-staging-001',
    name: 'Ahmed Mansoor',
    age: 29,
    gender: 'Male',
    phoneNumber: '777-123-456',
    medicalHistory: 'None',
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockPlanRepo = MockTreatmentPlanRepository();
    mockClinicRepo = MockClinicRepository();
    mockReqRepo = MockRequirementRepository();
    mockCaseRepo = MockCaseRecordRepository();
    mockVisitRepo = MockCaseVisitRepository();
    mockPatientRepo = MockPatientRepository();
    mockPatientRepo.addPatient(testPatient);
  });

  Widget buildTestableApp({Widget? child}) {
    return ProviderScope(
      overrides: [
        treatmentPlanRepositoryProvider.overrideWithValue(mockPlanRepo),
        clinicRepositoryProvider.overrideWithValue(mockClinicRepo),
        requirementRepositoryProvider.overrideWithValue(mockReqRepo),
        caseRecordRepositoryProvider.overrideWithValue(mockCaseRepo),
        caseVisitRepositoryProvider.overrideWithValue(mockVisitRepo),
        patientRepositoryProvider.overrideWithValue(mockPatientRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child ?? Scaffold(body: TreatmentPlanTab(patient: testPatient)),
      ),
    );
  }

  group('TreatmentPlanTab & Phased Care Staging Tests', () {
    testWidgets('renders zero state when no treatment plan items exist', (tester) async {
      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      expect(find.text('No Treatment Plan Staged'), findsOneWidget);
      expect(find.text('Stage Proposed Treatment'), findsOneWidget);
    });

    testWidgets('tapping Stage Proposed Treatment opens modal and adds treatment item', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Stage Proposed Treatment'));
      await tester.pumpAndSettle();

      expect(find.byType(AddTreatmentPlanModal), findsOneWidget);
      expect(find.text('Stage Proposed Treatment'), findsWidgets);

      // Enter treatment procedure title
      final titleField = find.widgetWithText(TextFormField, '');
      await tester.enterText(titleField.first, 'Emergency Pulpotomy #46');
      await tester.pumpAndSettle();

      // Tap submit button
      final submitButton = find.text('Stage Treatment');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify item now renders under Phase 1
      expect(find.text('Emergency Pulpotomy #46'), findsOneWidget);
      expect(find.text('Phase 1: Emergency'), findsOneWidget);
      expect(find.text('Proposed'), findsOneWidget);
      expect(mockPlanRepo.plans, hasLength(1));
    });

    testWidgets('renders grouped academic phases with summary pills', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      mockPlanRepo.plans.addAll([
        TreatmentPlan(
          id: 'tp-1',
          patientId: testPatient.id,
          phase: 1,
          title: 'Acute Abscess Drainage',
          status: TreatmentPlan.statusProposed,
          targetClinicId: 'clinic-endo',
          createdAt: DateTime.now(),
        ),
        TreatmentPlan(
          id: 'tp-2',
          patientId: testPatient.id,
          phase: 2,
          title: 'Full Mouth Scaling',
          status: TreatmentPlan.statusApproved,
          targetClinicId: 'clinic-perio',
          createdAt: DateTime.now(),
        ),
        TreatmentPlan(
          id: 'tp-3',
          patientId: testPatient.id,
          phase: 3,
          title: 'Direct Composite Restoration #11',
          status: TreatmentPlan.statusConverted,
          targetClinicId: 'clinic-op',
          createdAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      // Summary Header assertions
      expect(find.text('Phased Treatment Plan'), findsOneWidget);
      expect(find.text('3 Planned'), findsOneWidget);
      expect(find.text('1 Approved'), findsOneWidget);
      expect(find.text('1 Active Cases'), findsOneWidget);

      // Verify phases rendered
      expect(find.text('Phase 1: Emergency'), findsOneWidget);
      expect(find.text('Phase 2: Preventive / Perio'), findsOneWidget);
      expect(find.text('Phase 3: Restorative'), findsOneWidget);
      expect(find.text('Phase 4: Maintenance'), findsOneWidget);

      // Verify item titles
      expect(find.text('Acute Abscess Drainage'), findsOneWidget);
      expect(find.text('Full Mouth Scaling'), findsOneWidget);
      expect(find.text('Direct Composite Restoration #11'), findsOneWidget);
    });

    testWidgets('tapping Approve button marks proposed treatment as Approved', (tester) async {
      mockPlanRepo.plans.add(
        TreatmentPlan(
          id: 'tp-approve-1',
          patientId: testPatient.id,
          phase: 1,
          title: 'Urgent Trephination',
          status: TreatmentPlan.statusProposed,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      expect(find.text('Proposed'), findsOneWidget);

      // Tap Approve button
      final approveBtn = find.widgetWithText(OutlinedButton, 'Approve');
      expect(approveBtn, findsOneWidget);
      await tester.tap(approveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Approved'), findsOneWidget);
      expect(mockPlanRepo.plans.first.status, equals(TreatmentPlan.statusApproved));
    });

    testWidgets('tapping Convert to Case launches LogCaseRecordModal and marks plan as Converted', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      mockPlanRepo.plans.add(
        TreatmentPlan(
          id: 'tp-convert-1',
          patientId: testPatient.id,
          phase: 2,
          title: 'Scaling & Root Planing Upper',
          status: TreatmentPlan.statusApproved,
          targetClinicId: 'clinic-perio',
          notes: 'Generalized moderate periodontitis',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      // Tap Convert to Case
      final convertBtn = find.widgetWithText(FilledButton, 'Convert to Case');
      expect(convertBtn, findsOneWidget);
      await tester.tap(convertBtn);
      await tester.pumpAndSettle();

      // Modal should be displayed
      expect(find.byType(LogCaseRecordModal), findsOneWidget);

      // Submit case logging
      final saveBtn = find.text('Log Case Record');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify status is now Converted and active case indicator is shown
      expect(find.text('Active Case Created'), findsOneWidget);
      expect(mockPlanRepo.plans.first.status, equals(TreatmentPlan.statusConverted));
      expect(mockCaseRepo.cases, hasLength(1));
    });

    testWidgets('deleting treatment plan item removes it from list', (tester) async {
      mockPlanRepo.plans.add(
        TreatmentPlan(
          id: 'tp-del-1',
          patientId: testPatient.id,
          phase: 3,
          title: 'Porcelain Veneer #21',
          status: TreatmentPlan.statusProposed,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      expect(find.text('Porcelain Veneer #21'), findsOneWidget);

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Select Delete Item
      await tester.tap(find.text('Delete Item'));
      await tester.pumpAndSettle();

      // Confirm dialog
      expect(find.text('Delete Treatment Plan Item'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Porcelain Veneer #21'), findsNothing);
      expect(mockPlanRepo.plans, isEmpty);
    });

    testWidgets('PatientCaseSheetScreen renders Treatment Plan tab with full integration', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      mockPlanRepo.plans.add(
        TreatmentPlan(
          id: 'tp-sheet-1',
          patientId: testPatient.id,
          phase: 4,
          title: 'Periodontal Maintenance Recall',
          status: TreatmentPlan.statusApproved,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        buildTestableApp(
          child: PatientCaseSheetScreen(patient: testPatient),
        ),
      );
      await tester.pumpAndSettle();

      // Verify 3 tabs
      expect(find.text('Clinical Cases'), findsOneWidget);
      expect(find.text('Patient History'), findsOneWidget);
      expect(find.text('Treatment Plan'), findsOneWidget);

      // Switch to Treatment Plan tab
      await tester.tap(find.text('Treatment Plan'));
      await tester.pumpAndSettle();

      expect(find.byType(TreatmentPlanTab), findsOneWidget);
      expect(find.text('Periodontal Maintenance Recall'), findsOneWidget);
      expect(find.text('Phase 4: Maintenance'), findsOneWidget);
    });
  });
}
