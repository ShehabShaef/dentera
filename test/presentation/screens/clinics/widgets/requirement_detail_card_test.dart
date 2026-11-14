import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/l10n/l10n.dart';
import 'package:dentera/presentation/screens/clinics/widgets/requirement_detail_card.dart';

void main() {
  Widget buildHarness(Widget child, {ThemeMode themeMode = ThemeMode.light}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      themeMode: themeMode,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }

  group('RequirementDetailCard Widget Tests', () {
    testWidgets('renders requirement title, quota pill, and notes when present',
        (WidgetTester tester) async {
      const requirementWithNotes = Requirement(
        id: 'req-notes-1',
        clinicId: 'clinic-1',
        title: 'Class II Composite',
        targetCount: 6,
        completedCount: 2,
        notes: 'Must use sectional matrix and wedge; rubber dam required.',
      );

      await tester.pumpWidget(
        buildHarness(
          const RequirementDetailCard(
            requirement: requirementWithNotes,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title & Quota
      expect(find.text('Class II Composite'), findsOneWidget);
      expect(find.text('2 / 6'), findsOneWidget);

      // Notes rendering
      expect(find.byIcon(Icons.notes_rounded), findsOneWidget);
      expect(
        find.text('Must use sectional matrix and wedge; rubber dam required.'),
        findsOneWidget,
      );
    });

    testWidgets('does not render notes row or icon when notes is null',
        (WidgetTester tester) async {
      const requirementWithoutNotes = Requirement(
        id: 'req-no-notes',
        clinicId: 'clinic-1',
        title: 'Simple Extraction',
        targetCount: 10,
        completedCount: 4,
        notes: null,
      );

      await tester.pumpWidget(
        buildHarness(
          const RequirementDetailCard(
            requirement: requirementWithoutNotes,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Simple Extraction'), findsOneWidget);
      expect(find.text('4 / 10'), findsOneWidget);
      expect(find.byIcon(Icons.notes_rounded), findsNothing);
    });

    testWidgets('does not render notes row when notes is empty or whitespace only',
        (WidgetTester tester) async {
      const requirementWithBlankNotes = Requirement(
        id: 'req-blank-notes',
        clinicId: 'clinic-1',
        title: 'Complete Denture',
        targetCount: 3,
        completedCount: 1,
        notes: '   ',
      );

      await tester.pumpWidget(
        buildHarness(
          const RequirementDetailCard(
            requirement: requirementWithBlankNotes,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Complete Denture'), findsOneWidget);
      expect(find.byIcon(Icons.notes_rounded), findsNothing);
    });

    testWidgets('invokes onTap and onEdit callbacks appropriately',
        (WidgetTester tester) async {
      bool tapped = false;
      bool edited = false;

      const requirement = Requirement(
        id: 'req-callbacks',
        clinicId: 'clinic-1',
        title: 'Primary Pulpotomy',
        targetCount: 4,
        notes: 'Formocresol or ferric sulfate technique',
      );

      await tester.pumpWidget(
        buildHarness(
          RequirementDetailCard(
            requirement: requirement,
            onTap: () => tapped = true,
            onEdit: () => edited = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap onEdit
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      expect(edited, isTrue);

      // Tap card
      await tester.tap(find.text('Primary Pulpotomy'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });
}
