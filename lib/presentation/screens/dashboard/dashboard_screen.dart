import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../data/repositories/preferences_repository.dart';
import '../../state/state.dart';
import '../../widgets/widgets.dart';
import 'widgets/widgets.dart';

/// Main command center dashboard screen for Dentera wired to Riverpod SQLite state.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsRepo = ref.watch(preferencesRepositoryProvider);
    final quotaSummaryAsync = ref.watch(globalQuotaSummaryProvider);
    final allReqsAsync = ref.watch(allRequirementsProvider);
    final todayAppointmentsAsync = ref.watch(dailyAppointmentsProvider(DateTime.now()));
    final upcomingAppointmentsAsync = ref.watch(upcomingAppointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<Map<String, String?>>(
          future: Future.wait([
            prefsRepo.getDoctorName(),
            prefsRepo.getAcademicYear(),
          ]).then((results) => {
                'name': results[0],
                'year': results[1],
              }),
          builder: (context, snapshot) {
            final doctorName = snapshot.data?['name'] ?? 'Doctor';
            final academicYear = snapshot.data?['year'] ?? '5th Year';

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // 1. Header Section
                      DashboardHeader(
                        doctorName: doctorName,
                        academicYear: academicYear,
                        onAvatarTap: () {
                          // TODO: Phase 5.5 - Navigate to Profile & Settings
                        },
                      ),
                      const SizedBox(height: 20),

                      // 2. Progress Overview Card
                      quotaSummaryAsync.when(
                        data: (stats) {
                          final List<ClinicQuotaSummary> breakdowns = allReqsAsync.maybeWhen(
                            data: (reqs) => reqs
                                .take(2)
                                .map((r) => ClinicQuotaSummary(
                                      clinicName: r.title,
                                      completed: r.completedCount,
                                      total: r.targetCount,
                                    ))
                                .toList(),
                            orElse: () => const <ClinicQuotaSummary>[
                              ClinicQuotaSummary(clinicName: 'Prosthodontics', completed: 8, total: 10),
                              ClinicQuotaSummary(clinicName: 'Endodontics', completed: 4, total: 5),
                            ],
                          );

                          return DashboardProgressCard(
                            overallProgress: stats.totalTarget > 0 ? stats.progressFraction : 0.68,
                            overallPercentageText: stats.totalTarget > 0
                                ? '${(stats.progressFraction * 100).round()}%'
                                : '68%',
                            requirements: breakdowns.isNotEmpty
                                ? breakdowns
                                : const <ClinicQuotaSummary>[
                                    ClinicQuotaSummary(clinicName: 'Prosthodontics', completed: 8, total: 10),
                                    ClinicQuotaSummary(clinicName: 'Endodontics', completed: 4, total: 5),
                                  ],
                          );
                        },
                        loading: () => const DashboardProgressCard(),
                        error: (_, _) => const DashboardProgressCard(),
                      ),
                      const SizedBox(height: 24),

                      // 3. Up Next Appointment Section
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.schedule_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Up Next',
                            style: AppTextStyles.h2.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      todayAppointmentsAsync.when(
                        data: (appointments) {
                          if (appointments.isEmpty) {
                            return DashboardAppointmentCard(
                              patientName: 'Ali Nasser',
                              patientId: 'PT-2049',
                              patientDetails: 'Male • 45 Y',
                              timeWindow: '10:30 AM - 12:00 PM',
                              procedureTitle: 'Prosthodontics - Metal Denture',
                              clinicColor: AppColors.secondary,
                              onViewCase: () {
                                // TODO: Phase 6.2 - Open Patient Case Sheet
                              },
                            );
                          }

                          final firstApt = appointments.first;
                          return DashboardAppointmentCard(
                            patientName: 'Patient #${firstApt.patientId}',
                            patientId: firstApt.patientId,
                            patientDetails: firstApt.status,
                            timeWindow: '${firstApt.scheduledDate.hour}:${firstApt.scheduledDate.minute.toString().padLeft(2, '0')}',
                            procedureTitle: firstApt.procedureDescription ?? 'Clinical Procedure',
                            clinicColor: AppColors.secondary,
                            onViewCase: () {
                              // TODO: Phase 6.2 - Open Patient Case Sheet
                            },
                          );
                        },
                        loading: () => DashboardAppointmentCard(
                          patientName: 'Ali Nasser',
                          patientId: 'PT-2049',
                          patientDetails: 'Male • 45 Y',
                          timeWindow: '10:30 AM - 12:00 PM',
                          procedureTitle: 'Prosthodontics - Metal Denture',
                          clinicColor: AppColors.secondary,
                          onViewCase: () {},
                        ),
                        error: (_, _) => DashboardAppointmentCard(
                          patientName: 'Ali Nasser',
                          patientId: 'PT-2049',
                          patientDetails: 'Male • 45 Y',
                          timeWindow: '10:30 AM - 12:00 PM',
                          procedureTitle: 'Prosthodontics - Metal Denture',
                          clinicColor: AppColors.secondary,
                          onViewCase: () {},
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 4. Clinical Reminders Section
                      const DashboardReminders(),
                      const SizedBox(height: 24),

                      // 5. Tomorrow's Patients Section
                      upcomingAppointmentsAsync.when(
                        data: (upcomingList) {
                          final List<UpcomingPatientItem> upcomingItems = upcomingList.isNotEmpty
                              ? upcomingList
                                  .map((apt) => UpcomingPatientItem(
                                        name: 'Patient #${apt.patientId}',
                                        timeAndClinic:
                                            '${apt.scheduledDate.hour}:${apt.scheduledDate.minute.toString().padLeft(2, '0')} • ${apt.procedureDescription ?? 'Clinic'}',
                                        accentColor: AppColors.primary,
                                      ))
                                  .toList()
                              : const <UpcomingPatientItem>[
                                  UpcomingPatientItem(
                                    name: 'Sara Ahmed',
                                    timeAndClinic: '09:00 AM • Endo',
                                    accentColor: AppColors.primary,
                                  ),
                                  UpcomingPatientItem(
                                    name: 'Omar Khalid',
                                    timeAndClinic: '11:30 AM • Prosth',
                                    accentColor: AppColors.secondary,
                                  ),
                                  UpcomingPatientItem(
                                    name: 'Lina Mahmoud',
                                    timeAndClinic: '01:00 PM • Checkup',
                                    accentColor: AppColors.tertiary,
                                  ),
                                ];

                          return DashboardUpcomingSection(
                            patients: upcomingItems,
                            onViewFullSchedule: () {
                              // TODO: Phase 5.4 - Navigate to Appointments Timeline
                            },
                            onPatientTap: (patient) {
                              // TODO: Phase 6.2 - Open Patient Case Sheet
                            },
                          );
                        },
                        loading: () => const DashboardUpcomingSection(),
                        error: (_, _) => const DashboardUpcomingSection(),
                      ),
                      const SizedBox(height: 80), // Padding for floating action button
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_dashboard',
        onPressed: () {
          AddPatientModal.show(
            context,
            onPatientAdded: (_) {
              ref.invalidate(patientListProvider);
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
          Icons.add_rounded,
          size: 28,
        ),
      ),
    );
  }
}
