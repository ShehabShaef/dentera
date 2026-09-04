import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:dentera/presentation/screens/dashboard/widgets/widgets.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'doctorName': 'Dr. Shehab',
      'academicYear': '5th Year',
      'hasCompletedOnboarding': true,
    });
  });

  group('Dashboard Screen & Subwidgets Widget Tests', () {
    testWidgets('DashboardHeader renders doctor greeting and initials', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: DashboardHeader(
                doctorName: 'Dr. Shehab',
                academicYear: '5th Year',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Good morning, Dr. Shehab'), findsOneWidget);
      expect(find.text('Today • 5th Year Clinics'), findsOneWidget);
      expect(find.text('SH'), findsOneWidget);
    });

    testWidgets('DashboardProgressCard renders circular ring and progress bars', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: DashboardProgressCard(),
          ),
        ),
      );

      expect(find.text('68%'), findsOneWidget);
      expect(find.text('Reqs'), findsOneWidget);
      expect(find.text('Prosthodontics'), findsOneWidget);
      expect(find.text('Endodontics'), findsOneWidget);
    });

    testWidgets('DashboardAppointmentCard renders patient details and handles action', (WidgetTester tester) async {
      bool viewCaseTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DashboardAppointmentCard(
              patientName: 'Ali Nasser',
              patientId: 'PT-2049',
              patientDetails: 'Male • 45 Y',
              timeWindow: '10:30 AM - 12:00 PM',
              procedureTitle: 'Prosthodontics - Metal Denture',
              onViewCase: () => viewCaseTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Ali Nasser'), findsOneWidget);
      expect(find.text('ID: PT-2049 • Male • 45 Y'), findsOneWidget);
      expect(find.text('10:30 AM - 12:00 PM'), findsOneWidget);
      expect(find.text('Prosthodontics - Metal Denture'), findsOneWidget);
      expect(find.text('View Case'), findsOneWidget);

      await tester.tap(find.text('View Case'));
      expect(viewCaseTapped, isTrue);
    });

    testWidgets('DashboardUpcomingSection renders tomorrow patient cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: DashboardUpcomingSection(),
            ),
          ),
        ),
      );

      expect(find.text("Tomorrow's Patients"), findsOneWidget);
      expect(find.text('Sara Ahmed'), findsOneWidget);
      expect(find.text('Omar Khalid'), findsOneWidget);
      expect(find.text('Lina Mahmoud'), findsOneWidget);
      expect(find.text('View Full Schedule'), findsOneWidget);
    });

    testWidgets('DashboardScreen full view renders with FAB', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Good morning, Dr. Shehab'), findsOneWidget);
      expect(find.text('Up Next'), findsOneWidget);
      expect(find.text('Ali Nasser'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
