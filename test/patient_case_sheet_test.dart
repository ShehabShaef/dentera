import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/screens/patients/patient_case_sheet_screen.dart';
import 'package:dentera/presentation/screens/patients/widgets/widgets.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/widgets.dart';

void main() {
  group('PatientCaseSheetScreen & CaseRecordCard Widget Tests', () {
    final patient = Patient(
      id: 'PT-1001',
      name: 'Sara Ahmed',
      age: 23,
      gender: 'Female',
      phoneNumber: '+967-771234567',
      medicalHistory: 'Penicillin Allergy',
      createdAt: DateTime.parse('2026-08-20T10:00:00.000Z'),
    );

    final testCaseRecord = CaseRecord(
      id: 'c-01',
      patientId: 'PT-1001',
      requirementId: 'r-01',
      dateStarted: DateTime(2026, 8, 1),
      dateCompleted: DateTime(2026, 8, 15),
      status: 'Evaluated',
    );

    testWidgets('CaseRecordCard renders case details and completion date', (WidgetTester tester) async {
      bool tapped = false;
      final caseRecord = CaseRecord(
        id: 'c-01',
        patientId: 'PT-1001',
        requirementId: 'r-01',
        dateStarted: DateTime(2026, 8, 1),
        dateCompleted: DateTime(2026, 8, 15),
        status: 'Evaluated',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CaseRecordCard(
              caseRecord: caseRecord,
              requirementTitle: 'Complete Denture',
              clinicName: 'Prosthodontics',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Complete Denture'), findsOneWidget);
      expect(find.text('Prosthodontics'), findsOneWidget);
      expect(find.text('Evaluated'), findsOneWidget);
      expect(find.text('Started: Aug 1, 2026'), findsOneWidget);
      expect(find.text('Done: Aug 15, 2026'), findsOneWidget);

      await tester.tap(find.text('Complete Denture'));
      expect(tapped, isTrue);
    });

    testWidgets('PatientCaseSheetScreen renders zero state when no clinical cases exist', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            casesByPatientProvider(patient.id).overrideWith((ref) async => <CaseRecord>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: PatientCaseSheetScreen(patient: patient),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header Demographic Information
      expect(find.text('Sara Ahmed'), findsNWidgets(2)); // AppBar + Summary Header
      expect(find.text('Female, 23 yrs • +967-771234567'), findsOneWidget);

      // Default Active Tab: Clinical Cases (Zero State)
      expect(find.byType(DenteraEmptyState), findsOneWidget);
      expect(find.text('Clinical Cases'), findsOneWidget);
      expect(find.text('No clinical cases logged yet'), findsOneWidget);
      expect(find.text('Start logging procedural cases and treatments completed for Sara Ahmed.'), findsOneWidget);
      expect(find.text('Log First Case'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('PatientCaseSheetScreen renders persistent header and switches tabs when populated', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            casesByPatientProvider(patient.id).overrideWith((ref) async => [testCaseRecord]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: PatientCaseSheetScreen(patient: patient),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header Demographic Information
      expect(find.text('Sara Ahmed'), findsNWidgets(2)); // AppBar + Summary Header
      expect(find.text('Female, 23 yrs • +967-771234567'), findsOneWidget);
      expect(find.text('SA'), findsOneWidget);

      // Default Active Tab: Clinical Cases (Populated)
      expect(find.text('Clinical Cases'), findsOneWidget);
      expect(find.text('Clinical Requirement #r-01'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Assert unbacked Treatment Plan tab was pruned
      expect(find.text('Treatment Plan'), findsNothing);

      // Verify exactly 2 tabs exist in TabBar (Clinical Cases and Medical History)
      expect(find.byType(Tab), findsNWidgets(2));

      // Switch to Medical History Tab
      await tester.tap(find.text('Medical History'));
      await tester.pumpAndSettle();

      // Assert dynamic medical history renders and unbacked Dental History is pruned
      expect(find.text('Medical History & Allergies'), findsOneWidget);
      expect(find.text('Penicillin Allergy'), findsOneWidget);
      expect(find.text('Dental History'), findsNothing);
    });
  });
}
