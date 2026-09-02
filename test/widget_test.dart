import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/main.dart';
import 'package:dentera/presentation/widgets/widgets.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('DenteraApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DenteraApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DENTERA'), findsOneWidget);
    expect(find.text('Welcome, Doctor.'), findsOneWidget);
  });

  testWidgets('PrimaryButton renders and triggers onPressed', (WidgetTester tester) async {
    bool pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: PrimaryButton(
            text: 'Save Patient',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    expect(find.text('Save Patient'), findsOneWidget);
    await tester.tap(find.byType(PrimaryButton));
    expect(pressed, isTrue);
  });

  testWidgets('SecondaryButton renders and triggers onPressed', (WidgetTester tester) async {
    bool pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SecondaryButton(
            text: 'Cancel',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.byType(SecondaryButton));
    expect(pressed, isTrue);
  });

  testWidgets('DenteraTextField renders label and hint', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: DenteraTextField(
            label: 'Patient Name',
            hintText: 'Enter name',
          ),
        ),
      ),
    );

    expect(find.text('Patient Name'), findsOneWidget);
    expect(find.text('Enter name'), findsOneWidget);
  });

  testWidgets('RequirementProgressBar renders progress and text', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: RequirementProgressBar.fromQuota(
            completed: 3,
            total: 5,
            label: 'Crowns',
          ),
        ),
      ),
    );

    expect(find.text('Crowns'), findsOneWidget);
    expect(find.text('3/5'), findsOneWidget);
  });

  testWidgets('CircularProgressRing renders percentage', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: CircularProgressRing(
            progress: 0.75,
          ),
        ),
      ),
    );

    expect(find.text('75%'), findsOneWidget);
  });

  testWidgets('BaseCard and ActionCard render and respond', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Column(
            children: [
              const BaseCard(
                child: Text('Base Card Content'),
              ),
              ActionCard(
                onTap: () => tapped = true,
                child: const Text('Action Card Content'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Base Card Content'), findsOneWidget);
    expect(find.text('Action Card Content'), findsOneWidget);
    await tester.tap(find.text('Action Card Content'));
    expect(tapped, isTrue);
  });
}
