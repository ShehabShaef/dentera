import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../domain/entities/entities.dart';
import '../../widgets/widgets.dart';
import 'widgets/widgets.dart';

/// Clinical schedule timeline screen.
class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  DateTime _selectedDate = DateTime.now();

  // Mock appointments dataset (ready for SQLite injection in Phase 7)
  final List<Map<String, dynamic>> _mockAppointments = [
    {
      'appointment': Appointment(
        id: 'apt-01',
        patientId: 'PT-2049',
        clinicId: 'clinic-surgery',
        scheduledDate: DateTime.now().copyWith(hour: 10, minute: 30),
        status: 'Confirmed',
        procedureDescription: 'Extraction - Tooth 38',
      ),
      'patientName': 'Ali Nasser',
      'clinicName': 'Oral Surgery',
      'timeWindow': '10:30 AM - 12:00 PM',
      'timeFormatted': '10:30 AM',
      'clinicColor': AppColors.error,
      'isNextUp': true,
    },
    {
      'appointment': Appointment(
        id: 'apt-02',
        patientId: 'PT-1002',
        clinicId: 'clinic-pediatric',
        scheduledDate: DateTime.now().copyWith(hour: 13, minute: 0),
        status: 'Scheduled',
        procedureDescription: 'Pediatric Care',
      ),
      'patientName': 'Sarah Jenkins',
      'clinicName': 'Pediatric Dentistry',
      'timeWindow': '01:00 PM - 02:30 PM',
      'timeFormatted': '01:00 PM',
      'clinicColor': AppColors.secondary,
      'isNextUp': false,
    },
    {
      'appointment': Appointment(
        id: 'apt-03',
        patientId: 'PT-1003',
        clinicId: 'clinic-endo',
        scheduledDate: DateTime.now().copyWith(hour: 15, minute: 30),
        status: 'Scheduled',
        procedureDescription: 'Root Canal Therapy',
      ),
      'patientName': 'Michael Chang',
      'clinicName': 'Endodontics',
      'timeWindow': '03:30 PM - 05:00 PM',
      'timeFormatted': '03:30 PM',
      'clinicColor': AppColors.primary,
      'isNextUp': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // For demo purposes, show appointments if today, otherwise allow toggling
    final isToday = _selectedDate.day == DateTime.now().day &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.year == DateTime.now().year;

    final appointmentsForDay = isToday ? _mockAppointments : <Map<String, dynamic>>[];
    final nextUpAppointment = appointmentsForDay.where((a) => a['isNextUp'] == true).firstOrNull;
    final laterAppointments = appointmentsForDay.where((a) => a['isNextUp'] != true).toList();

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
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  if (appointmentsForDay.isEmpty)
                    _buildEmptyState()
                  else ...<Widget>[
                    // 2. "Next Up" Appointment Highlight Card
                    if (nextUpAppointment != null) ...<Widget>[
                      Text(
                        'Next Up',
                        style: AppTextStyles.h2.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildNextUpCard(nextUpAppointment),
                      const SizedBox(height: 24),
                    ],

                    // 3. "Later Today" Chronological Timeline
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
                          final item = laterAppointments[index];
                          final isLast = index == laterAppointments.length - 1;

                          return TimelineAppointmentCard(
                            appointment: item['appointment'] as Appointment,
                            patientName: item['patientName'] as String,
                            clinicName: item['clinicName'] as String,
                            timeFormatted: item['timeFormatted'] as String,
                            clinicColor: item['clinicColor'] as Color? ?? AppColors.secondary,
                            isLast: isLast,
                            onTap: () {
                              // TODO: Phase 6.2 - Open Case Sheet
                            },
                          );
                        },
                      ),
                    ],
                  ],
                  const SizedBox(height: 80), // Padding for FAB
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_appointments',
        onPressed: () {
          ScheduleAppointmentModal.show(
            context,
            initialDate: _selectedDate,
            onAppointmentScheduled: (newApt) {
              setState(() {
                _mockAppointments.add({
                  'appointment': newApt,
                  'patientName': 'Sara Ahmed',
                  'clinicName': 'Prosthodontics',
                  'clinicColor': AppColors.secondary,
                });
              });
            },
          );
        },
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

  Widget _buildNextUpCard(Map<String, dynamic> item) {
    final appointment = item['appointment'] as Appointment;
    final patientName = item['patientName'] as String;
    final clinicName = item['clinicName'] as String;
    final timeWindow = item['timeWindow'] as String;

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
              Text(
                '$clinicName${appointment.procedureDescription != null && appointment.procedureDescription!.isNotEmpty ? ' - ${appointment.procedureDescription}' : ''}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.onSurfaceVariant,
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
              onPressed: () {
                ScheduleAppointmentModal.show(
                  context,
                  initialDate: _selectedDate,
                  onAppointmentScheduled: (newApt) {
                    setState(() {
                      _mockAppointments.add({
                        'appointment': newApt,
                        'patientName': 'Sara Ahmed',
                        'clinicName': 'Prosthodontics',
                        'clinicColor': AppColors.secondary,
                      });
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
