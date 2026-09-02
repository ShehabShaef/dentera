import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../data/repositories/preferences_repository.dart';
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();

  int _currentPage = 0;
  String _selectedYear = '4th Year';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
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

  Future<void> _completeOnboarding() async {
    final name = _nameController.text.trim();
    final university = _universityController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final prefsRepo = ref.read(preferencesRepositoryProvider);
      await prefsRepo.saveUserProfile(
        name: name.isNotEmpty ? name : 'Doctor',
        university: university.isNotEmpty ? university : 'Dental School',
        academicYear: _selectedYear,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => const RootNavigationScreen(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                      color: AppColors.primary,
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
                          color: isActive ? AppColors.secondary : AppColors.outlineVariant,
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
                    nameController: _nameController,
                    onContinue: _nextPage,
                  ),
                  UniversityPage(
                    universityController: _universityController,
                    onContinue: _nextPage,
                    onBack: _previousPage,
                  ),
                  AcademicYearPage(
                    selectedYear: _selectedYear,
                    onYearSelected: (year) {
                      setState(() {
                        _selectedYear = year;
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
