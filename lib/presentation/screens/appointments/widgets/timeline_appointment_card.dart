import 'package:flutter/material.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../l10n/l10n.dart';
import '../../patients/patient_case_sheet_screen.dart';

/// Timeline appointment row widget with chronological node line and detailed patient card.
///
/// ### Routing Mechanisms:
/// Activating this timeline card executes an imperative [Navigator.push] to the
/// [PatientCaseSheetScreen], passing the linked [Appointment.patientId].
/// In Dentera's offline architecture, detail views are pushed onto the [Navigator]
/// stack to isolate workflow contexts and maintain standard platform back-stack navigation,
/// whereas core sections switch via Riverpod's `rootNavigationIndexProvider` inside the
/// root `IndexedStack`.
class TimelineAppointmentCard extends StatelessWidget {
  const TimelineAppointmentCard({
    super.key,
    required this.appointment,
    required this.patientName,
    required this.clinicName,
    required this.timeFormatted,
    this.clinicColor = AppColors.secondary,
    this.isLast = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final Appointment appointment;
  final String patientName;
  final String clinicName;
  final String timeFormatted;
  final Color clinicColor;
  final bool isLast;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 1. Time Indicator Column
          SizedBox(
            width: 72,
            child: Padding(
              padding: const EdgeInsets.only(top: 14.0),
              child: Text(
                timeFormatted,
                style: AppTextStyles.caption.copyWith(
                  color: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 2. Vertical Timeline Line & Dot Indicator
          Column(
            children: <Widget>[
              const SizedBox(height: 18),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: clinicColor,
                  border: Border.all(
                    color: isDark ? AppDarkColors.canvasBackground : AppColors.surfaceContainerLowest,
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: clinicColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // 3. Appointment Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Material(
                color: isDark ? AppDarkColors.surfaceContainer : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {
                    if (onTap != null) {
                      onTap!();
                    } else {
                      AppLogger.info('Navigating to Patient Case Sheet for patient: ${appointment.patientId}');
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => PatientCaseSheetScreen(
                            patientId: appointment.patientId,
                          ),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant.withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                      boxShadow: isDark ? AppDarkColors.cardShadow : AppColors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Patient Name & Status
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                patientName,
                                style: AppTextStyles.h2.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (appointment.status.isNotEmpty) ...<Widget>[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: appointment.status.toLowerCase() == 'completed'
                                      ? (isDark ? AppDarkColors.primaryTeal.withValues(alpha: 0.2) : AppColors.secondaryContainer.withValues(alpha: 0.3))
                                      : (isDark ? AppDarkColors.surfaceContainerHighest : AppColors.primaryContainer.withValues(alpha: 0.12)),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  appointment.status,
                                  style: AppTextStyles.labelCaps.copyWith(
                                    color: appointment.status.toLowerCase() == 'completed'
                                        ? (isDark ? AppDarkColors.primaryTeal : AppColors.secondary)
                                        : (isDark ? AppDarkColors.primaryTeal : AppColors.primary),
                                  ),
                                ),
                              ),
                            ],
                            if (onEdit != null) ...<Widget>[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
                                ),
                                tooltip: context.l10n.editAppointment,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                onPressed: onEdit,
                              ),
                            ],
                            if (onDelete != null || onEdit != null) ...<Widget>[
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  size: 18,
                                  color: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                tooltip: context.l10n.appointmentActions,
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    onEdit?.call();
                                  } else if (value == 'delete') {
                                    onDelete?.call();
                                  }
                                },
                                itemBuilder: (context) => <PopupMenuEntry<String>>[
                                  if (onEdit != null)
                                    PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18, color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface),
                                          const SizedBox(width: 8),
                                          Text(context.l10n.editAppointment),
                                        ],
                                      ),
                                    ),
                                  if (onDelete != null)
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
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Clinic & Procedure info
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.medical_services_outlined,
                              size: 16,
                              color: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '$clinicName${appointment.procedureDescription != null && appointment.procedureDescription!.isNotEmpty ? ' • ${appointment.procedureDescription}' : ''}',
                                style: AppTextStyles.caption.copyWith(
                                  color: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
