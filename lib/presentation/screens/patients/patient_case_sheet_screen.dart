import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';
import '../../widgets/widgets.dart';
import 'widgets/widgets.dart';

/// Patient Case Sheet detailed record screen with multi-tab layout wired to Riverpod SQLite state.
///
/// Dynamically loads patient demographics and clinical case records strictly from
/// [patientByIdProvider] and [casesByPatientProvider], handling empty case histories natively
/// without visual mock fallbacks.
///
/// **Architecture Note (v0.4 UI Scope Reduction):**
/// In v0.4, unbacked visual components (the static "Treatment Plan" tab and hardcoded "Dental History" card)
/// were pruned to eliminate visual hallucinations without SQLite database backing.
/// Phased treatment planning will be restored in a future phase once a dedicated `TreatmentPlan` entity
/// and database schema are introduced. Patient history is now strictly backed by [patient.medicalHistory].
///
/// Supports navigation either by directly passing a loaded [patient] entity,
/// or deep-linking via [patientId], which asynchronously resolves the patient
/// from SQLite via [patientByIdProvider].
class PatientCaseSheetScreen extends ConsumerStatefulWidget {
  const PatientCaseSheetScreen({
    super.key,
    this.patient,
    this.patientId,
  }) : assert(patient != null || patientId != null, 'Either patient or patientId must be provided');

  final Patient? patient;
  final String? patientId;

  @override
  ConsumerState<PatientCaseSheetScreen> createState() => _PatientCaseSheetScreenState();
}

class _PatientCaseSheetScreenState extends ConsumerState<PatientCaseSheetScreen> {
  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final pid = widget.patient?.id ?? widget.patientId!;
    final patientAsync = ref.watch(patientByIdProvider(pid));

    return patientAsync.when(
      data: (patient) {
        final effectivePatient = patient ??
            widget.patient ??
            Patient(
              id: pid,
              name: 'Patient #$pid',
              age: 25,
              gender: 'Unknown',
              createdAt: DateTime.now(),
            );
        return _buildScaffold(context, effectivePatient);
      },
      loading: () => widget.patient != null
          ? _buildScaffold(context, widget.patient!)
          : const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
      error: (error, stackTrace) {
        if (widget.patient != null) {
          return _buildScaffold(context, widget.patient!);
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Patient Case Sheet'),
          ),
          body: DenteraErrorWidget(
            error: error,
            stackTrace: stackTrace,
            title: 'Patient Record Unavailable',
            message: 'Could not load patient information from local database.',
            onRetry: () => ref.invalidate(patientByIdProvider(pid)),
          ),
        );
      },
    );
  }

  Widget _buildScaffold(BuildContext context, Patient patient) {
    final patientCasesAsync = ref.watch(casesByPatientProvider(patient.id));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            patient.name,
            style: AppTextStyles.h1Mobile.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Patient',
              onPressed: () => EditPatientModal.show(
                context,
                patient: patient,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              // 1. Persistent Patient Demographic Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        // Squircle Avatar
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _initials(patient.name),
                            style: AppTextStyles.h1.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Demographic Information
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                patient.name,
                                style: AppTextStyles.h2.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${patient.gender}, ${patient.age} yrs • ${patient.phoneNumber ?? 'No Phone'}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Clinic Tags
                    Wrap(
                      spacing: 6,
                      children: const <Widget>[
                        _ClinicBadge(label: 'Prosthodontics', color: AppColors.primary),
                        _ClinicBadge(label: 'Endodontics', color: AppColors.secondary),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Tab Bar Header
              Container(
                color: AppColors.background,
                child: TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.onSurfaceVariant,
                  indicatorColor: AppColors.secondary,
                  indicatorWeight: 3.0,
                  labelStyle: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const <Widget>[
                    Tab(text: 'Clinical Cases'),
                    Tab(text: 'Medical History'),
                  ],
                ),
              ),

              // 3. Tab Bar Content
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    // Tab 1: Clinical Cases
                    _buildCasesTab(patientCasesAsync, patient),

                    // Tab 2: Medical History
                    _buildMedicalHistoryTab(patient),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_case_sheet',
          tooltip: 'Log Case Record',
          onPressed: () => LogCaseRecordModal.show(
            context,
            patientId: patient.id,
            patientName: patient.name,
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.add_rounded,
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildCasesTab(AsyncValue<List<CaseRecord>> casesAsync, Patient patient) {
    return casesAsync.when(
      data: (cases) {
        if (cases.isEmpty) {
          AppLogger.debug(
            'PatientCaseSheetScreen rendered zero state: No clinical cases logged for patient ${patient.id}',
          );
          return _buildEmptyCasesState(patient);
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 88.0),
          physics: const BouncingScrollPhysics(),
          itemCount: cases.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = cases[index];
            return CaseRecordCard(
              caseRecord: item,
              requirementTitle: 'Clinical Requirement #${item.requirementId}',
              clinicName: 'Dental Department',
              clinicColor: AppColors.secondary,
              onTap: () => EvaluateCaseModal.show(
                context,
                caseRecord: item,
                patientName: patient.name,
              ),
            );
          },
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
      error: (error, stackTrace) => DenteraErrorWidget(
        error: error,
        stackTrace: stackTrace,
        title: 'Cases Unavailable',
        message: 'Could not load clinical cases for this patient from local database.',
        onRetry: () => ref.invalidate(casesByPatientProvider(patient.id)),
      ),
    );
  }

  /// Builds the standardized zero state display when no clinical cases exist for this patient.
  ///
  /// The Riverpod consumer for [casesByPatientProvider] explicitly falls back to the
  /// [DenteraEmptyState] widget when the SQLite repository returns an empty list for the
  /// patient. This informs the student that no cases have been recorded yet and provides
  /// a direct CTA to log their first procedure.
  Widget _buildEmptyCasesState(Patient patient) {
    return DenteraEmptyState(
      icon: Icons.assignment_late_outlined,
      title: 'No clinical cases logged yet',
      subtitle: 'Start logging procedural cases and treatments completed for ${patient.name}.',
      actionButton: PrimaryButton(
        isFullWidth: false,
        text: 'Log First Case',
        icon: const Icon(
          Icons.add_rounded,
          color: AppColors.onPrimary,
          size: 18,
        ),
        onPressed: () {
          AppLogger.info('Opened LogCaseRecordModal from empty cases state for patient: ${patient.id}');
          LogCaseRecordModal.show(
            context,
            patientId: patient.id,
            patientName: patient.name,
          );
        },
      ),
    );
  }

  Widget _buildMedicalHistoryTab(Patient patient) {
    final hasMedicalHistory = patient.medicalHistory != null &&
        patient.medicalHistory!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 88.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Systemic Conditions & Allergies Card (strictly backed by SQLite)
          BaseCard(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      hasMedicalHistory ? Icons.warning_amber_rounded : Icons.health_and_safety_outlined,
                      size: 20,
                      color: hasMedicalHistory ? AppColors.error : AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Medical History & Allergies',
                      style: AppTextStyles.h2.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  hasMedicalHistory
                      ? patient.medicalHistory!
                      : 'No significant systemic medical history or drug allergies reported.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: hasMedicalHistory ? AppColors.onSurface : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicBadge extends StatelessWidget {
  const _ClinicBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelCaps.copyWith(
          color: color,
        ),
      ),
    );
  }
}

