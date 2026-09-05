import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dentera/core/services/database_backup_service.dart';
import 'package:dentera/presentation/widgets/inputs/dentera_text_field.dart';
import 'package:dentera/presentation/widgets/modals/database_reset_modal.dart';

class MockResetDatabaseBackupService extends DatabaseBackupService {
  bool resetCalled = false;

  @override
  Future<void> resetAllData({dynamic preferencesRepository}) async {
    resetCalled = true;
  }
}

void main() {
  group('DatabaseResetModal Widget Tests', () {
    testWidgets('destructive button remains disabled until exact string "RESET" is entered',
        (WidgetTester tester) async {
      final mockService = MockResetDatabaseBackupService();

      bool? modalResult;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseBackupServiceProvider.overrideWithValue(mockService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    modalResult = await DatabaseResetModal.show(context);
                  },
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open the modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Verify modal content is rendered
      expect(find.text('Danger Zone'), findsOneWidget);
      expect(find.text('Reset All Clinical Data'), findsOneWidget);
      expect(find.text('Wipe All Data'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      final wipeButton = find.text('Wipe All Data');
      final inputField = find.byType(DenteraTextField);
      expect(inputField, findsOneWidget);

      // 1. Initial State: Button should be disabled
      await tester.tap(wipeButton);
      await tester.pumpAndSettle();
      expect(mockService.resetCalled, isFalse);
      expect(modalResult, isNull);

      // 2. Case mismatch: "reset" (lowercase) - should remain disabled
      await tester.enterText(inputField, 'reset');
      await tester.pumpAndSettle();

      await tester.tap(wipeButton);
      await tester.pumpAndSettle();
      expect(mockService.resetCalled, isFalse);
      expect(modalResult, isNull);

      // 3. Incomplete keyword: "RESE" - should remain disabled
      await tester.enterText(inputField, 'RESE');
      await tester.pumpAndSettle();

      await tester.tap(wipeButton);
      await tester.pumpAndSettle();
      expect(mockService.resetCalled, isFalse);
      expect(modalResult, isNull);

      // 4. Excess keyword: "RESET ALL" - should remain disabled
      await tester.enterText(inputField, 'RESET ALL');
      await tester.pumpAndSettle();

      await tester.tap(wipeButton);
      await tester.pumpAndSettle();
      expect(mockService.resetCalled, isFalse);
      expect(modalResult, isNull);

      // 5. Exact keyword: "RESET" - should enable the button and execute reset
      await tester.enterText(inputField, 'RESET');
      await tester.pumpAndSettle();

      await tester.tap(wipeButton);
      await tester.pumpAndSettle();

      expect(mockService.resetCalled, isTrue);
      expect(modalResult, isTrue);
      expect(find.text('Reset All Clinical Data'), findsNothing);
    });

    testWidgets('cancel button dismisses modal without executing reset',
        (WidgetTester tester) async {
      final mockService = MockResetDatabaseBackupService();
      bool? modalResult;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseBackupServiceProvider.overrideWithValue(mockService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    modalResult = await DatabaseResetModal.show(context);
                  },
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open the modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(mockService.resetCalled, isFalse);
      expect(modalResult, isFalse);
      expect(find.text('Reset All Clinical Data'), findsNothing);
    });
  });
}
