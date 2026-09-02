import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// Top-level greeting and profile avatar header for the Dashboard.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.doctorName,
    required this.academicYear,
    this.dateSubtitle,
    this.onAvatarTap,
  });

  final String doctorName;
  final String academicYear;
  final String? dateSubtitle;
  final VoidCallback? onAvatarTap;

  String get _initials {
    final clean = doctorName.replaceAll(RegExp(r'^Dr\.\s*', caseSensitive: false), '').trim();
    if (clean.isEmpty) return 'DR';
    final parts = clean.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSubtitle = dateSubtitle ?? 'Today • $academicYear Clinics';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Good morning, $doctorName',
                style: AppTextStyles.h1Mobile.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                effectiveSubtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: onAvatarTap ?? () {
            // TODO: Phase 5.5 - Navigate to Profile & Settings
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer.withValues(alpha: 0.2),
              border: Border.all(
                color: AppColors.outlineVariant,
                width: 1.0,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
