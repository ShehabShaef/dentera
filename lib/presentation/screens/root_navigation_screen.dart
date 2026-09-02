import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme.dart';
import 'appointments/appointments_screen.dart';
import 'clinics/clinics_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'patients/patients_screen.dart';
import 'profile/profile_screen.dart';

/// Root navigation screen maintaining an IndexedStack across the five core tabs.
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
  late int _currentIndex;

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
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
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
            currentIndex: _currentIndex,
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
