import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider tracking the currently selected bottom navigation index in [RootNavigationScreen].
///
/// **Navigation Tab Indices:**
/// - `0`: Dashboard (`DashboardScreen`) - Main clinical overview and quick actions.
/// - `1`: Clinics (`ClinicsScreen`) - Departmental requirements and progress.
/// - `2`: Patients (`PatientsScreen`) - Master roster of clinical patients.
/// - `3`: Schedule / Appointments (`AppointmentsScreen`) - Daily and upcoming appointment agenda.
/// - `4`: Profile & Settings (`ProfileScreen`) - Student clinician profile and configurations.
///
/// **Routing Mechanism:**
/// Modifying this provider triggers a reactive rebuild of [RootNavigationScreen],
/// changing the active child inside the root [IndexedStack] without altering the
/// [Navigator] history stack. This allows child screens (e.g. Dashboard) to request
/// global tab switches declaratively via Riverpod.
final rootNavigationIndexProvider = StateProvider<int>((ref) => 0);
