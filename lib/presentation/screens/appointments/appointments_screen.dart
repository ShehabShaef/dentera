import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../data/database/database_providers.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';
import '../../widgets/widgets.dart';
import 'widgets/widgets.dart';

/// Clinical schedule timeline screen providing reactive, offline-first appointment tracking.
///
/// **Riverpod State Reactivity:**
/// This screen watches [dailyAppointmentsProvider] parameterized by [_selectedDate].
/// Whenever the user selects a new date on the [DateSelectorStrip], [_selectedDate] updates,
/// which automatically triggers Riverpod to fetch the relevant appointments from the local
/// SQLite database for that specific calendar day.
///
/// **AsyncValue State Handling:**
/// - `loading`: Displays a centered [CircularProgressIndicator] while the local SQLite query executes.
/// - `data`: If empty, renders a clean zero-state prompt ([_buildEmptyState]) inviting the user
///   to schedule a new patient. If populated, splits the appointments into a highlighted "Next Up" card
///   and a chronological timeline using [TimelineAppointmentCard].
/// - `error`: Gracefully catches and logs errors via [AppLogger.error] while presenting the empty state
///   to prevent clinical workflow disruptions.
class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // Watch daily appointments for the currently selected calendar date
    final appointmentsAsync = ref.watch(dailyAppointmentsProvider(_selectedDate));

    // Watch registered patients and clinics for relational display mapping
    final patientsAsync = ref.watch(patientListProvider);
    final clinicsAsync = ref.watch(clinicListProvider);

    final patientsMap = {
      for (final p in patientsAsync.valueOrNull ?? const <Patient>[]) p.id: p,
    };
    final clinicsMap = {
      for (final c in clinicsAsync.valueOrNull ?? const <Clinic>[]) c.id: c,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Appointments',
          style: AppTextStyles.h1Mobile.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Phase 5.5 - Navigate to Profile & Settings
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 1. Horizontal Date Selector Strip
                  DateSelectorStrip(
                    selectedDate: _selectedDate,
                    onDateSelected: (date) {
                      AppLogger.info(
                        '[AppointmentsScreen] User navigated timeline to: '
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                      );
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // 2. Reactive Appointments Content
                  appointmentsAsync.when(
                    data: (appointments) {
                      AppLogger.debug(
                        '[AppointmentsScreen] Loaded ${appointments.length} appointments for date: '
                        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                      );

                      if (appointments.isEmpty) {
                        return _buildEmptyState();
                      }

                      // Sort chronologically by scheduled time
                      final sorted = List<Appointment>.from(appointments)
                        ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

                      final nextUpAppointment = sorted.first;
                      final laterAppointments = sorted.skip(1).toList();

                      final nextUpPatientName =
                          patientsMap[nextUpAppointment.patientId]?.name ??
                              'Patient #${nextUpAppointment.patientId}';
                      final nextUpClinic = clinicsMap[nextUpAppointment.clinicId];
                      final nextUpClinicName = nextUpClinic?.name ?? 'General Clinic';
                      final nextUpTimeWindow = _formatTimeWindow(nextUpAppointment.scheduledDate);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // "Next Up" Highlight Card
                          Text(
                            'Next Up',
                            style: AppTextStyles.h2.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildNextUpCard(
                            appointment: nextUpAppointment,
                            patientName: nextUpPatientName,
                            clinicName: nextUpClinicName,
                            timeWindow: nextUpTimeWindow,
                          ),
                          const SizedBox(height: 24),

                          // "Later Today" Chronological Timeline
                          if (laterAppointments.isNotEmpty) ...<Widget>[
                            Text(
                              'Later Today',
                              style: AppTextStyles.h2.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: laterAppointments.length,
                              itemBuilder: (context, index) {
                                final apt = laterAppointments[index];
                                final isLast = index == laterAppointments.length - 1;
                                final patientName =
                                    patientsMap[apt.patientId]?.name ??
                                        'Patient #${apt.patientId}';
                                final clinic = clinicsMap[apt.clinicId];
                                final clinicName = clinic?.name ?? 'General Clinic';
                                final clinicColor = _parseColor(
                                  clinic?.colorHex,
                                  fallback: AppColors.secondary,
                                );
                                final timeFormatted = _formatTime(apt.scheduledDate);

                                return TimelineAppointmentCard(
                                  appointment: apt,
                                  patientName: patientName,
                                  clinicName: clinicName,
                                  timeFormatted: timeFormatted,
                                  clinicColor: clinicColor,
                                  isLast: isLast,
                                  onTap: () {
                                    // TODO: Phase 6.2 - Open Case Sheet
                                  },
                                );
                              },
                            ),
                          ],
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 48.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ),
                    error: (error, stackTrace) {
                      AppLogger.error(
                        '[AppointmentsScreen] Failed to retrieve appointments for date $_selectedDate: $error',
                        error,
                        stackTrace,
                      );
                      return DenteraErrorState(
                        title: 'Failed to load schedule',
                        message: error.toString(),
                        onRetry: () => ref.invalidate(dailyAppointmentsProvider(_selectedDate)),
                      );
                    },
                  ),

                  const SizedBox(height: 80), // Padding for FAB
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_appointments',
        onPressed: _openScheduleAppointmentModal,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.edit_calendar_rounded,
          size: 26,
        ),
      ),
    );
  }

  /// Opens the appointment creation modal and invalidates providers upon insertion.
  Future<void> _openScheduleAppointmentModal() async {
    await ScheduleAppointmentModal.show(
      context,
      initialDate: _selectedDate,
      onAppointmentScheduled: (newApt) async {
        try {
          await ref.read(appointmentRepositoryProvider).addAppointment(newApt);
        } catch (_) {}
        ref.invalidate(dailyAppointmentsProvider(_selectedDate));
        ref.invalidate(allAppointmentsProvider);
        ref.invalidate(upcomingAppointmentsProvider);
      },
    );
    if (mounted) {
      ref.invalidate(dailyAppointmentsProvider(_selectedDate));
    }
  }

  Widget _buildNextUpCard({
    required Appointment appointment,
    required String patientName,
    required String clinicName,
    required String timeWindow,
  }) {
    return BaseCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    timeWindow,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    patientName,
                    style: AppTextStyles.h1Mobile.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  appointment.status,
                  style: AppTextStyles.labelCaps.copyWith(
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const Icon(
                Icons.medical_services_outlined,
                size: 18,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$clinicName${appointment.procedureDescription != null && appointment.procedureDescription!.isNotEmpty ? ' - ${appointment.procedureDescription}' : ''}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            text: 'Open Case Sheet',
            height: 42,
            borderColor: AppColors.outlineVariant,
            onPressed: () {
              // TODO: Phase 6.2 - Open Patient Case Sheet
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerHigh,
              ),
              child: const Icon(
                Icons.event_available_outlined,
                size: 36,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No appointments scheduled',
              style: AppTextStyles.h2.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enjoy your day off or schedule a new patient.',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              isFullWidth: false,
              text: 'Schedule Patient',
              icon: const Icon(
                Icons.add_rounded,
                color: AppColors.onPrimary,
                size: 18,
              ),
              onPressed: _openScheduleAppointmentModal,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
  }

  String _formatTimeWindow(DateTime dateTime) {
    final start = _formatTime(dateTime);
    final end = _formatTime(dateTime.add(const Duration(minutes: 90)));
    return '$start - $end';
  }

  Color _parseColor(String? hexString, {Color fallback = AppColors.secondary}) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final hex = hexString.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('0xFF$hex'));
      } else if (hex.length == 8) {
        return Color(int.parse('0x$hex'));
      }
    } catch (_) {}
    return fallback;
  }
}
