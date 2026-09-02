import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/screens/clinics/clinic_details_screen.dart';
import 'package:dentera/presentation/screens/clinics/widgets/widgets.dart';

void main() {
  group('ClinicDetailsScreen & RequirementDetailCard Widget Tests', () {
    const clinic = Clinic(
      id: 'c-pros',
      name: 'Prosthodontics',
      academicYear: '5th Year',
      colorHex: '#003E6F',
    );

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

    testWidgets('ClinicDetailsScreen renders overall progress and requirement list', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ClinicDetailsScreen(clinic: clinic),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prosthodontics'), findsOneWidget);
      expect(find.text('Overall Progress'), findsOneWidget);
      expect(find.text('4 of 8 Requirements Met'), findsOneWidget);
      expect(find.text('On Track'), findsOneWidget);
      expect(find.text('Procedural Requirements'), findsOneWidget);
      expect(find.text('Complete Denture'), findsOneWidget);
      expect(find.text('Removable Partial Denture (RPD)'), findsOneWidget);
      expect(find.text('Overdenture / Single Arch'), findsOneWidget);
      expect(find.text('No patients assigned yet.'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
