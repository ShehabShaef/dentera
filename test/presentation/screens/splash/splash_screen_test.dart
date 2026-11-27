import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/core/services/account_recovery_service.dart';
import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/repositories/preferences_repository.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/l10n/l10n.dart';
import 'package:dentera/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:dentera/presentation/screens/root_navigation_screen.dart';
import 'package:dentera/presentation/screens/splash/splash_screen.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/modals/account_recovery_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  List<Override> baseWorkspaceOverrides() {
    return [
      dailyAppointmentsProvider.overrideWith((ref, date) => <Appointment>[]),
      upcomingAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
      patientListProvider.overrideWith((ref) => <Patient>[]),
      allCasesProvider.overrideWith((ref) => <CaseRecord>[]),
      allRequirementsProvider.overrideWith((ref) => <Requirement>[]),
      clinicListProvider.overrideWith((ref) => <Clinic>[]),
      allAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
    ];
  }

  group('Issue #69: Transparent Brand Assets Verification', () {
    testWidgets('dentera_logo.png, dentera_logo_dark.png, and tooth marks have transparent backgrounds', (WidgetTester tester) async {
      await tester.runAsync(() async {
        for (final assetPath in const [
          'assets/images/dentera_logo.png',
          'assets/images/dentera_logo_dark.png',
          'assets/images/dentera_tooth_mark.png',
          'assets/images/dentera_tooth_mark_dark.png',
        ]) {
          final file = File(assetPath);
          expect(file.existsSync(), isTrue, reason: '$assetPath must exist');
          final codec = await ui.instantiateImageCodec(file.readAsBytesSync());
          final frame = await codec.getNextFrame();
          final image = frame.image;
          final rawBytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
          expect(rawBytes, isNotNull, reason: '$assetPath must yield RGBA bytes');
          final bytes = rawBytes!.buffer.asUint8List();

          // Top-left & bottom-right corner alpha channels must be 0 (transparent background)
          expect(bytes[3], equals(0), reason: '$assetPath top-left pixel must be transparent');
          expect(bytes[bytes.length - 1], equals(0), reason: '$assetPath bottom-right pixel must be transparent');

          // Ensure foreground logo ink pixels are present (alpha > 128)
          bool hasInk = false;
          for (int i = 3; i < bytes.length; i += 4) {
            if (bytes[i] > 128) {
              hasInk = true;
              break;
            }
          }
          expect(hasInk, isTrue, reason: '$assetPath must contain visible foreground logo strokes');
          image.dispose();
        }
      });
    });
  });

  group('Issue #69: Animated Theme-Aware SplashScreen Tests', () {
    testWidgets('renders Light Mode background, transparent tooth mark, shimmering wordmark, and transitions to OnboardingScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingStatusProvider.overrideWith((ref) async => false),
            startupRecoveryCandidateProvider.overrideWith((ref) async => null),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const SplashScreen(),
          ),
        ),
      );

      // Initial animation frame
      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('DENTERA'), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, equals(AppColors.background));

      final logoImg = tester.widget<Image>(find.byType(Image).first);
      expect((logoImg.image as AssetImage).assetName, equals('assets/images/dentera_tooth_mark.png'));

      // Complete entrance + PageRouteBuilder fade transition -> OnboardingScreen
      await tester.pumpAndSettle();
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('renders Dark Mode background, luminous dark emblem, and transitions to RootNavigationScreen when onboarded', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'doctorFirstName': 'Tariq',
        'doctorLastName': 'Al-Harbi',
        'university': 'King Saud University',
        'academicYear': '5th Year',
        'hasCompletedOnboarding': true,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseWorkspaceOverrides(),
            onboardingStatusProvider.overrideWith((ref) async => true),
            startupRecoveryCandidateProvider.overrideWith((ref) async => null),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const SplashScreen(),
          ),
        ),
      );

      await tester.pump();
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, equals(AppDarkColors.background));

      final logoImg = tester.widget<Image>(find.byType(Image).first);
      expect((logoImg.image as AssetImage).assetName, equals('assets/images/dentera_tooth_mark_dark.png'));

      await tester.pumpAndSettle();
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(RootNavigationScreen), findsOneWidget);
    });

    testWidgets('transitions smoothly to AccountRecoveryScreen when recovery candidate exists', (WidgetTester tester) async {
      const candidate = AccountRecoveryCandidate(
        firstName: 'Ahmed',
        lastName: 'Hassan',
        university: 'Cairo University',
        academicYear: '5th Year',
        fromSharedPreferences: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingStatusProvider.overrideWith((ref) async => true),
            startupRecoveryCandidateProvider.overrideWith((ref) async => candidate),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const SplashScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(AccountRecoveryScreen), findsOneWidget);
    });

    testWidgets('waits gracefully for slow startup futures past entrance duration before transitioning', (WidgetTester tester) async {
      final onboardingCompleter = Completer<bool>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingStatusProvider.overrideWith((ref) => onboardingCompleter.future),
            startupRecoveryCandidateProvider.overrideWith((ref) async => null),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const SplashScreen(
              entranceDuration: Duration(milliseconds: 900),
            ),
          ),
        ),
      );

      // Advance past the 900ms entrance animation while async future is still pending
      await tester.pump(const Duration(milliseconds: 950));
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Resolve startup async -> smooth fade transition into OnboardingScreen
      onboardingCompleter.complete(false);
      await tester.pumpAndSettle();
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('disposes AnimationController cleanly when unmounted mid-animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingStatusProvider.overrideWith((ref) async => false),
            startupRecoveryCandidateProvider.overrideWith((ref) async => null),
          ],
          child: const MaterialApp(
            home: SplashScreen(
              entranceDuration: Duration(milliseconds: 1100),
              autoNavigate: false,
            ),
          ),
        ),
      );

      // Advance partway through animation (~400ms)
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SplashScreen), findsOneWidget);

      // Replace widget tree mid-animation — must dispose controller with zero ticker leaks
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(find.byType(SplashScreen), findsNothing);
    });
  });
}
