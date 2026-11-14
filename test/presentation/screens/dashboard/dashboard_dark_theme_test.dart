import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:dentera/presentation/screens/dashboard/widgets/widgets.dart';
import 'package:dentera/presentation/state/state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'doctorName': 'Dr. Shehab',
      'academicYear': '5th Year',
      'hasCompletedOnboarding': true,
    });
  });

  group('Dark Theme Verification & Contrast Tests (Issue #50)', () {
    test('AppDarkColors primary and secondary are refined desaturated medical tones', () {
      // Ensure the neon tokens (0xFF46EFCF, 0xFF48F9DD) are eliminated in favor of softer tones
      expect(AppDarkColors.primary, equals(const Color(0xFF38B293)));
      expect(AppDarkColors.secondary, equals(const Color(0xFF42A69A)));

      // Ensure text muted and tertiary sky-blue are configured for WCAG AA compliance
      expect(AppDarkColors.textMuted, equals(const Color(0xFF94A3B8)));
      expect(AppDarkColors.tertiary, equals(const Color(0xFF93C5FD)));

      // Light mode tokens must remain completely untouched
      expect(AppColors.primary, equals(const Color(0xFF003E6F)));
      expect(AppColors.secondary, equals(const Color(0xFF006A64)));
    });

    testWidgets('DashboardAppointmentCard adapts surface and text colors in Dark Mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: DashboardAppointmentCard(
              patientName: 'Omar Khaled',
              patientId: 'PT-9901',
              patientDetails: 'Male • 28 Y',
              timeWindow: '11:00 AM - 12:30 PM',
              procedureTitle: 'Endodontics - Root Canal',
            ),
          ),
        ),
      );

      // Verify Card Outer Container uses dark surface palette instead of hardcoded white
      final containerFinder = find.byType(Container).first;
      final Container containerWidget = tester.widget<Container>(containerFinder);
      final BoxDecoration decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.color, equals(AppDarkColors.surfaceContainer));

      // Verify Patient Name text rendered with dark textPrimary
      final patientNameText = tester.widget<Text>(find.text('Omar Khaled'));
      expect(patientNameText.style?.color, equals(AppDarkColors.textPrimary));

      // Verify Subtitle text rendered with dark textMuted
      final subtitleText = tester.widget<Text>(find.text('ID: PT-9901 • Male • 28 Y'));
      expect(subtitleText.style?.color, equals(AppDarkColors.textMuted));

      // Verify Procedure tag text uses high-contrast tertiary sky-blue
      final procedureTagText = tester.widget<Text>(find.text('Endodontics - Root Canal'));
      expect(procedureTagText.style?.color, equals(AppDarkColors.tertiary));
    });

    testWidgets('DashboardAppointmentCard retains surfaceContainerLowest in Light Mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: DashboardAppointmentCard(
              patientName: 'Omar Khaled',
              patientId: 'PT-9901',
              patientDetails: 'Male • 28 Y',
              timeWindow: '11:00 AM - 12:30 PM',
              procedureTitle: 'Endodontics - Root Canal',
            ),
          ),
        ),
      );

      final containerFinder = find.byType(Container).first;
      final Container containerWidget = tester.widget<Container>(containerFinder);
      final BoxDecoration decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.color, equals(AppColors.surfaceContainerLowest));

      // In light mode, procedure tag should use primary
      final procedureTagText = tester.widget<Text>(find.text('Endodontics - Root Canal'));
      expect(procedureTagText.style?.color, equals(AppColors.primary));
    });

    testWidgets('DashboardScreen renders properly with dark theme active appointments', (WidgetTester tester) async {
      final appointment = Appointment(
        id: 'apt-001',
        patientId: 'PT-4040',
        clinicId: 'clinic-01',
        procedureDescription: 'Class II Composite',
        scheduledDate: DateTime.now(),
        status: 'In Progress',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyAppointmentsProvider.overrideWith((ref, date) => <Appointment>[appointment]),
            upcomingAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
            allRequirementsProvider.overrideWith((ref) => <Requirement>[]),
            clinicListProvider.overrideWith((ref) => <Clinic>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Appointment Card was rendered with dark mode surface
      expect(find.byType(DashboardAppointmentCard), findsOneWidget);
      expect(find.text('Patient #PT-4040'), findsOneWidget);
      expect(find.text('Class II Composite'), findsOneWidget);

      final dashboardCardContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(DashboardAppointmentCard),
          matching: find.byType(Container),
        ).first,
      );
      final BoxDecoration cardBoxDecoration = dashboardCardContainer.decoration as BoxDecoration;
      expect(cardBoxDecoration.color, equals(AppDarkColors.surfaceContainer));
    });
  });
}
