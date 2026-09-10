import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/database/database_providers.dart';
import 'package:dentera/domain/constants/dental_catalog.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/domain/repositories/repositories.dart';
import 'package:dentera/presentation/state/dental_catalog_provider.dart';
import 'package:dentera/presentation/widgets/inputs/inputs.dart';
import 'package:dentera/presentation/widgets/modals/add_clinic_modal.dart';
import 'package:dentera/presentation/widgets/modals/add_requirement_modal.dart';

class MockClinicRepository extends Fake implements ClinicRepository {
  Clinic? lastAddedClinic;
  final List<Clinic> clinics = [];

  @override
  Future<void> addClinic(Clinic clinic) async {
    lastAddedClinic = clinic;
    clinics.add(clinic);
  }

  @override
  Future<List<Clinic>> getAllClinics() async => clinics;
}

class MockRequirementRepository extends Fake implements RequirementRepository {
  Requirement? lastAddedRequirement;
  final List<Requirement> requirements = [];

  @override
  Future<void> addRequirement(Requirement requirement) async {
    lastAddedRequirement = requirement;
    requirements.add(requirement);
  }

  @override
  Future<List<Requirement>> getRequirementsByClinicId(String clinicId) async =>
      requirements.where((r) => r.clinicId == clinicId).toList();
}

void main() {
  group('DentalCatalog Unit Tests', () {
    test('standardDepartments contains all 10 academic dental departments', () {
      const expected = [
        'Oral Surgery',
        'Oral Medicine',
        'Removable Prosthodontics',
        'Fixed Prosthodontics',
        'Prosthodontics',
        'Operative',
        'Endodontics',
        'Orthodontics',
        'Pedodontics',
        'Periodontics',
      ];

      expect(DentalCatalog.standardDepartments, equals(expected));
      expect(DentalCatalog.standardDepartments.length, 10);
    });

    test('departmentOptions appends "Other..." to the 10 departments', () {
      final options = DentalCatalog.departmentOptions;
      expect(options.length, 11);
      expect(options.last, DentalCatalog.otherOption);
      expect(options, containsAll(DentalCatalog.standardDepartments));
    });

    test('Each standard department has non-empty predefined procedural catalog', () {
      for (final dept in DentalCatalog.standardDepartments) {
        final procedures = DentalCatalog.getProceduresForDepartment(dept);
        expect(procedures, isNotEmpty, reason: '$dept should have procedures');

        final options = DentalCatalog.getProcedureOptionsForDepartment(dept);
        expect(options.last, DentalCatalog.otherOption);
        expect(options.length, procedures.length + 1);
      }
    });

    test('isStandardDepartment recognizes standard names and clinical aliases', () {
      expect(DentalCatalog.isStandardDepartment('Oral Surgery'), isTrue);
      expect(DentalCatalog.isStandardDepartment('oral surgery'), isTrue);
      expect(DentalCatalog.isStandardDepartment('Prosthodontics'), isTrue);
      expect(DentalCatalog.isStandardDepartment('Operative'), isTrue);
      expect(DentalCatalog.isStandardDepartment('Operative Dentistry'), isTrue);
      expect(DentalCatalog.isStandardDepartment('Pedodontics'), isTrue);
      expect(DentalCatalog.isStandardDepartment('Pediatric Dentistry'), isTrue);

      expect(DentalCatalog.isStandardDepartment('Other...'), isFalse);
      expect(DentalCatalog.isStandardDepartment('Custom Clinic'), isFalse);
      expect(DentalCatalog.isStandardDepartment(null), isFalse);
    });

    test('getDefaultColorForDepartment returns valid color hex for all departments', () {
      for (final dept in DentalCatalog.standardDepartments) {
        final color = DentalCatalog.getDefaultColorForDepartment(dept);
        expect(color.startsWith('#'), isTrue);
        expect(color.length, 7);
      }
    });

    test('DefaultDentalCatalogRepository delegates accurately to DentalCatalog', () {
      const repo = DefaultDentalCatalogRepository();
      expect(repo.getStandardDepartments(), equals(DentalCatalog.standardDepartments));
      expect(repo.getDepartmentOptions(), equals(DentalCatalog.departmentOptions));
      expect(repo.isStandardDepartment('Endodontics'), isTrue);
      expect(repo.getProceduresForDepartment('Endodontics'), isNotEmpty);
      expect(repo.getDefaultColor('Endodontics'), equals(DentalCatalog.getDefaultColorForDepartment('Endodontics')));
    });

    test('dentalCatalogRepositoryProvider provides DefaultDentalCatalogRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(dentalCatalogRepositoryProvider);
      expect(repo, isA<DefaultDentalCatalogRepository>());
    });
  });

  group('AddClinicModal Catalog & "Other..." Integration Tests', () {
    testWidgets('Renders department dropdown with 10 standard departments and "Other..."',
        (WidgetTester tester) async {
      final mockRepo = MockClinicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicRepositoryProvider.overrideWithValue(mockRepo),
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

      expect(find.text('Department'), findsOneWidget);
      expect(find.text('Other...'), findsOneWidget);
      expect(find.byType(DenteraTextField), findsOneWidget); // Custom name field visible for "Other..."
    });

    testWidgets('Selecting a standard department sets clinic name directly and submits without custom text',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockClinicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicRepositoryProvider.overrideWithValue(mockRepo),
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

      // Tap department dropdown and select 'Oral Surgery'
      await tester.tap(find.text('Other...'));
      await tester.pumpAndSettle();

      final oralSurgeryItem = find.widgetWithText(DropdownMenuItem<String>, 'Oral Surgery');
      await tester.ensureVisible(oralSurgeryItem);
      await tester.pumpAndSettle();
      await tester.tap(oralSurgeryItem);
      await tester.pumpAndSettle();

      // Custom clinic name field should be hidden
      expect(find.text('Clinic Name'), findsNothing);

      // Submit
      await tester.tap(find.text('Save Clinic'));
      await tester.pumpAndSettle();

      expect(mockRepo.lastAddedClinic, isNotNull);
      expect(mockRepo.lastAddedClinic!.name, 'Oral Surgery');
      expect(mockRepo.lastAddedClinic!.colorHex, DentalCatalog.getDefaultColorForDepartment('Oral Surgery'));
    });

    testWidgets('Selecting "Other..." reveals custom clinic name field and enforces validation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockClinicRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: AddClinicModal(initialDepartment: 'Oral Surgery'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially 'Oral Surgery' - text field is hidden
      expect(find.text('Clinic Name'), findsNothing);

      // Switch to 'Other...'
      await tester.tap(find.text('Oral Surgery'));
      await tester.pumpAndSettle();

      final otherItem = find.widgetWithText(DropdownMenuItem<String>, 'Other...');
      await tester.ensureVisible(otherItem);
      await tester.pumpAndSettle();
      await tester.tap(otherItem);
      await tester.pumpAndSettle();

      // Custom field is revealed
      expect(find.text('Clinic Name'), findsOneWidget);

      // Try to submit empty
      await tester.tap(find.text('Save Clinic'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a clinic name'), findsOneWidget);
      expect(mockRepo.lastAddedClinic, isNull);

      // Enter valid custom name
      final nameField = find.widgetWithText(TextField, '');
      await tester.enterText(nameField.first, 'Maxillofacial Prosthetics');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Clinic'));
      await tester.pumpAndSettle();

      expect(mockRepo.lastAddedClinic, isNotNull);
      expect(mockRepo.lastAddedClinic!.name, 'Maxillofacial Prosthetics');
    });
  });

  group('AddRequirementModal Catalog & "Other..." Integration Tests', () {
    testWidgets('For standard clinic, renders procedure dropdown populated with predefined procedures',
        (WidgetTester tester) async {
      final mockReqRepo = MockRequirementRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            requirementRepositoryProvider.overrideWithValue(mockReqRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AddRequirementModal(
                clinicId: 'c-endo',
                clinicName: 'Endodontics',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Procedure / Requirement'), findsOneWidget);
      expect(find.text('Other...'), findsOneWidget);

      // Tap dropdown to see Endodontics procedures
      await tester.tap(find.text('Other...'));
      await tester.pumpAndSettle();

      expect(find.text('Anterior Root Canal Treatment'), findsWidgets);
      expect(find.text('Molar Root Canal Treatment'), findsWidgets);

      // Select 'Anterior Root Canal Treatment'
      await tester.tap(find.text('Anterior Root Canal Treatment').last);
      await tester.pumpAndSettle();

      // Custom title field is hidden
      expect(find.text('Custom Procedure Title'), findsNothing);

      // Submit
      await tester.tap(find.text('Save Requirement'));
      await tester.pumpAndSettle();

      expect(mockReqRepo.lastAddedRequirement, isNotNull);
      expect(mockReqRepo.lastAddedRequirement!.title, 'Anterior Root Canal Treatment');
      expect(mockReqRepo.lastAddedRequirement!.targetCount, 5);
      expect(mockReqRepo.lastAddedRequirement!.clinicId, 'c-endo');
    });

    testWidgets('For standard clinic with "Other...", allows custom procedure title entry',
        (WidgetTester tester) async {
      final mockReqRepo = MockRequirementRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            requirementRepositoryProvider.overrideWithValue(mockReqRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AddRequirementModal(
                clinicId: 'c-endo',
                clinicName: 'Endodontics',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "Other..." is selected by default, custom title field is visible
      expect(find.text('Custom Procedure Title'), findsOneWidget);

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'Apicoectomy');
      await tester.enterText(textFields.last, '2');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Requirement'));
      await tester.pumpAndSettle();

      expect(mockReqRepo.lastAddedRequirement, isNotNull);
      expect(mockReqRepo.lastAddedRequirement!.title, 'Apicoectomy');
      expect(mockReqRepo.lastAddedRequirement!.targetCount, 2);
    });

    testWidgets('For non-standard clinic created under "Other...", defaults to free-text input',
        (WidgetTester tester) async {
      final mockReqRepo = MockRequirementRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            requirementRepositoryProvider.overrideWithValue(mockReqRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AddRequirementModal(
                clinicId: 'c-custom',
                clinicName: 'Laser Dentistry', // Non-standard department
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Procedure dropdown is NOT rendered
      expect(find.text('Procedure / Requirement'), findsNothing);

      // Free-text requirement title field is rendered directly
      expect(find.text('Requirement Title'), findsOneWidget);

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'Laser Frenectomy');
      await tester.enterText(textFields.last, '3');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Requirement'));
      await tester.pumpAndSettle();

      expect(mockReqRepo.lastAddedRequirement, isNotNull);
      expect(mockReqRepo.lastAddedRequirement!.title, 'Laser Frenectomy');
      expect(mockReqRepo.lastAddedRequirement!.targetCount, 3);
    });
  });
}
