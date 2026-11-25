import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/services/account_recovery_service.dart';
import '../../../core/services/database_backup_service.dart';
import '../../../core/theme/theme.dart';
import '../../../data/database/database.dart';
import '../../../data/repositories/preferences_repository.dart';
import '../../../l10n/l10n.dart';
import '../root_navigation_screen.dart';
import 'academic_year_page.dart';
import 'university_page.dart';
import 'welcome_page.dart';

/// Main Onboarding flow container utilizing a 3-step PageView.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();

  int _currentPage = 0;
  String _selectedYear = '';
  String? _yearError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Shared onboarding finalization helper enforcing strict Guest vs. Real User isolation:
  /// - Persists clinician credentials & `isGuest` flag via [PreferencesRepository].
  /// - If `isGuest == true`, seeds the rich showcase demo dataset (`DatabaseSeeder.seedGuestDemoData`).
  /// - If `isGuest == false`, enforces a clean clinical slate (`DatabaseSeeder.seedRealUserBaseline`:
  ///   0 patients, 0 case records, 0 appointments).
  /// - Synchronizes Riverpod profile state and invalidates cached domain providers prior to navigation.
  Future<void> _finalizeOnboarding({
    required bool isGuest,
    required String firstName,
    required String lastName,
    required String university,
    required String academicYear,
  }) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefsRepo = ref.read(preferencesRepositoryProvider);
      await prefsRepo.saveUserProfile(
        firstName: firstName,
        lastName: lastName,
        university: university,
        academicYear: academicYear,
        isGuest: isGuest,
      );

      await ref.read(onboardingSeederProvider)(
        isGuest: isGuest,
        academicYear: academicYear,
      );

      // Persist recovery metadata (for non-guest users) and installation verification marker.
      await ref.read(accountRecoveryServiceProvider).writeRecoverySnapshotAndInstallMarker(
            UserProfile(
              firstName: firstName,
              lastName: lastName,
              university: university,
              academicYear: academicYear,
              isGuest: isGuest,
            ),
          );

      // Refresh reactive profile notifier and clear any stale provider caches before entering workspace.
      await ref.read(userProfileProvider.notifier).loadProfile();
      ref.read(databaseBackupServiceProvider).invalidateRiverpodState();
      ref.invalidate(onboardingStatusProvider);
      ref.invalidate(startupRecoveryCandidateProvider);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => const RootNavigationScreen(),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('[OnboardingScreen] Failed to complete onboarding (isGuest: $isGuest): $e', e, stackTrace);
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _continueAsGuest() async {
    await _finalizeOnboarding(
      isGuest: true,
      firstName: 'Guest',
      lastName: '',
      university: 'Guest Dental University',
      academicYear: '5th Year',
    );
  }

  Future<void> _completeOnboarding() async {
    if (_selectedYear.trim().isEmpty) {
      setState(() {
        _yearError = context.l10n.academicYearRequired;
      });
      return;
    }

    final firstName = PreferencesRepository.stripDoctorPrefix(_firstNameController.text.trim());
    final lastName = PreferencesRepository.stripDoctorPrefix(_lastNameController.text.trim());
    final university = _universityController.text.trim();

    await _finalizeOnboarding(
      isGuest: false,
      firstName: firstName.isNotEmpty ? firstName : 'Doctor',
      lastName: lastName,
      university: university.isNotEmpty ? university : 'Dental School',
      academicYear: _selectedYear,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Header Section: Wordmark & Step Dots
            Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
              child: Column(
                children: <Widget>[
                  Text(
                    'DENTERA',
                    style: AppTextStyles.displayWordmark.copyWith(
                      color: isDark ? AppDarkColors.primaryTeal : AppColors.primary,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Step Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? (isDark ? AppDarkColors.primaryTeal : AppColors.secondary)
                              : (isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Page Content Stepper
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: <Widget>[
                  WelcomePage(
                    firstNameController: _firstNameController,
                    lastNameController: _lastNameController,
                    onContinue: _nextPage,
                    onContinueAsGuest: _continueAsGuest,
                    isLoading: _isLoading,
                  ),
                  UniversityPage(
                    universityController: _universityController,
                    onContinue: _nextPage,
                    onBack: _previousPage,
                  ),
                  AcademicYearPage(
                    selectedYear: _selectedYear,
                    errorMessage: _yearError,
                    onYearSelected: (year) {
                      setState(() {
                        _selectedYear = year;
                        _yearError = null;
                      });
                    },
                    onSubmit: _completeOnboarding,
                    onBack: _previousPage,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
