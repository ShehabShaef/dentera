import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/data/repositories/preferences_repository.dart';
import 'package:dentera/l10n/app_localizations.dart';
import 'package:dentera/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Localization and Internationalization Tests', () {
    testWidgets('DenteraApp initializes with supportedLocales and localizationsDelegates', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: DenteraApp(),
        ),
      );
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.supportedLocales, contains(const Locale('en')));
      expect(materialApp.supportedLocales, contains(const Locale('ar')));
      expect(materialApp.localizationsDelegates, isNotEmpty);
      expect(materialApp.locale, const Locale('en'));
    });

    testWidgets('AppLocalizations provides localized strings for en and ar', (WidgetTester tester) async {
      final enLoc = await AppLocalizations.delegate.load(const Locale('en'));
      expect(enLoc.appTitle, 'Dentera');

      final arLoc = await AppLocalizations.delegate.load(const Locale('ar'));
      expect(arLoc.appTitle, 'دينتيرا');
    });

    testWidgets('Updating localeProvider dynamically changes MaterialApp locale and text direction', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const DenteraApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Initially 'en' (LTR)
      MaterialApp app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, const Locale('en'));

      // Switch to 'ar'
      await container.read(localeProvider.notifier).setLocale('ar');
      await tester.pumpAndSettle();

      // Verify app locale changed to 'ar'
      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, const Locale('ar'));

      // Verify text direction is RTL for Arabic
      final directionality = Directionality.of(tester.element(find.byType(Scaffold).first));
      expect(directionality, TextDirection.rtl);

      // Switch back to 'en'
      await container.read(localeProvider.notifier).setLocale('en');
      await tester.pumpAndSettle();

      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, const Locale('en'));
      final ltrDirectionality = Directionality.of(tester.element(find.byType(Scaffold).first));
      expect(ltrDirectionality, TextDirection.ltr);
    });
  });
}
