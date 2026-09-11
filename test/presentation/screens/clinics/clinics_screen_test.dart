import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/database/database_providers.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/domain/repositories/clinic_repository.dart';
import 'package:dentera/presentation/screens/clinics/clinics_screen.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/widgets.dart';

void main() {
  group('ClinicsScreen Zero State Widget Tests', () {
    testWidgets('ClinicsScreen renders DenteraEmptyState with action button when clinicListProvider emits empty array',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicListProvider.overrideWith((ref) async => <Clinic>[]),
            allRequirementsProvider.overrideWith((ref) async => <Requirement>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ClinicsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert that unified zero state component renders
      expect(find.byType(DenteraEmptyState), findsOneWidget);

      // Assert text content
      expect(find.text('No clinics added yet'), findsOneWidget);
      expect(
        find.text('Register your clinical departments to track quotas and case progress.'),
        findsOneWidget,
      );
      expect(find.text('Add Dental Clinic'), findsOneWidget);

      // Verify no layout overflow exceptions occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('ClinicsScreen renders DenteraEmptyState when category filter yields zero matches',
        (WidgetTester tester) async {
      const testClinics = <Clinic>[
        Clinic(
          id: 'c-1',
          name: 'Endodontics Clinic',
          academicYear: '5th Year',
          colorHex: '#003E6F',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicListProvider.overrideWith((ref) async => testClinics),
            allRequirementsProvider.overrideWith((ref) async => <Requirement>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ClinicsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on 'Prosthodontics' filter pill which yields zero matches for Endodontics clinic
      final filterPill = find.widgetWithText(InkWell, 'Prosthodontics');
      expect(filterPill, findsOneWidget);
      await tester.tap(filterPill);
      await tester.pumpAndSettle();

      // Assert that unified zero state component renders for empty filter
      expect(find.byType(DenteraEmptyState), findsOneWidget);
      expect(find.text('No clinics found in "Prosthodontics"'), findsOneWidget);
      expect(find.text('Try selecting "All" or a different clinical category.'), findsOneWidget);

      // Verify no layout overflow exceptions occurred
      expect(tester.takeException(), isNull);
    });
  });

  group('ClinicsScreen Multi-Select Batch Deletion Tests', () {
    late FakeClinicRepository fakeRepo;
    const testClinics = <Clinic>[
      Clinic(
        id: 'clinic-1',
        name: 'Endodontics Clinic',
        academicYear: '4th Year',
        colorHex: '#003E6F',
      ),
      Clinic(
        id: 'clinic-2',
        name: 'Periodontics Clinic',
        academicYear: '5th Year',
        colorHex: '#2E7D32',
      ),
    ];

    setUp(() {
      fakeRepo = FakeClinicRepository(List.from(testClinics));
    });

    Widget createWidgetUnderTest() {
      return ProviderScope(
        overrides: [
          clinicRepositoryProvider.overrideWithValue(fakeRepo),
          clinicListProvider.overrideWith((ref) async => fakeRepo.getAllClinics()),
          allRequirementsProvider.overrideWith((ref) async => <Requirement>[]),
          allCasesProvider.overrideWith((ref) async => <CaseRecord>[]),
          upcomingAppointmentsProvider.overrideWith((ref) async => <Appointment>[]),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ClinicsScreen(),
        ),
      );
    }

    testWidgets('3-dots menu displays Sort Clinics and Delete Clinics options',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap 3-dots popup menu
      final popupFinder = find.byType(PopupMenuButton<String>);
      expect(popupFinder, findsOneWidget);
      await tester.tap(popupFinder);
      await tester.pumpAndSettle();

      // Assert popup items
      expect(find.text('Sort Clinics'), findsOneWidget);
      expect(find.text('Delete Clinics'), findsOneWidget);
    });

    testWidgets('Selecting Sort Clinics opens SortClinicsModal with sort options',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Open popup and select Sort Clinics
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sort Clinics'));
      await tester.pumpAndSettle();

      // Assert SortClinicsModal options
      expect(find.byType(SortClinicsModal), findsOneWidget);
      expect(find.text('Name (A to Z)'), findsOneWidget);
      expect(find.text('Academic Year'), findsOneWidget);
      expect(find.text('Quota Progress'), findsOneWidget);
    });

    testWidgets('Selecting Delete Clinics enters selection mode with contextual action bar and checkboxes',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Open popup and select Delete Clinics
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Clinics'));
      await tester.pumpAndSettle();

      // Contextual action bar assertions
      expect(find.text('0 Selected'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Select All'), findsOneWidget);
      expect(find.text('Delete (0)'), findsOneWidget);

      // FAB is hidden in selection mode
      expect(find.byType(FloatingActionButton), findsNothing);

      // Checkboxes appear for each clinic card
      expect(find.byType(CircularCheckbox), findsNWidgets(2));
    });

    testWidgets('Tapping clinic card toggles selection and updates count',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter selection mode
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Clinics'));
      await tester.pumpAndSettle();

      // Tap first clinic card
      await tester.tap(find.text('Endodontics Clinic'));
      await tester.pumpAndSettle();

      expect(find.text('1 Selected'), findsOneWidget);
      expect(find.text('Delete (1)'), findsOneWidget);

      // Tap again to unselect
      await tester.tap(find.text('Endodontics Clinic'));
      await tester.pumpAndSettle();

      expect(find.text('0 Selected'), findsOneWidget);
      expect(find.text('Delete (0)'), findsOneWidget);
    });

    testWidgets('Tapping Select All selects all clinics and toggles to Deselect All',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter selection mode
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Clinics'));
      await tester.pumpAndSettle();

      // Tap Select All
      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();

      expect(find.text('2 Selected'), findsOneWidget);
      expect(find.text('Deselect All'), findsOneWidget);
      expect(find.text('Delete (2)'), findsOneWidget);

      // Tap Deselect All
      await tester.tap(find.text('Deselect All'));
      await tester.pumpAndSettle();

      expect(find.text('0 Selected'), findsOneWidget);
      expect(find.text('Select All'), findsOneWidget);
      expect(find.text('Delete (0)'), findsOneWidget);
    });

    testWidgets('Tapping Cancel exits selection mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter selection mode
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Clinics'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert normal state restored
      expect(find.text('Clinics & Requirements'), findsOneWidget);
      expect(find.byType(CircularCheckbox), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Batch deletion confirmation modal warns about cascade deletion and deletes selected clinics',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter selection mode
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Clinics'));
      await tester.pumpAndSettle();

      // Select first clinic
      await tester.tap(find.text('Endodontics Clinic'));
      await tester.pumpAndSettle();

      // Tap Delete (1)
      await tester.tap(find.text('Delete (1)'));
      await tester.pumpAndSettle();

      // Safety warning dialog asserts
      expect(find.text('Delete Selected Clinics?'), findsOneWidget);
      expect(
        find.textContaining('permanently remove all associated requirements, clinical case records, and scheduled appointments'),
        findsOneWidget,
      );

      // Tap Delete in dialog
      final deleteConfirmButton = find.widgetWithText(FilledButton, 'Delete');
      await tester.tap(deleteConfirmButton);
      await tester.pumpAndSettle();

      // Verify repository execution
      expect(fakeRepo.lastDeletedClinicIds, ['clinic-1']);
      expect(fakeRepo.clinics.length, 1);
      expect(fakeRepo.clinics.first.id, 'clinic-2');

      // Assert selection mode exited
      expect(find.text('Clinics & Requirements'), findsOneWidget);
    });
  });
}

class FakeClinicRepository implements ClinicRepository {
  final List<Clinic> clinics;
  List<String> lastDeletedClinicIds = [];

  FakeClinicRepository(this.clinics);

  @override
  Future<void> addClinic(Clinic clinic) async => clinics.add(clinic);

  @override
  Future<void> updateClinic(Clinic clinic) async {
    final idx = clinics.indexWhere((c) => c.id == clinic.id);
    if (idx != -1) clinics[idx] = clinic;
  }

  @override
  Future<List<Clinic>> getAllClinics() async => clinics;

  @override
  Future<Clinic?> getClinicById(String id) async =>
      clinics.where((c) => c.id == id).firstOrNull;

  @override
  Future<void> deleteClinic(String id) async {
    lastDeletedClinicIds = [id];
    clinics.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> deleteClinics(List<String> ids) async {
    lastDeletedClinicIds = List.from(ids);
    clinics.removeWhere((c) => ids.contains(c.id));
  }
}

