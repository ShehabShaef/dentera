import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/state/state.dart';

/// Unit tests validating [filteredPatientListProvider] category and relational filtering logic.
void main() {
  group('filteredPatientListProvider Unit Tests', () {
    final now = DateTime(2026, 9, 1);

    final testPatients = <Patient>[
      Patient(
        id: 'pt-1',
        name: 'Sara Ahmed',
        age: 23,
        gender: 'Female',
        phoneNumber: '+967-771111111',
        createdAt: now,
      ),
      Patient(
        id: 'pt-2',
        name: 'Omar Khalid',
        age: 45,
        gender: 'Male',
        phoneNumber: '+967-772222222',
        createdAt: now,
      ),
      Patient(
        id: 'pt-3',
        name: 'Lina Mahmoud',
        age: 19,
        gender: 'Female',
        phoneNumber: '+967-773333333',
        createdAt: now,
      ),
    ];

    final testClinics = <Clinic>[
      const Clinic(
        id: 'c-prosth',
        name: 'Prosthodontics',
        academicYear: '5th Year',
        colorHex: '#003E6F',
      ),
      const Clinic(
        id: 'c-endo',
        name: 'Endodontics',
        academicYear: '5th Year',
        colorHex: '#1E568C',
      ),
    ];

    final testRequirements = <Requirement>[
      const Requirement(
        id: 'req-cd',
        clinicId: 'c-prosth',
        title: 'Complete Denture',
        targetCount: 2,
        completedCount: 1,
      ),
      const Requirement(
        id: 'req-rct',
        clinicId: 'c-endo',
        title: 'Root Canal Treatment',
        targetCount: 3,
        completedCount: 2,
      ),
    ];

    final testCases = <CaseRecord>[
      CaseRecord(
        id: 'case-1',
        patientId: 'pt-1',
        requirementId: 'req-cd',
        status: 'In Progress',
        notes: 'Maxillary complete denture impression',
        dateStarted: now,
      ),
      CaseRecord(
        id: 'case-2',
        patientId: 'pt-2',
        requirementId: 'req-rct',
        status: 'Completed',
        notes: 'Tooth 46 obturation complete',
        dateStarted: now,
        dateCompleted: now.add(const Duration(days: 2)),
      ),
    ];

    ProviderContainer createTestContainer({
      List<Patient>? patients,
      List<Clinic>? clinics,
      List<Requirement>? requirements,
      List<CaseRecord>? cases,
    }) {
      return ProviderContainer(
        overrides: [
          patientListProvider.overrideWith((ref) => patients ?? testPatients),
          clinicListProvider.overrideWith((ref) => clinics ?? testClinics),
          allRequirementsProvider.overrideWith((ref) => requirements ?? testRequirements),
          allCasesProvider.overrideWith((ref) => cases ?? testCases),
        ],
      );
    }

    test('returns all patients when category is "All" and search query is empty', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      final result = container.read(filteredPatientListProvider);

      expect(result.hasValue, isTrue);
      final patients = result.value!;
      expect(patients, hasLength(3));
      expect(patients.map((p) => p.name), containsAll(['Sara Ahmed', 'Omar Khalid', 'Lina Mahmoud']));
    });

    test('filters roster by search query across name, phone, and patient ID', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      // Search by name
      container.read(patientSearchQueryProvider.notifier).state = 'sara';
      var result = container.read(filteredPatientListProvider);
      expect(result.value!, hasLength(1));
      expect(result.value!.first.name, equals('Sara Ahmed'));

      // Search by phone number
      container.read(patientSearchQueryProvider.notifier).state = '772222222';
      result = container.read(filteredPatientListProvider);
      expect(result.value!, hasLength(1));
      expect(result.value!.first.name, equals('Omar Khalid'));

      // Search by patient ID
      container.read(patientSearchQueryProvider.notifier).state = 'pt-3';
      result = container.read(filteredPatientListProvider);
      expect(result.value!, hasLength(1));
      expect(result.value!.first.name, equals('Lina Mahmoud'));

      // Search with non-matching query
      container.read(patientSearchQueryProvider.notifier).state = 'nonexistent';
      result = container.read(filteredPatientListProvider);
      expect(result.value!, isEmpty);
    });

    test('filters roster by "Active Cases" category', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(patientFilterCategoryProvider.notifier).state = 'Active Cases';
      final result = container.read(filteredPatientListProvider);

      expect(result.hasValue, isTrue);
      final patients = result.value!;
      // Only pt-1 (Sara Ahmed) has an in-progress case
      expect(patients, hasLength(1));
      expect(patients.first.name, equals('Sara Ahmed'));
    });

    test('filters roster by "Completed" category', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(patientFilterCategoryProvider.notifier).state = 'Completed';
      final result = container.read(filteredPatientListProvider);

      expect(result.hasValue, isTrue);
      final patients = result.value!;
      // Only pt-2 (Omar Khalid) has a completed case
      expect(patients, hasLength(1));
      expect(patients.first.name, equals('Omar Khalid'));
    });

    test('filters roster by specific clinic department category', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      // Filter by Prosthodontics (linked to pt-1 via req-cd)
      container.read(patientFilterCategoryProvider.notifier).state = 'Prosthodontics';
      var result = container.read(filteredPatientListProvider);
      expect(result.value!, hasLength(1));
      expect(result.value!.first.name, equals('Sara Ahmed'));

      // Filter by Endodontics (linked to pt-2 via req-rct)
      container.read(patientFilterCategoryProvider.notifier).state = 'Endodontics';
      result = container.read(filteredPatientListProvider);
      expect(result.value!, hasLength(1));
      expect(result.value!.first.name, equals('Omar Khalid'));

      // Filter by department with no cases (Oral Surgery)
      container.read(patientFilterCategoryProvider.notifier).state = 'Oral Surgery';
      result = container.read(filteredPatientListProvider);
      expect(result.value!, isEmpty);
    });

    test('combines category filter and search query correctly', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(patientFilterCategoryProvider.notifier).state = 'Active Cases';

      // Search for 'omar' under Active Cases (Omar has only Completed cases, so should be empty)
      container.read(patientSearchQueryProvider.notifier).state = 'omar';
      var result = container.read(filteredPatientListProvider);
      expect(result.value!, isEmpty);

      // Search for 'sara' under Active Cases (Sara has Active case)
      container.read(patientSearchQueryProvider.notifier).state = 'sara';
      result = container.read(filteredPatientListProvider);
      expect(result.value!, hasLength(1));
      expect(result.value!.first.name, equals('Sara Ahmed'));
    });
  });
}
