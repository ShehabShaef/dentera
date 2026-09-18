import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../data/repositories/preferences_repository.dart';
import '../../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/widgets.dart';
import '../patients/patient_case_sheet_screen.dart';
import 'widgets/widgets.dart';

/// Main command center dashboard screen for Dentera wired to Riverpod SQLite state.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsRepo = ref.watch(preferencesRepositoryProvider);
    final quotaSummaryAsync = ref.watch(globalQuotaSummaryProvider);
    final allReqsAsync = ref.watch(allRequirementsProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayAppointmentsAsync = ref.watch(dailyAppointmentsProvider(today));
    final upcomingAppointmentsAsync = ref.watch(upcomingAppointmentsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
                          AppLogger.info('Switching root tab to Profile');
                          ref.read(rootNavigationIndexProvider.notifier).state = 4;
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
                            orElse: () => const <ClinicQuotaSummary>[],
                          );

                          return DashboardProgressCard(
                            overallProgress: stats.totalTarget > 0 ? stats.progressFraction : 0.0,
                            overallPercentageText: stats.totalTarget > 0
                                ? '${(stats.progressFraction * 100).round()}%'
                                : '0%',
                            requirements: breakdowns,
                          );
                        },
                        loading: () => const DashboardProgressCard(),
                        error: (error, stackTrace) => DenteraErrorWidget(
                          error: error,
                          stackTrace: stackTrace,
                          isCompact: true,
                          title: 'Quota Statistics Unavailable',
                          message: 'Could not retrieve departmental progress.',
                          onRetry: () {
                            ref.invalidate(globalQuotaSummaryProvider);
                            ref.invalidate(allRequirementsProvider);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. Up Next Appointment Section
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.schedule_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.upNext,
                            style: AppTextStyles.h2.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      todayAppointmentsAsync.when(
                        data: (appointments) {
                          if (appointments.isEmpty) {
                            AppLogger.debug('Dashboard screen rendering zero state - SQLite returned 0 appointments today');
                            return BaseCard(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark ? AppDarkColors.surfaceContainerHighest : AppColors.surfaceContainerHigh,
                                    ),
                                    child: Icon(
                                      Icons.event_available_outlined,
                                      size: 22,
                                      color: isDark ? AppDarkColors.textMuted : AppColors.outline,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                         Text(
                                           context.l10n.noAppointmentsToday,
                                           style: AppTextStyles.bodyMd.copyWith(
                                             fontWeight: FontWeight.w600,
                                             color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                                           ),
                                         ),
                                         const SizedBox(height: 2),
                                         Text(
                                           context.l10n.scheduledProceduresAppearHere,
                                           style: AppTextStyles.caption.copyWith(
                                             color: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
                                           ),
                                         ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
                              AppLogger.info('Navigating to Patient Case Sheet for patient: ${firstApt.patientId}');
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => PatientCaseSheetScreen(
                                    patientId: firstApt.patientId,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        ),
                        error: (error, stackTrace) => DenteraErrorWidget(
                          error: error,
                          stackTrace: stackTrace,
                          isCompact: true,
                          title: 'Appointments Unavailable',
                          message: 'Could not load today\'s scheduled appointments.',
                          onRetry: () => ref.invalidate(dailyAppointmentsProvider(today)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 4. Clinical Reminders Section
                      const DashboardReminders(),
                      const SizedBox(height: 24),

                      // 5. Tomorrow's Patients Section
                      upcomingAppointmentsAsync.when(
                        data: (upcomingList) {
                          if (upcomingList.isEmpty) {
                            AppLogger.debug('Dashboard screen rendering zero state - SQLite returned 0 upcoming appointments');
                          }

                          final List<UpcomingPatientItem> upcomingItems = upcomingList
                              .map((apt) => UpcomingPatientItem(
                                    patientId: apt.patientId,
                                    name: 'Patient #${apt.patientId}',
                                    timeAndClinic:
                                        '${apt.scheduledDate.hour}:${apt.scheduledDate.minute.toString().padLeft(2, '0')} • ${apt.procedureDescription ?? 'Clinic'}',
                                    accentColor: AppColors.primary,
                                  ))
                              .toList();

                          return DashboardUpcomingSection(
                            patients: upcomingItems,
                            onViewFullSchedule: () {
                              AppLogger.info('Switching root tab to Appointments');
                              ref.read(rootNavigationIndexProvider.notifier).state = 3;
                            },
                            onPatientTap: (patient) {
                              if (patient.patientId == null) return;
                              AppLogger.info('Navigating to Patient Case Sheet for patient: ${patient.patientId}');
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => PatientCaseSheetScreen(
                                    patientId: patient.patientId!,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const DashboardUpcomingSection(),
                        error: (error, stackTrace) => DenteraErrorWidget(
                          error: error,
                          stackTrace: stackTrace,
                          isCompact: true,
                          title: 'Upcoming Patients Unavailable',
                          message: 'Could not retrieve tomorrow\'s patient schedule.',
                          onRetry: () => ref.invalidate(upcomingAppointmentsProvider),
                        ),
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
        backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor ?? (isDark ? AppDarkColors.primaryTeal : AppColors.primary),
        foregroundColor: Theme.of(context).floatingActionButtonTheme.foregroundColor ?? (isDark ? AppDarkColors.onPrimary : AppColors.onPrimary),
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
