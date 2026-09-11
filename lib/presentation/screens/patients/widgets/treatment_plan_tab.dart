import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';
import '../../../state/state.dart';
import '../../../widgets/dentera_snackbar.dart';
import '../../../widgets/modals/add_treatment_plan_modal.dart';
import '../../../widgets/modals/log_case_record_modal.dart';

/// Tab widget presenting structured, phased academic dental treatment staging.
class TreatmentPlanTab extends ConsumerWidget {
  const TreatmentPlanTab({
    super.key,
    required this.patient,
  });

  final Patient patient;

  Color _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.parse('0xFF$clean'));
    }
    return AppColors.primary;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case TreatmentPlan.statusApproved:
        return const Color(0xFF006A64);
      case TreatmentPlan.statusConverted:
        return const Color(0xFF1B6B2F);
      case TreatmentPlan.statusCompleted:
        return const Color(0xFF4A4458);
      case TreatmentPlan.statusProposed:
      default:
        return const Color(0xFFB35C00);
    }
  }

  Color _getStatusBg(String status) {
    switch (status) {
      case TreatmentPlan.statusApproved:
        return const Color(0xFF006A64).withValues(alpha: 0.12);
      case TreatmentPlan.statusConverted:
        return const Color(0xFF1B6B2F).withValues(alpha: 0.12);
      case TreatmentPlan.statusCompleted:
        return const Color(0xFF4A4458).withValues(alpha: 0.12);
      case TreatmentPlan.statusProposed:
      default:
        return const Color(0xFFB35C00).withValues(alpha: 0.12);
    }
  }

  Future<void> _handleConvertPlanToCase(
    BuildContext context,
    WidgetRef ref,
    TreatmentPlan plan,
  ) async {
    final noteContent = plan.notes != null && plan.notes!.trim().isNotEmpty
        ? '${plan.title}\n${plan.notes}'
        : plan.title;

    final caseRecord = await LogCaseRecordModal.show(
      context,
      patientId: patient.id,
      patientName: patient.name,
      initialClinicId: plan.targetClinicId,
      initialNotes: noteContent,
    );

    if (caseRecord != null) {
      final controller = ref.read(treatmentPlansControllerProvider);
      await controller.markConverted(plan);
      if (context.mounted) {
        DenteraSnackBar.showSuccess(
          context,
          message: 'Treatment "${plan.title}" converted to active Case Record',
        );
      }
    }
  }

  Future<void> _confirmDeletePlan(
    BuildContext context,
    WidgetRef ref,
    TreatmentPlan plan,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Treatment Plan Item'),
        content: Text(
          'Are you sure you want to remove "${plan.title}" from ${patient.name}\'s treatment plan?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final controller = ref.read(treatmentPlansControllerProvider);
      await controller.deletePlan(plan.id, patient.id);
      if (context.mounted) {
        DenteraSnackBar.showSuccess(
          context,
          message: 'Treatment plan item deleted',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(treatmentPlansByPatientProvider(patient.id));
    final clinicsAsync = ref.watch(allClinicsProvider);

    final clinicsMap = {
      for (final c in clinicsAsync.valueOrNull ?? const <Clinic>[]) c.id: c,
    };

    return plansAsync.when(
      data: (plans) {
        if (plans.isEmpty) {
          return _buildZeroState(context);
        }
        return _buildPhasedPlanList(context, ref, plans, clinicsMap);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'Failed to load treatment plans',
                style: AppTextStyles.h2.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: AppTextStyles.caption.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(treatmentPlansByPatientProvider(patient.id)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZeroState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Treatment Plan Staged',
              style: AppTextStyles.h1Mobile.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Organize comprehensive clinical treatments across academic phases (Emergency, Preventive, Restorative, Maintenance) for ${patient.name}.',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => AddTreatmentPlanModal.show(
                context,
                patientId: patient.id,
                patientName: patient.name,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Stage Proposed Treatment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhasedPlanList(
    BuildContext context,
    WidgetRef ref,
    List<TreatmentPlan> plans,
    Map<String, Clinic> clinicsMap,
  ) {
    final totalCount = plans.length;
    final approvedCount = plans.where((p) => p.status == TreatmentPlan.statusApproved).length;
    final convertedCount = plans.where((p) => p.status == TreatmentPlan.statusConverted).length;

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 88),
      children: <Widget>[
        // Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow,
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Phased Treatment Plan',
                    style: AppTextStyles.h2.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => AddTreatmentPlanModal.show(
                      context,
                      patientId: patient.id,
                      patientName: patient.name,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Item'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  _buildSummaryPill('$totalCount Planned', AppColors.primary),
                  const SizedBox(width: 8),
                  _buildSummaryPill('$approvedCount Approved', const Color(0xFF006A64)),
                  const SizedBox(width: 8),
                  _buildSummaryPill('$convertedCount Active Cases', const Color(0xFF1B6B2F)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Phase Groups
        for (final phase in TreatmentPhase.values) ...[
          _buildPhaseSection(
            context,
            ref,
            phase,
            plans.where((p) => p.phase == phase.value).toList(),
            clinicsMap,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildSummaryPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelCaps.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPhaseSection(
    BuildContext context,
    WidgetRef ref,
    TreatmentPhase phase,
    List<TreatmentPlan> phasePlans,
    Map<String, Clinic> clinicsMap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Phase Header
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${phase.value}',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        phase.label,
                        style: AppTextStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        phase.description,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  tooltip: 'Add to ${phase.label}',
                  color: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => AddTreatmentPlanModal.show(
                    context,
                    patientId: patient.id,
                    patientName: patient.name,
                    initialPhase: phase.value,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),

          // Items or placeholder
          if (phasePlans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Text(
                'No treatments staged in this phase.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: phasePlans.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: AppColors.outlineVariant,
              ),
              itemBuilder: (context, index) {
                final plan = phasePlans[index];
                return _buildPlanItemTile(context, ref, plan, clinicsMap);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPlanItemTile(
    BuildContext context,
    WidgetRef ref,
    TreatmentPlan plan,
    Map<String, Clinic> clinicsMap,
  ) {
    final clinic = plan.targetClinicId != null ? clinicsMap[plan.targetClinicId] : null;
    final statusColor = _getStatusColor(plan.status);
    final statusBg = _getStatusBg(plan.status);
    final isProposed = plan.status == TreatmentPlan.statusProposed;
    final isApproved = plan.status == TreatmentPlan.statusApproved;
    final isConverted = plan.status == TreatmentPlan.statusConverted;

    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Row 1: Title and Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  plan.title,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  plan.status,
                  style: AppTextStyles.labelCaps.copyWith(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Contextual 3-dot popup menu
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 18,
                  color: AppColors.onSurfaceVariant,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onSelected: (action) async {
                  final controller = ref.read(treatmentPlansControllerProvider);
                  switch (action) {
                    case 'edit':
                      AddTreatmentPlanModal.show(
                        context,
                        patientId: patient.id,
                        patientName: patient.name,
                        treatmentPlan: plan,
                      );
                      break;
                    case 'approve':
                      await controller.approvePlan(plan);
                      if (context.mounted) {
                        DenteraSnackBar.showSuccess(
                          context,
                          message: 'Marked "${plan.title}" as Approved',
                        );
                      }
                      break;
                    case 'complete':
                      await controller.updatePlan(
                        plan.copyWith(status: TreatmentPlan.statusCompleted),
                      );
                      if (context.mounted) {
                        DenteraSnackBar.showSuccess(
                          context,
                          message: 'Marked "${plan.title}" as Completed',
                        );
                      }
                      break;
                    case 'proposed':
                      await controller.updatePlan(
                        plan.copyWith(status: TreatmentPlan.statusProposed),
                      );
                      break;
                    case 'convert':
                      _handleConvertPlanToCase(context, ref, plan);
                      break;
                    case 'delete':
                      _confirmDeletePlan(context, ref, plan);
                      break;
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Edit Treatment'),
                      ],
                    ),
                  ),
                  if (isProposed)
                    const PopupMenuItem(
                      value: 'approve',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF006A64)),
                          SizedBox(width: 8),
                          Text('Mark as Approved'),
                        ],
                      ),
                    ),
                  if (!isConverted)
                    const PopupMenuItem(
                      value: 'convert',
                      child: Row(
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, size: 16, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('Convert to Case Record'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'complete',
                    child: Row(
                      children: [
                        Icon(Icons.done_all, size: 16),
                        SizedBox(width: 8),
                        Text('Mark as Completed'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete Item', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Clinic department badge if assigned
          if (clinic != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _parseColor(clinic.colorHex).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _parseColor(clinic.colorHex).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                clinic.name,
                style: AppTextStyles.labelCaps.copyWith(
                  color: _parseColor(clinic.colorHex),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          // Clinical Notes
          if (plan.notes != null && plan.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              plan.notes!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],

          // Quick Action Buttons
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              if (isProposed) ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    final controller = ref.read(treatmentPlansControllerProvider);
                    await controller.approvePlan(plan);
                    if (context.mounted) {
                      DenteraSnackBar.showSuccess(
                        context,
                        message: 'Faculty approved "${plan.title}"',
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: const Color(0xFF006A64),
                    side: const BorderSide(color: Color(0xFF006A64)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 14),
                  label: const Text('Approve', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
              ],
              if (isApproved || isProposed) ...[
                FilledButton.icon(
                  onPressed: () => _handleConvertPlanToCase(context, ref, plan),
                  style: FilledButton.styleFrom(
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.assignment_turned_in_outlined, size: 14),
                  label: const Text('Convert to Case', style: TextStyle(fontSize: 12)),
                ),
              ],
              if (isConverted) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B6B2F).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Color(0xFF1B6B2F)),
                      SizedBox(width: 4),
                      Text(
                        'Active Case Created',
                        style: TextStyle(
                          color: Color(0xFF1B6B2F),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
