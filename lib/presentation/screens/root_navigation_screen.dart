import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../core/theme/theme.dart';
import '../../l10n/l10n.dart';
import '../state/state.dart';
import 'appointments/appointments_screen.dart';
import 'clinics/clinics_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'patients/patients_screen.dart';
import 'profile/profile_screen.dart';

/// Root navigation screen maintaining an interactive, swipeable [PageView] across the five core tabs.
///
/// ### Routing Mechanisms in Dentera:
/// 1. **Tab Switching via Riverpod (`rootNavigationIndexProvider`) & Gestures:**
///    The 5 core tabs (Dashboard, Clinics, Patients, Schedule, Profile) reside inside
///    an interactive [PageView] with [AutomaticKeepAliveClientMixin] state preservation.
///    This preserves screen scroll positions, cached form states, search filters,
///    and sub-widget lifecycles across horizontal swipes and bottom navigation taps.
///    Any child widget in the application tree can declaratively switch the active tab
///    by mutating [rootNavigationIndexProvider], which smoothly synchronizes with
///    the underlying [PageController].
///
/// 2. **Deep Link / Detail Routing via [Navigator.push]:**
///    Screens requiring drill-down views (e.g. [PatientCaseSheetScreen], modal sheets,
///    or clinical evaluation records) are pushed onto the imperative [Navigator]
///    stack as [MaterialPageRoute]s above the [RootNavigationScreen], providing standard
///    OS back gestures and isolated sub-routes.
class RootNavigationScreen extends ConsumerStatefulWidget {
  const RootNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  ConsumerState<RootNavigationScreen> createState() => _RootNavigationScreenState();
}

class _RootNavigationScreenState extends ConsumerState<RootNavigationScreen> {
  late final PageController _pageController;

  final List<Widget> _screens = const <Widget>[
    DashboardScreen(),
    ClinicsScreen(),
    PatientsScreen(),
    AppointmentsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    AppLogger.debug('Initialized PageController with initialPage: ${widget.initialIndex}');

    // If an initialIndex other than the default was passed, sync the Riverpod provider.
    if (widget.initialIndex != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(rootNavigationIndexProvider.notifier).state = widget.initialIndex;
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (ref.read(rootNavigationIndexProvider) != index) {
      AppLogger.info('RootNavigationScreen: horizontal swipe gesture navigated to tab index: $index');
      ref.read(rootNavigationIndexProvider.notifier).state = index;
    }
  }

  void _onTabSelected(int index) {
    if (ref.read(rootNavigationIndexProvider) != index) {
      AppLogger.info('RootNavigationScreen: bottom navigation tapped tab index: $index');
      ref.read(rootNavigationIndexProvider.notifier).state = index;
    }
  }

  void _navigateToPage(int targetIndex) {
    if (!_pageController.hasClients) return;
    final currentPage = _pageController.page?.round() ?? 0;
    if (currentPage == targetIndex) return;

    final isAdjacent = (targetIndex - currentPage).abs() == 1;
    if (isAdjacent) {
      _pageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _pageController.jumpToPage(targetIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to Riverpod rootNavigationIndexProvider changes (e.g. from bottom bar taps,
    // Dashboard shortcuts, or external provider mutations) and sync PageController.
    ref.listen<int>(rootNavigationIndexProvider, (previous, next) {
      _navigateToPage(next);
    });

    final currentIndex = ref.watch(rootNavigationIndexProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navBg = isDark
        ? AppDarkColors.surfaceContainer
        : AppColors.surfaceContainerLowest;
    final selectedColor = isDark
        ? AppDarkColors.primary
        : AppColors.secondary;
    final unselectedColor = isDark
        ? AppDarkColors.textMuted
        : AppColors.onSurfaceVariant;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const PageScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          border: isDark
              ? const Border(
                  top: BorderSide(color: AppDarkColors.outlineVariant, width: 1),
                )
              : null,
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF2A3B4C).withValues(alpha: 0.04),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: _onTabSelected,
            type: BottomNavigationBarType.fixed,
            backgroundColor: navBg,
            selectedItemColor: selectedColor,
            unselectedItemColor: unselectedColor,
            selectedLabelStyle: AppTextStyles.labelCaps.copyWith(
              fontWeight: FontWeight.w700,
              color: selectedColor,
            ),
            unselectedLabelStyle: AppTextStyles.labelCaps.copyWith(
              fontWeight: FontWeight.w500,
              color: unselectedColor,
            ),
            elevation: 0,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard_outlined),
                activeIcon: const Icon(Icons.dashboard_rounded),
                label: context.l10n.dashboard,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.medical_services_outlined),
                activeIcon: const Icon(Icons.medical_services_rounded),
                label: context.l10n.clinics,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.people_outline_rounded),
                activeIcon: const Icon(Icons.people_rounded),
                label: context.l10n.patients,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.calendar_today_outlined),
                activeIcon: const Icon(Icons.calendar_month_rounded),
                label: context.l10n.schedule,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline_rounded),
                activeIcon: const Icon(Icons.person_rounded),
                label: context.l10n.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
