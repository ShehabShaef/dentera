import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/logging/app_provider_observer.dart';
import 'core/services/account_recovery_service.dart';
import 'core/theme/theme.dart';
import 'data/repositories/preferences_repository.dart';
import 'l10n/app_localizations.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/root_navigation_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/widgets/modals/account_recovery_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      observers: [
        AppProviderObserver(),
      ],
      child: DenteraApp(),
    ),
  );
}

class DenteraApp extends ConsumerWidget {
  const DenteraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);
    final locale = Locale(currentLocale);

    return MaterialApp(
      title: 'Dentera',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightThemeForLocale(locale),
      darkTheme: AppTheme.darkThemeForLocale(locale),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const SplashScreen(),
    );
  }
}

class InitializationScreen extends ConsumerWidget {
  const InitializationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingStatusProvider);
    final recoveryAsync = ref.watch(startupRecoveryCandidateProvider);

    return onboardingAsync.when(
      data: (hasCompleted) {
        if (recoveryAsync.isLoading) {
          return _buildLoadingScaffold(context);
        }
        final recoveryCandidate = recoveryAsync.valueOrNull;
        if (recoveryCandidate != null) {
          return AccountRecoveryScreen(candidate: recoveryCandidate);
        }
        if (hasCompleted) {
          return const RootNavigationScreen();
        }
        return const OnboardingScreen();
      },
      loading: () => _buildLoadingScaffold(context),
      error: (error, stackTrace) => const OnboardingScreen(),
    );
  }

  Widget _buildLoadingScaffold(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset(
              isDark
                  ? 'assets/images/dentera_logo_dark.png'
                  : 'assets/images/dentera_logo.png',
              width: 72,
              height: 72,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.medical_services_outlined,
                size: 64,
                color: isDark ? AppDarkColors.primaryTeal : AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppDarkColors.primaryTeal : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
