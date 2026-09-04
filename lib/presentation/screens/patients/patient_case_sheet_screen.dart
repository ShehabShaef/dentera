import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../data/database/database_providers.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';
import '../../widgets/widgets.dart';
import 'widgets/widgets.dart';

/// Patient Case Sheet detailed record screen with multi-tab layout wired to Riverpod SQLite state.
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

  Future<void> _logNewCase(String patientId) async {
    final newCase = CaseRecord(
      id: 'case-${DateTime.now().millisecondsSinceEpoch % 10000}',
      patientId: patientId,
      requirementId: 'req-cd',
      status: 'In Progress',
      notes: 'Initial clinical evaluation & impression taking.',
      dateStarted: DateTime.now(),
    );

    await ref.read(caseRecordRepositoryProvider).addCaseRecord(newCase);
    ref.invalidate(casesByPatientProvider(patientId));
    ref.invalidate(allCasesProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New clinical case logged successfully.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.patient != null) {
      return _buildScaffold(context, widget.patient!);
    }

    final pid = widget.patientId!;
    final patientAsync = ref.watch(patientByIdProvider(pid));

    return patientAsync.when(
      data: (patient) {
        final effectivePatient = patient ??
            Patient(
              id: pid,
              name: 'Patient #$pid',
              age: 25,
              gender: 'Unknown',
              createdAt: DateTime.now(),
            );
        return _buildScaffold(context, effectivePatient);
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      error: (_, _) {
        final fallbackPatient = Patient(
          id: pid,
          name: 'Patient #$pid',
          age: 25,
          gender: 'Unknown',
          createdAt: DateTime.now(),
        );
        return _buildScaffold(context, fallbackPatient);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, Patient patient) {
    final patientCasesAsync = ref.watch(casesByPatientProvider(patient.id));

    return DefaultTabController(
      length: 3,
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
              onPressed: () {
                // TODO: Phase 6.1 - Edit Patient details
              },
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
                    Tab(text: 'Treatment Plan'),
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

                    // Tab 2: Treatment Plan
                    _buildTreatmentPlanTab(),

                    // Tab 3: Medical History
                    _buildMedicalHistoryTab(patient),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_case_sheet',
          onPressed: () => _logNewCase(patient.id),
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
          return _buildMockCasesTab(patient);
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
              onTap: () {
                // TODO: Phase 6.2 - Open Case Record evaluation sheet
              },
            );
          },
        );
      },
      loading: () => _buildMockCasesTab(patient),
      error: (_, _) => _buildMockCasesTab(patient),
    );
  }

  Widget _buildMockCasesTab(Patient patient) {
    final mockCases = [
      {
        'caseRecord': CaseRecord(
          id: 'case-01',
          patientId: patient.id,
          requirementId: 'req-cd',
          dateStarted: DateTime.now().subtract(const Duration(days: 14)),
          status: 'In Progress',
          notes: 'Primary impression completed. Border molding next.',
        ),
        'requirementTitle': 'Complete Denture',
        'clinicName': 'Prosthodontics',
        'clinicColor': AppColors.primary,
      },
      {
        'caseRecord': CaseRecord(
          id: 'case-02',
          patientId: patient.id,
          requirementId: 'req-anterior-rct',
          dateStarted: DateTime.now().subtract(const Duration(days: 28)),
          dateCompleted: DateTime.now().subtract(const Duration(days: 7)),
          status: 'Evaluated',
          notes: 'Obturation successful. Signed off with score 9.0/10.',
        ),
        'requirementTitle': 'Anterior Root Canal (Tooth 11)',
        'clinicName': 'Endodontics',
        'clinicColor': AppColors.secondary,
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 88.0),
      physics: const BouncingScrollPhysics(),
      itemCount: mockCases.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = mockCases[index];
        return CaseRecordCard(
          caseRecord: item['caseRecord'] as CaseRecord,
          requirementTitle: item['requirementTitle'] as String,
          clinicName: item['clinicName'] as String,
          clinicColor: item['clinicColor'] as Color? ?? AppColors.secondary,
          onTap: () {
            // TODO: Phase 6.2 - Open Case Record evaluation sheet
          },
        );
      },
    );
  }

  Widget _buildTreatmentPlanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 88.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Chief Complaint Card
          BaseCard(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.record_voice_over_outlined,
                      size: 20,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Chief Complaint & Findings',
                      style: AppTextStyles.h2.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Patient reports missing lower molars and difficulty chewing.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Oral Lesions: Negative • Periodontal Status: Fair',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Phased Treatment Plan Card
          BaseCard(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.format_list_numbered_rounded,
                          size: 20,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Phased Treatment Plan',
                          style: AppTextStyles.h2.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '2 Phases',
                        style: AppTextStyles.labelCaps.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _TreatmentPhaseItem(
                  phaseNumber: 'Phase 1',
                  description: 'Endodontic therapy on tooth 36 (Anterior/Premolar)',
                  phaseColor: AppColors.secondary,
                ),
                const SizedBox(height: 12),
                const _TreatmentPhaseItem(
                  phaseNumber: 'Phase 2',
                  description: 'Prosthetic rehabilitation: Metal Denture / Overdenture',
                  phaseColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
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
          // Systemic Conditions & Allergies Card
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
          const SizedBox(height: 16),

          // Dental History Card
          BaseCard(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.history_edu_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Dental History',
                      style: AppTextStyles.h2.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Previous extractions under local anesthesia without complications. Last visit over 1 year ago.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
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

class _TreatmentPhaseItem extends StatelessWidget {
  const _TreatmentPhaseItem({
    required this.phaseNumber,
    required this.description,
    required this.phaseColor,
  });

  final String phaseNumber;
  final String description;
  final Color phaseColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.outline, width: 1.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  phaseNumber.toUpperCase(),
                  style: AppTextStyles.labelCaps.copyWith(
                    color: phaseColor,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurface,
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
