import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/data/database/database_providers.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/domain/repositories/repositories.dart';
import 'package:dentera/presentation/state/state.dart';

class MockPatientRepo implements PatientRepository {
  final List<Patient> _patients = [];

  @override
  Future<void> addPatient(Patient patient) async {
    _patients.add(patient);
  }

  @override
  Future<List<Patient>> getAllPatients() async => List.unmodifiable(_patients);

  @override
  Future<Patient?> getPatientById(String id) async {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updatePatient(Patient patient) async {
    final index = _patients.indexWhere((p) => p.id == patient.id);
    if (index != -1) _patients[index] = patient;
  }

  @override
  Future<void> deletePatient(String id) async {
    _patients.removeWhere((p) => p.id == id);
  }
}

class MockClinicRepo implements ClinicRepository {
  final List<Clinic> _clinics = [
    const Clinic(id: 'c-1', name: 'Prosthodontics', academicYear: '5th Year', colorHex: '#003E6F'),
    const Clinic(id: 'c-2', name: 'Endodontics', academicYear: '5th Year', colorHex: '#006A64'),
  ];

  @override
  Future<void> addClinic(Clinic clinic) async => _clinics.add(clinic);

  @override
  Future<List<Clinic>> getAllClinics() async => List.unmodifiable(_clinics);

  @override
  Future<Clinic?> getClinicById(String id) async {
    try {
      return _clinics.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

class MockRequirementRepo implements RequirementRepository {
  final List<Requirement> _requirements = [
    const Requirement(id: 'r-1', clinicId: 'c-1', title: 'Complete Denture', targetCount: 5, completedCount: 3),
    const Requirement(id: 'r-2', clinicId: 'c-1', title: 'RPD', targetCount: 5, completedCount: 2),
    const Requirement(id: 'r-3', clinicId: 'c-2', title: 'Molar RCT', targetCount: 10, completedCount: 5),
  ];

  @override
  Future<void> addRequirement(Requirement requirement) async => _requirements.add(requirement);

  @override
  Future<List<Requirement>> getAllRequirements() async => List.unmodifiable(_requirements);

  @override
  Future<List<Requirement>> getRequirementsByClinicId(String clinicId) async =>
      _requirements.where((r) => r.clinicId == clinicId).toList();

  @override
  Future<void> updateRequirementProgress(String requirementId, int completedCount) async {}
}

class MockAppointmentRepo implements AppointmentRepository {
  final List<Appointment> _appointments = [];

  @override
  Future<void> addAppointment(Appointment appointment) async => _appointments.add(appointment);

  @override
  Future<List<Appointment>> getAllAppointments() async => List.unmodifiable(_appointments);

  @override
  Future<List<Appointment>> getAppointmentsByDate(DateTime date) async {
    return _appointments.where((a) {
      return a.scheduledDate.year == date.year &&
          a.scheduledDate.month == date.month &&
          a.scheduledDate.day == date.day;
    }).toList();
  }

  @override
  Future<List<Appointment>> getAppointmentsByPatientId(String patientId) async =>
      _appointments.where((a) => a.patientId == patientId).toList();

  @override
  Future<void> updateAppointment(Appointment appointment) async {}

  @override
  Future<void> deleteAppointment(String id) async => _appointments.removeWhere((a) => a.id == id);
}

class MockCaseRecordRepo implements CaseRecordRepository {
  final List<CaseRecord> _cases = [];

  @override
  Future<void> addCaseRecord(CaseRecord caseRecord) async => _cases.add(caseRecord);

  @override
  Future<List<CaseRecord>> getAllCaseRecords() async => List.unmodifiable(_cases);

  @override
  Future<List<CaseRecord>> getCaseRecordsByPatientId(String patientId) async =>
      _cases.where((c) => c.patientId == patientId).toList();

  @override
  Future<List<CaseRecord>> getCaseRecordsByRequirementId(String requirementId) async =>
      _cases.where((c) => c.requirementId == requirementId).toList();

  @override
  Future<void> updateCaseRecord(CaseRecord caseRecord) async {}

  @override
  Future<void> deleteCaseRecord(String id) async => _cases.removeWhere((c) => c.id == id);
}

void main() {
  group('Phase 7.1 State Injection & Reactive Provider Tests', () {
    late ProviderContainer container;
    late MockPatientRepo mockPatientRepo;
    late MockClinicRepo mockClinicRepo;
    late MockRequirementRepo mockRequirementRepo;
    late MockAppointmentRepo mockAppointmentRepo;
    late MockCaseRecordRepo mockCaseRecordRepo;

    setUp(() {
      mockPatientRepo = MockPatientRepo();
      mockClinicRepo = MockClinicRepo();
      mockRequirementRepo = MockRequirementRepo();
      mockAppointmentRepo = MockAppointmentRepo();
      mockCaseRecordRepo = MockCaseRecordRepo();

      container = ProviderContainer(
        overrides: [
          patientRepositoryProvider.overrideWithValue(mockPatientRepo),
          clinicRepositoryProvider.overrideWithValue(mockClinicRepo),
          requirementRepositoryProvider.overrideWithValue(mockRequirementRepo),
          appointmentRepositoryProvider.overrideWithValue(mockAppointmentRepo),
          caseRecordRepositoryProvider.overrideWithValue(mockCaseRecordRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('patientListProvider & filteredPatientListProvider reactivity', () async {
      // 1. Initial empty state
      final initialPatients = await container.read(patientListProvider.future);
      expect(initialPatients, isEmpty);

      // 2. Add patient to repository & invalidate
      final newPatient = Patient(
        id: 'PT-99',
        name: 'Fatima Zahra',
        age: 26,
        gender: 'Female',
        createdAt: DateTime.now(),
      );
      await mockPatientRepo.addPatient(newPatient);
      container.invalidate(patientListProvider);

      final updatedPatients = await container.read(patientListProvider.future);
      expect(updatedPatients.length, 1);
      expect(updatedPatients.first.name, 'Fatima Zahra');

      // 3. Test filtered patient search query
      container.read(patientSearchQueryProvider.notifier).state = 'Fatima';
      final filteredAsync = container.read(filteredPatientListProvider);
      expect(filteredAsync.value?.length, 1);

      container.read(patientSearchQueryProvider.notifier).state = 'NonExistent';
      final emptyFilteredAsync = container.read(filteredPatientListProvider);
      expect(emptyFilteredAsync.value, isEmpty);
    });

    test('clinics and requirements providers calculation', () async {
      final clinics = await container.read(clinicListProvider.future);
      expect(clinics.length, 2);

      final clinic1Reqs = await container.read(requirementsByClinicProvider('c-1').future);
      expect(clinic1Reqs.length, 2);

      final allReqs = await container.read(allRequirementsProvider.future);
      expect(allReqs.length, 3);

      final quotaStats = container.read(globalQuotaSummaryProvider);
      // Total: (5+5+10) = 20, Completed: (3+2+5) = 10 -> 50%
      expect(quotaStats.value?.totalTarget, 20);
      expect(quotaStats.value?.totalCompleted, 10);
      expect(quotaStats.value?.progressFraction, 0.5);
    });

    test('dailyAppointmentsProvider and casesByPatientProvider reactivity', () async {
      final testDate = DateTime(2026, 9, 5);
      final apt = Appointment(
        id: 'a-1',
        patientId: 'PT-99',
        clinicId: 'c-1',
        scheduledDate: DateTime(2026, 9, 5, 10, 0),
        procedureDescription: 'Crown Prep',
      );
      await mockAppointmentRepo.addAppointment(apt);

      final dailyApts = await container.read(dailyAppointmentsProvider(testDate).future);
      expect(dailyApts.length, 1);
      expect(dailyApts.first.procedureDescription, 'Crown Prep');

      final newCase = CaseRecord(
        id: 'cr-1',
        patientId: 'PT-99',
        requirementId: 'r-1',
        status: 'In Progress',
        dateStarted: DateTime(2026, 9, 5),
      );
      await mockCaseRecordRepo.addCaseRecord(newCase);

      final patientCases = await container.read(casesByPatientProvider('PT-99').future);
      expect(patientCases.length, 1);
      expect(patientCases.first.id, 'cr-1');
    });
  });
}
