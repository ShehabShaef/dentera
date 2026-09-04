import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../core/theme/theme.dart';
import '../state/state.dart';
import 'appointments/appointments_screen.dart';
import 'clinics/clinics_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'patients/patients_screen.dart';
import 'profile/profile_screen.dart';

/// Root navigation screen maintaining an [IndexedStack] across the five core tabs.
///
/// ### Routing Mechanisms in Dentera:
/// 1. **Tab Switching via Riverpod (`rootNavigationIndexProvider`):**
///    The 5 core tabs (Dashboard, Clinics, Patients, Schedule, Profile) reside inside
///    an [IndexedStack]. This preserves screen scroll positions, cached form states,
///    and sub-widget lifecycles across tab changes. Any child widget in the application
///    tree can declaratively switch the active tab without needing [BuildContext]
///    route lookups by mutating [rootNavigationIndexProvider].
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
    // If an initialIndex other than the default was passed, sync the Riverpod provider.
    if (widget.initialIndex != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(rootNavigationIndexProvider.notifier).state = widget.initialIndex;
        }
      });
    }
  }

  void _onTabSelected(int index) {
    if (ref.read(rootNavigationIndexProvider) != index) {
      AppLogger.info('Switching root tab to index: $index');
      ref.read(rootNavigationIndexProvider.notifier).state = index;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(rootNavigationIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
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
            backgroundColor: AppColors.surfaceContainerLowest,
            selectedItemColor: AppColors.secondary,
            unselectedItemColor: AppColors.onSurfaceVariant,
            selectedLabelStyle: AppTextStyles.labelCaps.copyWith(
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: AppTextStyles.labelCaps.copyWith(
              fontWeight: FontWeight.w500,
            ),
            elevation: 0,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.medical_services_outlined),
                activeIcon: Icon(Icons.medical_services_rounded),
                label: 'Clinics',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline_rounded),
                activeIcon: Icon(Icons.people_rounded),
                label: 'Patients',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_month_rounded),
                label: 'Schedule',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
