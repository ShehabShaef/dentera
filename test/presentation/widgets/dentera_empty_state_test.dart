import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/presentation/widgets/dentera_empty_state.dart';

void main() {
  group('DenteraEmptyState Widget Tests', () {
    testWidgets('renders title, subtitle, and default icon with proper theme styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: DenteraEmptyState(
              icon: Icons.account_balance_outlined,
              title: 'No clinics found',
              subtitle: 'Please register a new clinic.',
            ),
          ),
        ),
      );

      expect(find.byType(DenteraEmptyState), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_outlined), findsOneWidget);
      expect(find.text('No clinics found'), findsOneWidget);
      expect(find.text('Please register a new clinic.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders custom graphic widget when graphic parameter is passed', (WidgetTester tester) async {
      const customGraphicKey = Key('custom_svg_graphic');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: DenteraEmptyState(
              graphic: SizedBox(
                key: customGraphicKey,
                width: 100,
                height: 100,
              ),
              title: 'Custom Graphic Zero State',
              subtitle: 'Rendering with custom SVG illustration.',
            ),
          ),
        ),
      );

      expect(find.byKey(customGraphicKey), findsOneWidget);
      expect(find.text('Custom Graphic Zero State'), findsOneWidget);
      expect(find.text('Rendering with custom SVG illustration.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders action button and triggers callback when pressed', (WidgetTester tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DenteraEmptyState(
              icon: Icons.people_outline_rounded,
              title: 'Empty Directory',
              subtitle: 'No records available.',
              actionText: 'Add Record',
              onAction: () => actionPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Add Record'), findsOneWidget);
      await tester.tap(find.text('Add Record'));
      expect(actionPressed, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders compact layout correctly without layout overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SizedBox(
              height: 250,
              width: 300,
              child: DenteraEmptyState(
                icon: Icons.event_available_outlined,
                title: 'No Items',
                subtitle: 'Compact view guidance.',
                isCompact: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('No Items'), findsOneWidget);
      expect(find.text('Compact view guidance.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
