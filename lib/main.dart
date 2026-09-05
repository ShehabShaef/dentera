import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/logging/app_provider_observer.dart';
import 'core/theme/theme.dart';
import 'data/repositories/preferences_repository.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/root_navigation_screen.dart';

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

    return MaterialApp(
      title: 'Dentera',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const InitializationScreen(),
    );
  }
}

class InitializationScreen extends ConsumerWidget {
  const InitializationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingStatusProvider);

    return onboardingAsync.when(
      data: (hasCompleted) {
        if (hasCompleted) {
          return const RootNavigationScreen();
        }
        return const OnboardingScreen();
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      error: (error, stackTrace) => const OnboardingScreen(),
    );
  }
}
