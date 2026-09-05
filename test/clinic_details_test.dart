import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/screens/clinics/clinic_details_screen.dart';
import 'package:dentera/presentation/screens/clinics/widgets/widgets.dart';
import 'package:dentera/presentation/state/state.dart';

void main() {
  group('ClinicDetailsScreen & RequirementDetailCard Widget Tests', () {
    const clinic = Clinic(
      id: 'c-pros',
      name: 'Prosthodontics',
      academicYear: '5th Year',
      colorHex: '#003E6F',
    );

    const testRequirements = <Requirement>[
      Requirement(
        id: 'r-01',
        clinicId: 'c-pros',
        title: 'Complete Denture',
        targetCount: 3,
        completedCount: 2,
      ),
      Requirement(
        id: 'r-02',
        clinicId: 'c-pros',
        title: 'Removable Partial Denture (RPD)',
        targetCount: 2,
        completedCount: 1,
      ),
    ];

    testWidgets('RequirementDetailCard renders quota fraction and linked patient cases', (WidgetTester tester) async {
      const requirement = Requirement(
        id: 'r-01',
        clinicId: 'c-pros',
        title: 'Complete Denture',
        targetCount: 3,
        completedCount: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: RequirementDetailCard(
              requirement: requirement,
              accentColor: AppColors.primary,
              linkedCases: <LinkedPatientCase>[
                LinkedPatientCase(patientName: 'Ahmed Ali', status: 'Completed', isCompleted: true),
                LinkedPatientCase(patientName: 'Omar Khalid', status: 'In Progress', isCompleted: false),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Complete Denture'), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.text('66% Done'), findsOneWidget);
      expect(find.text('Ahmed Ali'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Omar Khalid'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
    });

    testWidgets('ClinicDetailsScreen renders zero state when no requirements exist', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            requirementsByClinicProvider(clinic.id).overrideWith((ref) async => <Requirement>[]),
            allCasesProvider.overrideWith((ref) async => <CaseRecord>[]),
          ],
          child: const MaterialApp(
            home: ClinicDetailsScreen(clinic: clinic),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prosthodontics'), findsOneWidget);
      expect(find.text('Overall Progress'), findsOneWidget);
      expect(find.text('0 of 0 Requirements Met'), findsOneWidget);
      expect(find.text('Needs Focus'), findsOneWidget);
      expect(find.text('Procedural Requirements'), findsOneWidget);
      expect(find.text('No requirements added yet'), findsOneWidget);
      expect(find.text('Define clinical quotas and procedural targets for Prosthodontics.'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('ClinicDetailsScreen renders overall progress and requirement list when populated', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            requirementsByClinicProvider(clinic.id).overrideWith((ref) async => testRequirements),
            allCasesProvider.overrideWith((ref) async => <CaseRecord>[]),
          ],
          child: const MaterialApp(
            home: ClinicDetailsScreen(clinic: clinic),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prosthodontics'), findsOneWidget);
      expect(find.text('Overall Progress'), findsOneWidget);
      expect(find.text('3 of 5 Requirements Met'), findsOneWidget);
      expect(find.text('On Track'), findsOneWidget);
      expect(find.text('Procedural Requirements'), findsOneWidget);
      expect(find.text('Complete Denture'), findsOneWidget);
      expect(find.text('Removable Partial Denture (RPD)'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
