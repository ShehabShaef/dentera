import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/screens/patients/patients_screen.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/widgets.dart';

void main() {
  group('PatientsScreen Zero State Widget Tests', () {
    final dummyPatients = <Patient>[
      Patient(
        id: 'PT-1001',
        name: 'Sara Ahmed',
        age: 23,
        gender: 'Female',
        phoneNumber: '+967-771234567',
        medicalHistory: 'No known allergies',
        createdAt: DateTime.parse('2026-08-20T10:00:00.000Z'),
      ),
    ];

    testWidgets('PatientsScreen renders DenteraEmptyState with action button when patientListProvider emits empty array',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientListProvider.overrideWith((ref) async => <Patient>[]),
            allCasesProvider.overrideWith((ref) async => <CaseRecord>[]),
            allRequirementsProvider.overrideWith((ref) async => <Requirement>[]),
            clinicListProvider.overrideWith((ref) async => <Clinic>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PatientsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert that unified zero state component renders
      expect(find.byType(DenteraEmptyState), findsOneWidget);

      // Assert text content
      expect(find.text('No patients found'), findsOneWidget);
      expect(
        find.text('Add your first patient to start tracking clinical requirements.'),
        findsOneWidget,
      );
      expect(find.text('Add First Patient'), findsOneWidget);

      // Verify no layout overflow exceptions occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('PatientsScreen renders DenteraEmptyState when search query matches zero records',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientListProvider.overrideWith((ref) async => dummyPatients),
            allCasesProvider.overrideWith((ref) async => <CaseRecord>[]),
            allRequirementsProvider.overrideWith((ref) async => <Requirement>[]),
            clinicListProvider.overrideWith((ref) async => <Clinic>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PatientsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search query that has no match
      await tester.enterText(find.byType(TextField), 'NonExistentPatient');
      await tester.pumpAndSettle();

      // Assert unified zero state component renders
      expect(find.byType(DenteraEmptyState), findsOneWidget);
      expect(find.text('No patients found'), findsOneWidget);
      expect(find.text('No patient records match "NonExistentPatient".'), findsOneWidget);

      // Verify no layout overflow exceptions occurred
      expect(tester.takeException(), isNull);
    });
  });
}
