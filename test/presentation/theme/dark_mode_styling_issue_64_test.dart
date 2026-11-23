import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/l10n/l10n.dart';
import 'package:dentera/presentation/screens/clinics/clinics_screen.dart';
import 'package:dentera/presentation/screens/onboarding/academic_year_page.dart';
import 'package:dentera/presentation/screens/patients/patients_screen.dart';
import 'package:dentera/presentation/screens/profile/widgets/profile_header_card.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/widgets.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'firstName': 'Omar',
      'lastName': 'Khaled',
      'academicYear': '5th Year',
      'university': 'Sana’a University',
      'hasCompletedOnboarding': true,
    });
  });

  group('Issue #64: Complete Dark Mode Styling Verification', () {
    testWidgets('AcademicYearPage options use dark surfaces and readable text in Dark Mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AcademicYearPage(
              selectedYear: '4th Year',
              onYearSelected: (_) {},
              onSubmit: () {},
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify unselected card container (e.g. 5th Year) uses dark textSecondary
      final unselectedText = tester.widget<Text>(find.text('5th Year'));
      expect(unselectedText.style?.color, equals(AppDarkColors.textSecondary));

      // Verify selected card container (4th Year) text uses primary
      final selectedText = tester.widget<Text>(find.text('4th Year'));
      expect(selectedText.style?.color, equals(AppDarkColors.primary));
    });

    testWidgets('AcademicYearPage options retain light surfaces and colors in Light Mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AcademicYearPage(
              selectedYear: '4th Year',
              onYearSelected: (_) {},
              onSubmit: () {},
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final unselectedText = tester.widget<Text>(find.text('5th Year'));
      expect(unselectedText.style?.color, equals(AppColors.onSurfaceVariant));

      final selectedText = tester.widget<Text>(find.text('4th Year'));
      expect(selectedText.style?.color, equals(AppColors.primary));
    });

    testWidgets('PrimaryButton has no colored BoxShadow glow in Dark Mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: PrimaryButton(
              text: 'Save Changes',
              onPressed: () {},
            ),
          ),
        ),
      );

      final containerFinder = find.byType(Container).first;
      final Container container = tester.widget<Container>(containerFinder);
      final BoxDecoration decoration = container.decoration as BoxDecoration;

      // Glow must be null (clean, sharp edges)
      expect(decoration.boxShadow, isNull);
    });

    testWidgets('DenteraEmptyState adapts icon container, tint, and text in Dark Mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: DenteraEmptyState(
              icon: Icons.calendar_today_outlined,
              title: 'No Appointments',
              subtitle: 'Schedule a patient visit to get started.',
            ),
          ),
        ),
      );

      final titleText = tester.widget<Text>(find.text('No Appointments'));
      expect(titleText.style?.color, equals(AppDarkColors.textPrimary));

      final subtitleText = tester.widget<Text>(find.text('Schedule a patient visit to get started.'));
      expect(subtitleText.style?.color, equals(AppDarkColors.textSecondary));

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.calendar_today_outlined));
      expect(iconWidget.color, equals(AppDarkColors.textMuted));
    });

    testWidgets('DenteraEmptyState retains light theme colors in Light Mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: DenteraEmptyState(
              icon: Icons.calendar_today_outlined,
              title: 'No Appointments',
              subtitle: 'Schedule a patient visit to get started.',
            ),
          ),
        ),
      );

      final titleText = tester.widget<Text>(find.text('No Appointments'));
      expect(titleText.style?.color, equals(AppColors.onSurface));

      final subtitleText = tester.widget<Text>(find.text('Schedule a patient visit to get started.'));
      expect(subtitleText.style?.color, equals(AppColors.textSecondary));

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.calendar_today_outlined));
      expect(iconWidget.color, equals(AppColors.outline));
    });

    testWidgets('DenteraSearchBar adapts fill, text, and hint in Dark Mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: DenteraSearchBar(
              hintText: 'Search patients...',
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.style?.color, equals(AppDarkColors.textPrimary));
      expect(textField.decoration?.fillColor, equals(AppDarkColors.surfaceBase));
      expect(textField.decoration?.hintStyle?.color, equals(AppDarkColors.textPlaceholder));
    });

    testWidgets('DenteraSearchBar retains light colors in Light Mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: DenteraSearchBar(
              hintText: 'Search patients...',
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.style?.color, equals(AppColors.onSurface));
      expect(textField.decoration?.fillColor, equals(AppColors.surfaceContainerLowest));
      expect(textField.decoration?.hintStyle?.color, equals(AppColors.outline));
    });

    testWidgets('ProfileHeaderCard renders white title and light secondary text in Dark Mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: ProfileHeaderCard(
                name: 'Dr. Omar Khaled',
                subtitle: '5th Year Clinical Student • Sana’a University',
              ),
            ),
          ),
        ),
      );

      final nameText = tester.widget<Text>(find.text('Dr. Omar Khaled'));
      expect(nameText.style?.color, equals(AppDarkColors.textPrimary));

      final subtitleText = tester.widget<Text>(find.text('5th Year Clinical Student • Sana’a University'));
      expect(subtitleText.style?.color, equals(AppDarkColors.textSecondary));
    });

    testWidgets('ClinicsScreen header renders white text in Dark Mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicListProvider.overrideWith((ref) async => <Clinic>[]),
            allRequirementsProvider.overrideWith((ref) async => <Requirement>[]),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.darkTheme,
            home: const ClinicsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final headerFinder = find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Clinics & Requirements'),
      );
      expect(headerFinder, findsOneWidget);
      final headerText = tester.widget<Text>(headerFinder);
      expect(headerText.style?.color, equals(AppDarkColors.textPrimary));
    });

    testWidgets('PatientsScreen header renders white text in Dark Mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientListProvider.overrideWith((ref) async => <Patient>[]),
            allCasesProvider.overrideWith((ref) async => <CaseRecord>[]),
            allRequirementsProvider.overrideWith((ref) async => <Requirement>[]),
            clinicListProvider.overrideWith((ref) async => <Clinic>[]),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.darkTheme,
            home: const PatientsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final headerFinder = find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Patients'),
      );
      expect(headerFinder, findsOneWidget);
      final headerText = tester.widget<Text>(headerFinder);
      expect(headerText.style?.color, equals(AppDarkColors.textPrimary));
    });
  });
}
