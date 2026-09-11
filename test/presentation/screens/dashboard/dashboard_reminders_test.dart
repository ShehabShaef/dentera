import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/screens/clinics/clinic_details_screen.dart';
import 'package:dentera/presentation/screens/dashboard/widgets/dashboard_reminders.dart';
import 'package:dentera/presentation/screens/patients/patient_case_sheet_screen.dart';
import 'package:dentera/presentation/state/state.dart';

void main() {
  final fixedClock = DateTime(2026, 9, 11, 14, 0);

  final testPatient = Patient(
    id: 'PT-999',
    name: 'Ahmed Yaseen',
    age: 28,
    gender: 'Male',
    phoneNumber: '+967770000000',
    createdAt: DateTime(2026, 1, 1),
  );

  const testClinic = Clinic(
    id: 'clinic-endo',
    name: 'Endodontics',
    academicYear: '5th Year',
    colorHex: '#2E3F50',
  );

  Widget buildTestWidget({
    required Widget child,
    List<dynamic> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        clinicalRemindersClockProvider.overrideWithValue(fixedClock),
        patientListProvider.overrideWith((ref) => <Patient>[testPatient]),
        patientByIdProvider(testPatient.id).overrideWith((ref) => testPatient),
        clinicListProvider.overrideWith((ref) => <Clinic>[testClinic]),
        allRequirementsProvider.overrideWith((ref) => <Requirement>[]),
        requirementsByClinicProvider(testClinic.id).overrideWith((ref) => <Requirement>[]),
        allCasesProvider.overrideWith((ref) => <CaseRecord>[]),
        casesByPatientProvider(testPatient.id).overrideWith((ref) => <CaseRecord>[]),
        radiographsByPatientProvider(testPatient.id).overrideWith((ref) => <PatientRadiograph>[]),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: child),
      ),
    );
  }

  group('DashboardReminders Widget & Navigation Tests (Issue #21)', () {
    testWidgets('collapses to SizedBox.shrink when no reminders exist', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            clinicalRemindersProvider.overrideWithValue(<ClinicalReminderItem>[]),
          ],
          child: const DashboardReminders(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsNothing);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('renders overdue case alert pill and navigates to PatientCaseSheetScreen on tap', (tester) async {
      final overdueCase = CaseRecord(
        id: 'case-overdue-12345',
        patientId: testPatient.id,
        requirementId: 'req-1',
        status: 'In Progress',
        dateStarted: fixedClock.subtract(const Duration(days: 18)),
      );

      final reminderItem = ClinicalReminderItem(
        id: 'overdue-case-${overdueCase.id}',
        message: 'Case #case-o: overdue (18 days in progress)',
        icon: Icons.warning_amber_rounded,
        type: ReminderType.alert,
        category: ReminderCategory.overdueCase,
        caseRecord: overdueCase,
      );

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            clinicalRemindersProvider.overrideWithValue([reminderItem]),
          ],
          child: const DashboardReminders(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Case #case-o: overdue (18 days in progress)'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // Tap reminder pill
      await tester.tap(find.text('Case #case-o: overdue (18 days in progress)'));
      await tester.pumpAndSettle();

      // Verify navigation to PatientCaseSheetScreen
      expect(find.byType(PatientCaseSheetScreen), findsOneWidget);
      expect(find.text('Ahmed Yaseen'), findsWidgets);
    });

    testWidgets('renders imminent appointment warning pill and navigates to PatientCaseSheetScreen on tap', (tester) async {
      final imminentApt = Appointment(
        id: 'apt-imminent-88',
        patientId: testPatient.id,
        clinicId: testClinic.id,
        scheduledDate: fixedClock.add(const Duration(minutes: 30)),
        status: 'Scheduled',
      );

      final reminderItem = ClinicalReminderItem(
        id: 'imminent-apt-${imminentApt.id}',
        message: 'Appointment starting in 30m (Patient #${testPatient.id})',
        icon: Icons.alarm,
        type: ReminderType.warning,
        category: ReminderCategory.imminentAppointment,
        appointment: imminentApt,
      );

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            clinicalRemindersProvider.overrideWithValue([reminderItem]),
          ],
          child: const DashboardReminders(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Appointment starting in 30m (Patient #${testPatient.id})'), findsOneWidget);
      expect(find.byIcon(Icons.alarm), findsOneWidget);

      // Tap reminder pill
      await tester.tap(find.text('Appointment starting in 30m (Patient #${testPatient.id})'));
      await tester.pumpAndSettle();

      // Verify navigation
      expect(find.byType(PatientCaseSheetScreen), findsOneWidget);
      expect(find.text('Ahmed Yaseen'), findsWidgets);
    });

    testWidgets('renders lagging quota alert pill and navigates to ClinicDetailsScreen on tap', (tester) async {
      final reminderItem = ClinicalReminderItem(
        id: 'quota-pacing-${testClinic.id}',
        message: 'Endodontics quota lagging (10% / Target: 20)',
        icon: Icons.pie_chart_outline_rounded,
        type: ReminderType.warning,
        category: ReminderCategory.laggingQuota,
        clinic: testClinic,
      );

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            clinicalRemindersProvider.overrideWithValue([reminderItem]),
          ],
          child: const DashboardReminders(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Endodontics quota lagging (10% / Target: 20)'), findsOneWidget);
      expect(find.byIcon(Icons.pie_chart_outline_rounded), findsOneWidget);

      // Tap reminder pill
      await tester.tap(find.text('Endodontics quota lagging (10% / Target: 20)'));
      await tester.pumpAndSettle();

      // Verify navigation to ClinicDetailsScreen
      expect(find.byType(ClinicDetailsScreen), findsOneWidget);
      expect(find.text('Endodontics'), findsOneWidget);
    });
  });
}
