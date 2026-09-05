import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/presentation/screens/clinics/clinics_screen.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/widgets.dart';

void main() {
  group('ClinicsScreen Zero State Widget Tests', () {
    testWidgets('ClinicsScreen renders DenteraEmptyState with action button when clinicListProvider emits empty array',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicListProvider.overrideWith((ref) async => <Clinic>[]),
            allRequirementsProvider.overrideWith((ref) async => <Requirement>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ClinicsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert that unified zero state component renders
      expect(find.byType(DenteraEmptyState), findsOneWidget);

      // Assert text content
      expect(find.text('No clinics added yet'), findsOneWidget);
      expect(
        find.text('Register your clinical departments to track quotas and case progress.'),
        findsOneWidget,
      );
      expect(find.text('Add Dental Clinic'), findsOneWidget);

      // Verify no layout overflow exceptions occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('ClinicsScreen renders DenteraEmptyState when category filter yields zero matches',
        (WidgetTester tester) async {
      const testClinics = <Clinic>[
        Clinic(
          id: 'c-1',
          name: 'Endodontics Clinic',
          academicYear: '5th Year',
          colorHex: '#003E6F',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicListProvider.overrideWith((ref) async => testClinics),
            allRequirementsProvider.overrideWith((ref) async => <Requirement>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ClinicsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on 'Prosthodontics' filter pill which yields zero matches for Endodontics clinic
      final filterPill = find.widgetWithText(InkWell, 'Prosthodontics');
      expect(filterPill, findsOneWidget);
      await tester.tap(filterPill);
      await tester.pumpAndSettle();

      // Assert that unified zero state component renders for empty filter
      expect(find.byType(DenteraEmptyState), findsOneWidget);
      expect(find.text('No clinics found in "Prosthodontics"'), findsOneWidget);
      expect(find.text('Try selecting "All" or a different clinical category.'), findsOneWidget);

      // Verify no layout overflow exceptions occurred
      expect(tester.takeException(), isNull);
    });
  });
}
