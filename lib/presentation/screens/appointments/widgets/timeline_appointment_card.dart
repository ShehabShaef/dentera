import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';

/// Timeline appointment row widget with chronological node line and detailed patient card.
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
  });

  final Appointment appointment;
  final String patientName;
  final String clinicName;
  final String timeFormatted;
  final Color clinicColor;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 1. Time Column
          SizedBox(
            width: 64,
            child: Padding(
              padding: const EdgeInsets.only(top: 14.0),
              child: Text(
                timeFormatted,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.onSurfaceVariant,
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
                    color: AppColors.surfaceContainerLowest,
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
                    color: AppColors.outlineVariant.withValues(alpha: 0.4),
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
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: onTap ?? () {
                    // TODO: Phase 6.2 - Open Case Sheet
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Patient Name & Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                patientName,
                                style: AppTextStyles.h2.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (appointment.status.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: appointment.status.toLowerCase() == 'completed'
                                      ? AppColors.secondaryContainer.withValues(alpha: 0.3)
                                      : AppColors.primaryContainer.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  appointment.status,
                                  style: AppTextStyles.labelCaps.copyWith(
                                    color: appointment.status.toLowerCase() == 'completed'
                                        ? AppColors.secondary
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Clinic & Procedure info
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.medical_services_outlined,
                              size: 16,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '$clinicName${appointment.procedureDescription != null && appointment.procedureDescription!.isNotEmpty ? ' • ${appointment.procedureDescription}' : ''}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.onSurfaceVariant,
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
