import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme.dart';
import 'data/repositories/preferences_repository.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/root_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: DenteraApp(),
    ),
  );
}

class DenteraApp extends StatelessWidget {
  const DenteraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dentera',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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
