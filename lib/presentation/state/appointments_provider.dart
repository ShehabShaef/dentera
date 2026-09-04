import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database_providers.dart';
import '../../domain/entities/entities.dart';

/// Currently selected date in the Appointments Timeline.
final selectedScheduleDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Provides scheduled appointments for a specific date from SQLite.
///
/// **Error Propagation Architecture:**
/// Database exceptions are allowed to bubble up naturally into Riverpod's [FutureProvider.family].
/// Rather than returning `<Appointment>[]` on error (which misled users into believing no patients
/// were scheduled), [AsyncError] enables the timeline to render a distinct error card with a retry button.
final dailyAppointmentsProvider =
    FutureProvider.family<List<Appointment>, DateTime>((ref, date) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return await repository.getAppointmentsByDate(date);
});

/// Provides all appointments recorded in the local database.
///
/// **Error Propagation Architecture:**
/// Database exceptions propagate to Riverpod's [FutureProvider] wrapped in [AsyncError].
final allAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return await repository.getAllAppointments();
});

/// Provides upcoming appointments from tomorrow onward.
///
/// **Error Propagation Architecture:**
/// Exceptions from [AppointmentRepository.getAllAppointments] propagate directly,
/// allowing dashboard sections to render error states and retry buttons.
final upcomingAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final allApts = await ref.watch(appointmentRepositoryProvider).getAllAppointments();
  final now = DateTime.now();
  final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

  return allApts.where((apt) => apt.scheduledDate.isAfter(todayEnd)).toList();
});
