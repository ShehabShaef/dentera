import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database_providers.dart';
import '../../domain/entities/entities.dart';

/// Currently selected date in the Appointments Timeline.
final selectedScheduleDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Provides scheduled appointments for a specific date from SQLite.
final dailyAppointmentsProvider =
    FutureProvider.family<List<Appointment>, DateTime>((ref, date) async {
  try {
    final repository = ref.watch(appointmentRepositoryProvider);
    return await repository.getAppointmentsByDate(date);
  } catch (_) {
    return <Appointment>[];
  }
});

/// Provides all appointments recorded in the local database.
final allAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  try {
    final repository = ref.watch(appointmentRepositoryProvider);
    return await repository.getAllAppointments();
  } catch (_) {
    return <Appointment>[];
  }
});

/// Provides upcoming appointments from tomorrow onward.
final upcomingAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  try {
    final allApts = await ref.watch(appointmentRepositoryProvider).getAllAppointments();
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return allApts.where((apt) => apt.scheduledDate.isAfter(todayEnd)).toList();
  } catch (_) {
    return <Appointment>[];
  }
});
