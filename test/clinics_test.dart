import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/screens/clinics/clinics_screen.dart';
import 'package:dentera/presentation/screens/clinics/widgets/widgets.dart';
import 'package:dentera/presentation/state/state.dart';

void main() {
  group('Clinics & Requirements Widget Tests', () {
    const testClinics = <Clinic>[
      Clinic(
        id: 'c-prosth',
        name: 'Prosthodontics',
        academicYear: '5th Year',
        colorHex: '#003E6F',
      ),
      Clinic(
        id: 'c-op',
        name: 'Operative Dentistry',
        academicYear: '5th Year',
        colorHex: '#006A64',
      ),
      Clinic(
        id: 'c-endo',
        name: 'Endodontics',
        academicYear: '5th Year',
        colorHex: '#1E568C',
      ),
    ];

    testWidgets('ClinicSummaryCard renders department data and handles View Cases', (WidgetTester tester) async {
      bool viewCasesTapped = false;

      const clinic = Clinic(
        id: 'c-prosth',
        name: 'Prosthodontics',
        academicYear: '5th Year',
        colorHex: '#003E6F',
      );

      const requirements = <Requirement>[
        Requirement(
          id: 'r-1',
          clinicId: 'c-prosth',
          title: 'Complete Denture',
          targetCount: 2,
          completedCount: 1,
        ),
        Requirement(
          id: 'r-2',
          clinicId: 'c-prosth',
          title: 'Metal Denture',
          targetCount: 3,
          completedCount: 2,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ClinicSummaryCard(
              clinic: clinic,
              requirements: requirements,
              onTap: () => viewCasesTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Prosthodontics'), findsOneWidget);
      expect(find.text('60% Complete'), findsOneWidget);
      expect(find.text('Complete Denture'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('Metal Denture'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);
      expect(find.text('2 requirements left'), findsOneWidget);
      expect(find.text('View Cases'), findsOneWidget);

      await tester.tap(find.text('View Cases'));
      expect(viewCasesTapped, isTrue);
    });

    testWidgets('ClinicsScreen renders zero state when clinicListProvider returns empty list', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicListProvider.overrideWith((ref) async => <Clinic>[]),
            allRequirementsProvider.overrideWith((ref) async => <Requirement>[]),
          ],
          child: const MaterialApp(
            home: ClinicsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clinics & Requirements'), findsOneWidget);
      expect(find.text('No clinics added yet'), findsOneWidget);
      expect(find.text('Register your clinical departments to track quotas and case progress.'), findsOneWidget);
      expect(find.text('Add Dental Clinic'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('ClinicsScreen renders categories and filters clinic cards when populated', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicListProvider.overrideWith((ref) async => testClinics),
            allRequirementsProvider.overrideWith((ref) async => <Requirement>[]),
          ],
          child: const MaterialApp(
            home: ClinicsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clinics & Requirements'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Prosthodontics'), findsNWidgets(2)); // Category pill + Card header
      expect(find.text('Operative Dentistry'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Filter by Endodontics
      await tester.tap(find.widgetWithText(InkWell, 'Endodontics'));
      await tester.pumpAndSettle();

      expect(find.text('Endodontics'), findsNWidgets(2)); // Category pill + Card header
      expect(find.text('Operative Dentistry'), findsNothing);
    });
  });
}
