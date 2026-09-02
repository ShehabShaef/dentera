import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/widgets/widgets.dart';

void main() {
  group('AddPatientModal Widget Tests', () {
    testWidgets('AddPatientModal renders form inputs and enforces validation', (WidgetTester tester) async {
      Patient? createdPatient;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AddPatientModal.show(
                      context,
                      onPatientAdded: (patient) => createdPatient = patient,
                    );
                  },
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('New Patient'), findsOneWidget);
      expect(find.text('Patient Name *'), findsOneWidget);
      expect(find.text('Age *'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Assign to Clinic'), findsOneWidget);
      expect(find.text('Prosthodontics'), findsOneWidget);
      expect(find.text('Save Patient'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Save Patient without filling form -> Validation triggers
      await tester.tap(find.text('Save Patient'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter the patient name'), findsOneWidget);
      expect(find.text('Enter age'), findsOneWidget);
      expect(createdPatient, isNull);

      // Fill in Name and Age
      await tester.enterText(find.widgetWithText(DenteraTextField, 'Patient Name *'), 'Layla Al-Yamani');
      await tester.enterText(find.widgetWithText(DenteraTextField, 'Age *'), '28');
      await tester.pumpAndSettle();

      // Expand Optional Details
      await tester.tap(find.text('Add Contact & Details (Optional)'));
      await tester.pumpAndSettle();

      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Medical History / Allergies'), findsOneWidget);

      await tester.enterText(find.widgetWithText(DenteraTextField, 'Phone Number'), '+967-771122334');
      await tester.enterText(find.widgetWithText(DenteraTextField, 'Medical History / Allergies'), 'No known drug allergies');
      await tester.pumpAndSettle();

      // Tap Save Patient
      await tester.tap(find.text('Save Patient'));
      await tester.pumpAndSettle();

      // Modal closed
      expect(find.text('New Patient'), findsNothing);

      // Patient was created properly
      expect(createdPatient, isNotNull);
      expect(createdPatient!.name, 'Layla Al-Yamani');
      expect(createdPatient!.age, 28);
      expect(createdPatient!.gender, 'Male');
      expect(createdPatient!.phoneNumber, '+967-771122334');
      expect(createdPatient!.medicalHistory, 'No known drug allergies');
    });
  });
}
