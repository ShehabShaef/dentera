import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/services/report_generator_service.dart';
import '../../../core/theme/theme.dart';
import '../../../data/repositories/preferences_repository.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';
import '../buttons/buttons.dart';
import '../dentera_snackbar.dart';

/// Modal bottom sheet allowing clinicians to generate, preview, print,
/// and share academic quota supervisory reports (PDF & CSV).
class GenerateQuotaReportModal extends ConsumerStatefulWidget {
  const GenerateQuotaReportModal({
    super.key,
    this.initialClinic,
  });

  final Clinic? initialClinic;

  /// Convenience static method to summon the [GenerateQuotaReportModal] bottom sheet.
  static Future<void> show(
    BuildContext context, {
    Clinic? clinic,
  }) {
    AppLogger.info('Opened GenerateQuotaReportModal (scope: ${clinic?.name ?? "All Departments"})');
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GenerateQuotaReportModal(initialClinic: clinic),
    );
  }

  @override
  ConsumerState<GenerateQuotaReportModal> createState() => _GenerateQuotaReportModalState();
}

class _GenerateQuotaReportModalState extends ConsumerState<GenerateQuotaReportModal> {
  String? _selectedClinicId;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _selectedClinicId = widget.initialClinic?.id;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _selectedStartDate != null && _selectedEndDate != null
          ? DateTimeRange(start: _selectedStartDate!, end: _selectedEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
    });
  }

  QuotaReportData _buildReportData() {
    final userProfile = ref.read(userProfileProvider).valueOrNull ??
        const UserProfile(
          name: 'Dr. Shehab Shaif',
          university: 'Dental School',
          academicYear: '5th Year',
        );
    final clinics = ref.read(clinicListProvider).valueOrNull ?? const <Clinic>[];
    final allClinics = <Clinic>[
      if (widget.initialClinic != null && !clinics.any((c) => c.id == widget.initialClinic!.id))
        widget.initialClinic!,
      ...clinics,
    ];
    final requirements = ref.read(allRequirementsProvider).valueOrNull ?? const <Requirement>[];
    final cases = ref.read(allCasesProvider).valueOrNull ?? const <CaseRecord>[];
    final patients = ref.read(patientListProvider).valueOrNull ?? const <Patient>[];

    return QuotaReportData(
      doctorName: userProfile.name,
      university: userProfile.university,
      academicYear: userProfile.academicYear,
      generatedDate: DateTime.now(),
      clinics: allClinics,
      requirements: requirements,
      cases: cases,
      patients: patients,
      filterClinicId: _selectedClinicId,
      startDate: _selectedStartDate,
      endDate: _selectedEndDate,
    );
  }

  Future<void> _handlePreviewAndPrint() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      final service = ref.read(reportGeneratorServiceProvider);
      final data = _buildReportData();
      await service.previewAndPrintPdf(data);
      if (mounted) Navigator.of(context).pop();
    } catch (e, st) {
      AppLogger.error('Failed to preview/print quota report: $e', e, st);
      if (mounted) {
        DenteraSnackBar.showError(
          context,
          message: 'Failed to generate PDF report',
          error: e,
          stackTrace: st,
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _handleSharePdf() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      final service = ref.read(reportGeneratorServiceProvider);
      final data = _buildReportData();
      await service.sharePdf(data);
      if (mounted) Navigator.of(context).pop();
    } catch (e, st) {
      AppLogger.error('Failed to share PDF report: $e', e, st);
      if (mounted) {
        DenteraSnackBar.showError(
          context,
          message: 'Failed to share PDF report',
          error: e,
          stackTrace: st,
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _handleExportCsv() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      final service = ref.read(reportGeneratorServiceProvider);
      final data = _buildReportData();
      await service.shareCsv(data);
      if (mounted) Navigator.of(context).pop();
    } catch (e, st) {
      AppLogger.error('Failed to export CSV grading report: $e', e, st);
      if (mounted) {
        DenteraSnackBar.showError(
          context,
          message: 'Failed to export CSV grading sheet',
          error: e,
          stackTrace: st,
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final clinicsAsync = ref.watch(clinicListProvider);
    final clinics = clinicsAsync.valueOrNull ?? const <Clinic>[];

    // Ensure initialClinic is available in the dropdown items even before clinicsAsync finishes loading
    final List<Clinic> dropdownClinics = <Clinic>[...clinics];
    if (widget.initialClinic != null &&
        !dropdownClinics.any((c) => c.id == widget.initialClinic!.id)) {
      dropdownClinics.add(widget.initialClinic!);
    }

    final String? effectiveClinicValue =
        _selectedClinicId != null && dropdownClinics.any((c) => c.id == _selectedClinicId)
            ? _selectedClinicId
            : null;

    final userProfile = ref.watch(userProfileProvider).valueOrNull ??
        const UserProfile(
          name: 'Dr. Shehab Shaif',
          university: 'Dental School',
          academicYear: '5th Year',
        );

    final allReqs = ref.watch(allRequirementsProvider).valueOrNull ?? const <Requirement>[];
    final allCases = ref.watch(allCasesProvider).valueOrNull ?? const <CaseRecord>[];

    // Compute preview metrics for selected scope
    final visibleClinics = effectiveClinicValue != null && effectiveClinicValue.isNotEmpty
        ? dropdownClinics.where((c) => c.id == effectiveClinicValue).toList()
        : dropdownClinics;
    final visibleClinicIds = visibleClinics.map((c) => c.id).toSet();
    final visibleReqs = allReqs.where((r) => visibleClinicIds.contains(r.clinicId)).toList();
    final visibleReqIds = visibleReqs.map((r) => r.id).toSet();
    final visibleCases = allCases.where((c) {
      if (!visibleReqIds.contains(c.requirementId)) return false;
      final caseDate = c.dateCompleted ?? c.dateStarted;
      if (_selectedStartDate != null && caseDate.isBefore(_selectedStartDate!)) return false;
      if (_selectedEndDate != null) {
        final endOfDay = DateTime(
          _selectedEndDate!.year,
          _selectedEndDate!.month,
          _selectedEndDate!.day,
          23,
          59,
          59,
        );
        if (caseDate.isAfter(endOfDay)) return false;
      }
      return true;
    }).toList();

    final dateFormat = DateFormat('MMM d, yyyy');
    final String dateRangeDisplay = _selectedStartDate != null && _selectedEndDate != null
        ? '${dateFormat.format(_selectedStartDate!)} – ${dateFormat.format(_selectedEndDate!)}'
        : 'All Time (Complete Record)';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: bottomInset + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header with icon
            Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in_outlined,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Academic Supervisory Portfolio',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Generate Quota Report',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Clinician Summary Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: const Icon(Icons.person_rounded, size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          userProfile.name,
                          style: AppTextStyles.bodyMd.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          '${userProfile.academicYear} • ${userProfile.university}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Scope Selector: Department / Clinic
            Text(
              'Department Scope',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: effectiveClinicValue,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.outline),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Departments & Clinics'),
                    ),
                    ...dropdownClinics.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedClinicId = val;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date Range Picker
            Text(
              'Case Date Range',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.date_range_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dateRangeDisplay,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: _selectedStartDate != null
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant,
                          fontWeight: _selectedStartDate != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (_selectedStartDate != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        tooltip: 'Clear Date Filter',
                        onPressed: _clearDateRange,
                      )
                    else
                      const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.outline),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Scope Metrics Breakdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  _MetricBadge(
                    count: visibleClinics.length,
                    label: visibleClinics.length == 1 ? 'Clinic' : 'Clinics',
                  ),
                  Container(width: 1, height: 24, color: AppColors.outlineVariant),
                  _MetricBadge(
                    count: visibleReqs.length,
                    label: visibleReqs.length == 1 ? 'Requirement' : 'Requirements',
                  ),
                  Container(width: 1, height: 24, color: AppColors.outlineVariant),
                  _MetricBadge(
                    count: visibleCases.length,
                    label: visibleCases.length == 1 ? 'Case Log' : 'Case Logs',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            if (_isGenerating)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // Preview & Print PDF Button
              PrimaryButton(
                text: 'Preview & Print PDF',
                icon: const Icon(Icons.print_rounded, size: 20, color: AppColors.onPrimary),
                onPressed: _handlePreviewAndPrint,
              ),
              const SizedBox(height: 10),

              // Share PDF Button
              SecondaryButton(
                text: 'Share PDF Report',
                icon: const Icon(Icons.share_rounded, size: 20, color: AppColors.primary),
                onPressed: _handleSharePdf,
              ),
              const SizedBox(height: 10),

              // Export Tabular CSV Button
              OutlinedButton.icon(
                onPressed: _handleExportCsv,
                icon: const Icon(Icons.table_chart_outlined, size: 18),
                label: const Text('Export Tabular CSV (Grading Sheet)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurface,
                  side: const BorderSide(color: AppColors.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.count,
    required this.label,
  });

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          count.toString(),
          style: AppTextStyles.h2.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 11,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
