import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/database/database_providers.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/domain/repositories/repositories.dart';
import 'package:dentera/presentation/screens/patients/patient_case_sheet_screen.dart';
import 'package:dentera/presentation/screens/patients/widgets/widgets.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/modals/add_radiograph_modal.dart';
import 'package:dentera/presentation/widgets/radiographs/radiograph_viewer_modal.dart';

class MockRadiographRepository implements RadiographRepository {
  final List<PatientRadiograph> radiographs = [];

  @override
  Future<void> addRadiograph(PatientRadiograph radiograph) async {
    radiographs.add(radiograph);
  }

  @override
  Future<void> updateRadiograph(PatientRadiograph radiograph) async {
    final idx = radiographs.indexWhere((r) => r.id == radiograph.id);
    if (idx != -1) {
      radiographs[idx] = radiograph;
    }
  }

  @override
  Future<void> deleteRadiograph(String id) async {
    radiographs.removeWhere((r) => r.id == id);
  }

  @override
  Future<PatientRadiograph?> getRadiographById(String id) async {
    return radiographs.where((r) => r.id == id).firstOrNull;
  }

  @override
  Future<List<PatientRadiograph>> getRadiographsByPatient(String patientId) async {
    return radiographs.where((r) => r.patientId == patientId).toList();
  }

  @override
  Future<List<PatientRadiograph>> getAllRadiographs() async {
    return List.unmodifiable(radiographs);
  }
}

void main() {
  late MockRadiographRepository mockRadRepo;

  final testPatient = Patient(
    id: 'pt-xray-001',
    name: 'Ahmed Tariq',
    age: 28,
    gender: 'Male',
    createdAt: DateTime(2026, 9, 1),
  );

  setUp(() {
    mockRadRepo = MockRadiographRepository();
  });

  Widget buildTestableApp({Widget? home}) {
    return ProviderScope(
      overrides: [
        radiographRepositoryProvider.overrideWithValue(mockRadRepo),
        radiographsByPatientProvider(testPatient.id).overrideWith(
          (ref) async => mockRadRepo.radiographs.where((r) => r.patientId == testPatient.id).toList(),
        ),
        patientByIdProvider(testPatient.id).overrideWith((ref) async => testPatient),
        casesByPatientProvider(testPatient.id).overrideWith((ref) async => <CaseRecord>[]),
        treatmentPlansByPatientProvider(testPatient.id).overrideWith((ref) async => <TreatmentPlan>[]),
        allRequirementsProvider.overrideWith((ref) async => <Requirement>[]),
        allClinicsProvider.overrideWith((ref) async => <Clinic>[]),
        clinicListProvider.overrideWith((ref) async => <Clinic>[]),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: home ?? Scaffold(body: RadiographsGallerySection(patient: testPatient)),
      ),
    );
  }

  group('RadiographsGallerySection & Offline X-Ray Viewer Tests', () {
    testWidgets('renders zero state with attach prompt when no radiographs exist', (tester) async {
      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      expect(find.text('Radiographs'), findsOneWidget);
      expect(find.text('Attach X-Ray'), findsOneWidget);
      expect(
        find.text(
          'No radiographs attached. Attach periapical, bitewing, or panoramic X-rays for offline diagnostic review.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping Attach X-Ray opens AddRadiographModal and saves radiograph', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      // Tap Attach X-Ray button
      final attachBtn = find.text('Attach X-Ray');
      expect(attachBtn, findsOneWidget);
      await tester.tap(attachBtn);
      await tester.pumpAndSettle();

      // Modal should be displayed
      expect(find.byType(AddRadiographModal), findsOneWidget);
      expect(find.text('Attach Radiograph (X-Ray)'), findsOneWidget);
      expect(find.text('Projection Type'), findsOneWidget);

      // Select Panoramic type
      final panoChip = find.text('Panoramic');
      await tester.tap(panoChip);
      await tester.pumpAndSettle();

      // Enter clinical notes
      final notesField = find.widgetWithText(TextField, 'e.g., Periapical radiolucency on root apex #36, crestal bone level normal...');
      await tester.enterText(notesField, 'Full dentition panoramic survey showing impacted #38 and #48');
      await tester.pumpAndSettle();

      // Submit modal
      final submitBtn = find.text('Attach Radiograph');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Since no image was selected, validation error should appear
      expect(find.text('Please capture or select a radiograph image.'), findsOneWidget);
    });

    testWidgets('AddRadiographModal saves radiograph when image is provided', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tempFile = File('${Directory.systemTemp.path}/test_picker_img_${DateTime.now().microsecondsSinceEpoch}.png');
      tempFile.writeAsBytesSync(const <int>[
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
      ]);

      try {
        await tester.pumpWidget(
          buildTestableApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => AddRadiographModal.show(
                    context,
                    patientId: testPatient.id,
                    initialImagePath: tempFile.path,
                  ),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        expect(find.byType(AddRadiographModal), findsOneWidget);

        final bitewingChip = find.text('Bitewing');
        await tester.ensureVisible(bitewingChip);
        await tester.tap(bitewingChip);
        await tester.pumpAndSettle();

        final submitBtn = find.text('Attach Radiograph');
        await tester.ensureVisible(submitBtn);

        await tester.runAsync(() async {
          await tester.tap(submitBtn);
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pumpAndSettle();

        expect(mockRadRepo.radiographs, hasLength(1));
        expect(mockRadRepo.radiographs.first.type, equals(PatientRadiograph.typeBitewing));
      } finally {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      }
    });

    testWidgets('renders horizontal radiograph cards with type badges and capture dates', (tester) async {
      mockRadRepo.radiographs.addAll([
        PatientRadiograph(
          id: 'rad-peri-1',
          patientId: testPatient.id,
          filePath: '/mock/path/peri1.jpg',
          type: PatientRadiograph.typePeriapical,
          notes: 'Apex of tooth #21',
          captureDate: DateTime(2026, 9, 8),
          createdAt: DateTime(2026, 9, 8),
        ),
        PatientRadiograph(
          id: 'rad-pano-1',
          patientId: testPatient.id,
          filePath: '/mock/path/pano1.jpg',
          type: PatientRadiograph.typePanoramic,
          notes: 'Pre-ortho OPG',
          captureDate: DateTime(2026, 9, 10),
          createdAt: DateTime(2026, 9, 10),
        ),
      ]);

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      // Count badge
      expect(find.text('2'), findsOneWidget);

      // Type tags
      expect(find.text('Periapical'), findsOneWidget);
      expect(find.text('Panoramic'), findsOneWidget);

      // Formatted dates
      expect(find.text('Sep 8, 2026'), findsOneWidget);
      expect(find.text('Sep 10, 2026'), findsOneWidget);

      // Notes preview
      expect(find.text('Apex of tooth #21'), findsOneWidget);
      expect(find.text('Pre-ortho OPG'), findsOneWidget);
    });

    testWidgets('tapping radiograph card opens full-screen interactive viewer', (tester) async {
      final radItem = PatientRadiograph(
        id: 'rad-view-1',
        patientId: testPatient.id,
        filePath: '/mock/path/view_test.jpg',
        type: PatientRadiograph.typePeriapical,
        notes: 'Periapical bone density normal',
        captureDate: DateTime(2026, 9, 11),
        createdAt: DateTime(2026, 9, 11),
      );
      mockRadRepo.radiographs.add(radItem);

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      // Tap the radiograph thumbnail card
      await tester.tap(find.text('Periapical bone density normal'));
      await tester.pumpAndSettle();

      // RadiographViewerModal should now be open
      expect(find.byType(RadiographViewerModal), findsOneWidget);
      expect(find.text('Ahmed Tariq'), findsOneWidget);
      expect(find.text('Captured: September 11, 2026'), findsOneWidget);
      expect(find.text('Periapical bone density normal'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

      // Tap back button to close
      final backBtn = find.byTooltip('Close Viewer');
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.byType(RadiographViewerModal), findsNothing);
    });

    testWidgets('deleting radiograph from viewer removes it from repository', (tester) async {
      final radItem = PatientRadiograph(
        id: 'rad-del-1',
        patientId: testPatient.id,
        filePath: '/mock/path/delete_me.jpg',
        type: PatientRadiograph.typeBitewing,
        notes: 'Caries detection bitewing',
        captureDate: DateTime(2026, 9, 5),
        createdAt: DateTime(2026, 9, 5),
      );
      mockRadRepo.radiographs.add(radItem);

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      // Tap to open viewer
      await tester.tap(find.text('Caries detection bitewing'));
      await tester.pumpAndSettle();

      // Tap delete button in app bar
      final deleteBtn = find.byTooltip('Delete Radiograph');
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Delete Radiograph?'), findsOneWidget);
      final confirmBtn = find.widgetWithText(FilledButton, 'Delete');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Viewer should close and item should be removed
      expect(find.byType(RadiographViewerModal), findsNothing);
      expect(mockRadRepo.radiographs, isEmpty);
      expect(find.text('No radiographs attached. Attach periapical, bitewing, or panoramic X-rays for offline diagnostic review.'), findsOneWidget);
    });

    testWidgets('PatientCaseSheetScreen renders RadiographsGallerySection inside Patient History tab', (tester) async {
      mockRadRepo.radiographs.add(
        PatientRadiograph(
          id: 'rad-casesheet-1',
          patientId: testPatient.id,
          filePath: '/mock/path/opg.jpg',
          type: PatientRadiograph.typePanoramic,
          captureDate: DateTime(2026, 9, 11),
          createdAt: DateTime(2026, 9, 11),
        ),
      );

      await tester.pumpWidget(
        buildTestableApp(
          home: PatientCaseSheetScreen(patient: testPatient),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Patient History Tab
      final historyTab = find.text('Patient History');
      await tester.tap(historyTab);
      await tester.pumpAndSettle();

      // RadiographsGallerySection should be rendered
      expect(find.byType(RadiographsGallerySection), findsOneWidget);
      expect(find.text('Panoramic'), findsOneWidget);
    });
  });
}
