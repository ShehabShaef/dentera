import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../../data/database/database_providers.dart';
import '../../../domain/entities/entities.dart';
import '../../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/widgets.dart';
import 'widgets/widgets.dart';

/// Patient Case Sheet detailed record screen with multi-tab layout wired to Riverpod SQLite state.
///
/// Dynamically loads patient demographics and clinical case records strictly from
/// [patientByIdProvider] and [casesByPatientProvider], handling empty case histories natively
/// without visual mock fallbacks.
///
/// **Architecture Note (Restoration of Phased Treatment Planning):**
/// Phased treatment planning is restored and backed by the relational SQLite table `treatment_plans`
/// and [treatmentPlansByPatientProvider], enabling structured staging across 4 academic care phases:
/// Emergency, Preventive / Perio, Restorative, and Maintenance.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final patientCasesAsync = ref.watch(casesByPatientProvider(patient.id));
    final reqsAsync = ref.watch(allRequirementsProvider);
    final clinicsAsync = ref.watch(allClinicsProvider);

    final reqsMap = {
      for (final r in reqsAsync.valueOrNull ?? const <Requirement>[]) r.id: r,
    };
    final clinicsMap = {
      for (final c in clinicsAsync.valueOrNull ?? const <Clinic>[]) c.id: c,
    };

    final cases = patientCasesAsync.valueOrNull ?? const <CaseRecord>[];
    final patientClinics = <Clinic>[];
    final seenClinicIds = <String>{};

    for (final c in cases) {
      final req = reqsMap[c.requirementId];
      if (req != null) {
        final clinic = clinicsMap[req.clinicId] ??
            (req.clinicId.isNotEmpty
                ? Clinic(
                    id: req.clinicId,
                    name: _fallbackClinicNames[req.clinicId] ?? 'Dental Department',
                    academicYear: '',
                    colorHex: '#006A64',
                  )
                : null);
        if (clinic != null && seenClinicIds.add(clinic.id)) {
          patientClinics.add(clinic);
        }
      }
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            patient.name,
            style: AppTextStyles.h1Mobile.copyWith(
              color: isDark ? AppDarkColors.textPrimary : AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: context.l10n.editPatient,
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
                decoration: BoxDecoration(
                  color: isDark ? AppDarkColors.surfaceContainer : AppColors.surfaceContainerLowest,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  border: Border.all(
                    color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                  boxShadow: isDark ? AppDarkColors.cardShadow : AppColors.cardShadow,
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
                            color: isDark
                                ? AppDarkColors.primaryTeal.withValues(alpha: 0.15)
                                : AppColors.primaryContainer.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _initials(patient.name),
                            style: AppTextStyles.h1.copyWith(
                              color: isDark ? AppDarkColors.primaryTeal : AppColors.primary,
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
                                  color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${patient.gender}, ${patient.age} yrs • ${patient.phoneNumber ?? context.l10n.noPhone}',
                                style: AppTextStyles.caption.copyWith(
                                  color: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
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
                      runSpacing: 6,
                      children: patientClinics.isNotEmpty
                          ? patientClinics.map((clinic) {
                              return _ClinicBadge(
                                label: clinic.name,
                                color: _parseColor(clinic.colorHex),
                              );
                            }).toList()
                          : const <Widget>[
                              _ClinicBadge(label: 'General', color: AppColors.primary),
                            ],
                    ),
                  ],
                ),
              ),

              // 2. Tab Bar Header
              Container(
                color: Colors.transparent,
                child: TabBar(
                  labelColor: isDark ? AppDarkColors.primaryTeal : AppColors.primary,
                  unselectedLabelColor: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
                  indicatorColor: isDark ? AppDarkColors.primaryTeal : AppColors.secondary,
                  indicatorWeight: 3.0,
                  labelStyle: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: <Widget>[
                    Tab(text: context.l10n.clinicalCases),
                    Tab(text: context.l10n.patientHistory),
                    Tab(text: context.l10n.treatmentPlan),
                  ],
                ),
              ),

              // 3. Tab Bar Content
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    // Tab 1: Clinical Cases
                    _buildCasesTab(patientCasesAsync, patient),

                    // Tab 2: Patient History
                    _buildPatientHistoryTab(patient),

                    // Tab 3: Treatment Plan
                    TreatmentPlanTab(patient: patient),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_case_sheet',
          tooltip: context.l10n.logCaseRecord,
          onPressed: () => LogCaseRecordModal.show(
            context,
            patientId: patient.id,
            patientName: patient.name,
          ),
          backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor ?? (isDark ? AppDarkColors.primaryTeal : AppColors.primary),
          foregroundColor: Theme.of(context).floatingActionButtonTheme.foregroundColor ?? (isDark ? AppDarkColors.onPrimary : AppColors.onPrimary),
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

  static const Map<String, String> _fallbackProcedureTitles = <String, String>{
    'req-prosth-cd': 'Complete Denture',
    'req-prosth-rpd': 'Removable Partial Denture',
    'req-op-class1': 'Class I Composite',
    'req-op-class2': 'Class II Amalgam',
    'req-endo-anterior': 'Anterior RCT',
    'req-endo-molar': 'Premolar / Molar RCT',
    'req-surg-simple': 'Simple Extraction',
    'req-surg-complex': 'Surgical Extraction',
    'req-perio-srp': 'Scaling & Root Planing',
    'req-perio-gingivectomy': 'Gingivectomy',
    'req-pediatric-pulpotomy': 'Pulpotomy',
    'req-pediatric-ssc': 'Stainless Steel Crown',
  };

  static const Map<String, String> _fallbackClinicNames = <String, String>{
    'clinic-prosth': 'Prosthodontics',
    'clinic-operative': 'Operative Dentistry',
    'clinic-endo': 'Endodontics',
    'clinic-surgery': 'Oral Surgery',
    'clinic-perio': 'Periodontics',
    'clinic-pediatric': 'Pediatric Dentistry',
  };

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return AppColors.secondary;
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.secondary;
    }
  }

  Widget _buildCasesTab(AsyncValue<List<CaseRecord>> casesAsync, Patient patient) {
    final reqsAsync = ref.watch(allRequirementsProvider);
    final clinicsAsync = ref.watch(allClinicsProvider);

    final reqsMap = {
      for (final r in reqsAsync.valueOrNull ?? const <Requirement>[]) r.id: r,
    };
    final clinicsMap = {
      for (final c in clinicsAsync.valueOrNull ?? const <Clinic>[]) c.id: c,
    };

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
            final requirement = reqsMap[item.requirementId];
            final clinic = requirement != null ? clinicsMap[requirement.clinicId] : null;

            final procedureTitle = requirement?.title ??
                _fallbackProcedureTitles[item.requirementId] ??
                'Clinical Procedure';
            final clinicName = clinic?.name ??
                (requirement != null ? _fallbackClinicNames[requirement.clinicId] : null) ??
                'Dental Department';
            final clinicColor = _parseColor(clinic?.colorHex);

            return Dismissible(
              key: ValueKey('case_dismiss_${item.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
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
              confirmDismiss: (direction) async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(context.l10n.deleteCaseRecord),
                    content: Text(
                      context.l10n.deleteCaseRecordConfirmation,
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
              },
              onDismissed: (direction) async {
                try {
                  await ref.read(caseRecordRepositoryProvider).deleteCaseRecord(item.id);
                  AppLogger.info('Successfully deleted case record ${item.id}');
                  ref.invalidate(casesByPatientProvider(patient.id));
                  ref.invalidate(casesByRequirementProvider(item.requirementId));
                  ref.invalidate(allCasesProvider);
                  ref.invalidate(allRequirementsProvider);
                  ref.invalidate(globalQuotaSummaryProvider);
                  final reqs = ref.read(allRequirementsProvider).valueOrNull;
                  if (reqs != null) {
                    for (final r in reqs) {
                      if (r.id == item.requirementId && r.clinicId.isNotEmpty) {
                        ref.invalidate(requirementsByClinicProvider(r.clinicId));
                      }
                    }
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.caseRecordDeleted)),
                    );
                  }
                } catch (e, st) {
                  AppLogger.error('Failed to delete case record ${item.id}: $e', e, st);
                }
              },
              child: CaseRecordCard(
                caseRecord: item,
                requirementTitle: procedureTitle,
                clinicName: clinicName,
                clinicColor: clinicColor,
                onTap: () => EvaluateCaseModal.show(
                  context,
                  caseRecord: item,
                  patientName: patient.name,
                  procedureTitle: procedureTitle,
                ),
                onEdit: () => EvaluateCaseModal.show(
                  context,
                  caseRecord: item,
                  patientName: patient.name,
                  procedureTitle: procedureTitle,
                ),
                onDelete: () => _confirmDeleteCaseRecord(
                  context,
                  item,
                  procedureTitle,
                  patient,
                ),
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

  Future<void> _confirmDeleteCaseRecord(
    BuildContext context,
    CaseRecord caseRecord,
    String procedureTitle,
    Patient patient,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteCaseRecord),
        content: Text(
          context.l10n.deleteCaseRecordConfirmation,
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

    if (confirmed == true && mounted) {
      try {
        await ref.read(caseRecordRepositoryProvider).deleteCaseRecord(caseRecord.id);
        AppLogger.info('Successfully deleted case record ${caseRecord.id}');

        ref.invalidate(casesByPatientProvider(patient.id));
        ref.invalidate(casesByRequirementProvider(caseRecord.requirementId));
        ref.invalidate(allCasesProvider);
        ref.invalidate(allRequirementsProvider);
        ref.invalidate(globalQuotaSummaryProvider);

        final reqs = ref.read(allRequirementsProvider).valueOrNull;
        if (reqs != null) {
          for (final r in reqs) {
            if (r.id == caseRecord.requirementId && r.clinicId.isNotEmpty) {
              ref.invalidate(requirementsByClinicProvider(r.clinicId));
            }
          }
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.caseRecordDeleted)),
          );
        }
      } catch (e, st) {
        AppLogger.error('Failed to delete case record ${caseRecord.id}: $e', e, st);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete case record: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
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
      title: context.l10n.noClinicalCasesLoggedYet,
      subtitle: context.l10n.startLoggingCases(patient.name),
      actionButton: PrimaryButton(
        isFullWidth: false,
        text: context.l10n.logFirstCase,
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

  Widget _buildPatientHistoryTab(Patient patient) {
    final hasMedicalHistory = patient.medicalHistory != null &&
        patient.medicalHistory!.isNotEmpty;

    void onEditAnamnesis() {
      EditPatientModal.show(context, patient: patient);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 88.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 1. Chief Complaint (CC)
          _AnamnesisSectionCard(
            title: context.l10n.chiefComplaint,
            icon: Icons.record_voice_over_outlined,
            iconColor: AppColors.primary,
            content: patient.chiefComplaint,
            emptyPlaceholder: 'No chief complaint recorded.',
            onEdit: onEditAnamnesis,
          ),
          const SizedBox(height: 12),

          // 2. History of Chief Complaint (HCC)
          _AnamnesisSectionCard(
            title: context.l10n.historyOfChiefComplaint,
            icon: Icons.history_edu_outlined,
            iconColor: AppColors.secondary,
            content: patient.historyOfChiefComplaint,
            emptyPlaceholder: 'No history of chief complaint recorded.',
            onEdit: onEditAnamnesis,
          ),
          const SizedBox(height: 12),

          // 3. Medical History & Allergies
          _AnamnesisSectionCard(
            title: context.l10n.medicalHistoryAndAllergies,
            icon: hasMedicalHistory ? Icons.warning_amber_rounded : Icons.health_and_safety_outlined,
            iconColor: hasMedicalHistory ? AppColors.error : AppColors.secondary,
            content: patient.medicalHistory,
            emptyPlaceholder: 'No significant systemic medical history or drug allergies reported.',
            onEdit: onEditAnamnesis,
          ),
          const SizedBox(height: 12),

          // 4. Dental History
          _AnamnesisSectionCard(
            title: context.l10n.dentalHistory,
            icon: Icons.medical_services_outlined,
            iconColor: AppColors.primary,
            content: patient.dentalHistory,
            emptyPlaceholder: 'No prior dental treatments or dental history recorded.',
            onEdit: onEditAnamnesis,
          ),
          const SizedBox(height: 12),

          // 5. Current Medications
          _AnamnesisSectionCard(
            title: context.l10n.currentMedications,
            icon: Icons.medication_outlined,
            iconColor: AppColors.secondary,
            content: patient.medications,
            emptyPlaceholder: 'No active medications reported.',
            onEdit: onEditAnamnesis,
          ),
          const SizedBox(height: 12),

          // 6. Diagnostic Aids & Investigations
          _AnamnesisSectionCard(
            title: context.l10n.diagnosticAids,
            icon: Icons.biotech_outlined,
            iconColor: AppColors.primary,
            content: patient.diagnosticAids,
            emptyPlaceholder: 'No radiographs, pulp tests, or diagnostic aids logged.',
            onEdit: onEditAnamnesis,
          ),
          const SizedBox(height: 12),

          // 7. Attached Radiographs (X-Rays) Gallery
          RadiographsGallerySection(patient: patient),
        ],
      ),
    );
  }
}

class _AnamnesisSectionCard extends StatelessWidget {
  const _AnamnesisSectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.content,
    required this.emptyPlaceholder,
    required this.onEdit,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String? content;
  final String emptyPlaceholder;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasContent = content != null && content!.trim().isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BaseCard(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 20, color: isDark ? (iconColor == AppColors.error ? AppDarkColors.error : AppDarkColors.primaryTeal) : iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.h2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppDarkColors.textPrimary : AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: isDark ? AppDarkColors.textMuted : AppColors.outline),
                tooltip: 'Edit $title',
                splashRadius: 18,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasContent)
            Text(
              content!.trim(),
              style: AppTextStyles.bodyMd.copyWith(
                color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
              ),
            )
          else
            Row(
              children: <Widget>[
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: isDark ? AppDarkColors.textMuted : AppColors.outlineVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    emptyPlaceholder,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
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

