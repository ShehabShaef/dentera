import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../domain/entities/entities.dart';
import '../../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/widgets.dart';
import '../patients/patient_case_sheet_screen.dart';
import 'widgets/widgets.dart';

/// Clinical schedule timeline screen providing reactive, offline-first appointment tracking.
///
/// ### Routing Mechanisms:
/// 1. **State-Driven Tab Switching (Riverpod):**
///    Tapping the AppBar settings icon mutates [rootNavigationIndexProvider] to index `4`
///    (Profile tab). This activates the Profile screen within the root [IndexedStack],
///    preserving the active schedule scroll position and loaded timeline state without
///    manipulating the imperative [Navigator] history.
///
/// 2. **Stack-Based Deep Link Routing ([Navigator.push]):**
///    Tapping "Open Case Sheet" on the Next Up card or tapping any [TimelineAppointmentCard]
///    pushes [PatientCaseSheetScreen] onto the [Navigator] stack with the corresponding
///    `patientId` and [Patient] entity. This isolates clinical case workflows and
///    ensures predictable back-button / back-gesture popping to the timeline.
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
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.appointments,
          style: AppTextStyles.h1Mobile.copyWith(
            color: isDark ? AppDarkColors.textPrimary : AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
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
                        _selectedDate = DateTime(date.year, date.month, date.day);
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
                        AppLogger.debug(
                          'AppointmentsScreen rendered zero state: No appointments scheduled for selected timeline date $_selectedDate',
                        );
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
                            context.l10n.nextUp,
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
                            patient: patientsMap[nextUpAppointment.patientId],
                          ),
                          const SizedBox(height: 24),

                          // "Later Today" Chronological Timeline
                          if (laterAppointments.isNotEmpty) ...<Widget>[
                            Text(
                              context.l10n.laterToday,
                              style: AppTextStyles.h2.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: laterAppointments.length,
                              itemBuilder: (_, index) {
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

                                return Dismissible(
                                  key: ValueKey('apt_dismiss_${apt.id}'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20.0),
                                    margin: const EdgeInsets.only(bottom: 16.0),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      color: AppColors.onError,
                                      size: 24,
                                    ),
                                  ),
                                  confirmDismiss: (direction) =>
                                      _confirmDeleteAppointment(context, apt, patientName),
                                  onDismissed: (direction) async {
                                    final deletedMessage = context.l10n.appointmentDeleted;
                                    await ref
                                        .read(appointmentsNotifierProvider.notifier)
                                        .deleteAppointment(
                                          apt.id,
                                          scheduledDate: apt.scheduledDate,
                                        );
                                    if (mounted) {
                                      ref.invalidate(dailyAppointmentsProvider(_selectedDate));
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        SnackBar(content: Text(deletedMessage)),
                                      );
                                    }
                                  },
                                  child: TimelineAppointmentCard(
                                    appointment: apt,
                                    patientName: patientName,
                                    clinicName: clinicName,
                                    timeFormatted: timeFormatted,
                                    clinicColor: clinicColor,
                                    isLast: isLast,
                                    onTap: () {
                                      AppLogger.info('Navigating to Patient Case Sheet for patient: ${apt.patientId}');
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (context) => PatientCaseSheetScreen(
                                            patientId: apt.patientId,
                                            patient: patientsMap[apt.patientId],
                                          ),
                                        ),
                                      );
                                    },
                                    onEdit: () => _editAppointment(apt),
                                    onDelete: () => _handleDeleteAppointment(apt, patientName),
                                  ),
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
        backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor ?? (isDark ? AppDarkColors.primaryTeal : AppColors.primary),
        foregroundColor: Theme.of(context).floatingActionButtonTheme.foregroundColor ?? (isDark ? AppDarkColors.onPrimary : AppColors.onPrimary),
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
      onAppointmentScheduled: (newApt) {
        ref.invalidate(dailyAppointmentsProvider(_selectedDate));
        ref.invalidate(allAppointmentsProvider);
        ref.invalidate(upcomingAppointmentsProvider);
      },
    );
    if (mounted) {
      ref.invalidate(dailyAppointmentsProvider(_selectedDate));
    }
  }

  Future<void> _editAppointment(Appointment apt) async {
    await EditAppointmentModal.show(context, appointment: apt);
  }

  Future<bool> _confirmDeleteAppointment(
    BuildContext context,
    Appointment apt,
    String patientName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteAppointment),
        content: Text(
          'Are you sure you want to delete this appointment for $patientName? This action cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              context.l10n.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<void> _handleDeleteAppointment(
    Appointment apt,
    String patientName,
  ) async {
    final confirmed = await _confirmDeleteAppointment(context, apt, patientName);
    if (confirmed && mounted) {
      await ref.read(appointmentsNotifierProvider.notifier).deleteAppointment(
            apt.id,
            scheduledDate: apt.scheduledDate,
          );
      if (mounted) {
        ref.invalidate(dailyAppointmentsProvider(_selectedDate));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.appointmentDeleted)),
        );
      }
    }
  }

  Widget _buildNextUpCard({
    required Appointment appointment,
    required String patientName,
    required String clinicName,
    required String timeWindow,
    Patient? patient,
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
              Row(
                children: <Widget>[
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
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: AppColors.onSurfaceVariant,
                    ),
                    tooltip: context.l10n.editAppointment,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => _editAppointment(appointment),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: AppColors.onSurfaceVariant,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: context.l10n.appointmentActions,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editAppointment(appointment);
                      } else if (value == 'delete') {
                        _handleDeleteAppointment(appointment, patientName);
                      }
                    },
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 18, color: AppColors.onSurface),
                            const SizedBox(width: 8),
                            Text(context.l10n.editAppointment),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                            const SizedBox(width: 8),
                            Text(
                              context.l10n.deleteAppointment,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
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
            text: context.l10n.openCaseSheet,
            height: 42,
            borderColor: AppColors.outlineVariant,
            onPressed: () {
              final patientId = appointment.patientId;
              AppLogger.info('Navigating to Patient Case Sheet for patient: $patientId');
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => PatientCaseSheetScreen(
                    patientId: patientId,
                    patient: patient,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Builds the standardized zero state display when no appointments are scheduled.
  ///
  /// The Riverpod consumer for [dailyAppointmentsProvider] explicitly falls back to the
  /// [DenteraEmptyState] widget when the SQLite repository returns an empty list for the
  /// selected date. This provides clear guidance and a direct action to schedule a patient.
  Widget _buildEmptyState() {
    return DenteraEmptyState(
      icon: Icons.event_available_outlined,
      title: context.l10n.noAppointmentsScheduled,
      subtitle: 'Enjoy your day off or schedule a new patient.',
      actionButton: PrimaryButton(
        isFullWidth: false,
        text: context.l10n.schedulePatient,
        icon: const Icon(
          Icons.add_rounded,
          color: AppColors.onPrimary,
          size: 18,
        ),
        onPressed: _openScheduleAppointmentModal,
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
