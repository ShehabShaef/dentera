import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/theme.dart';
import '../../../state/state.dart';

/// Top-level greeting and profile avatar header for the Dashboard.
///
/// ### Routing Mechanism:
/// Tapping the student clinician avatar switches the active root navigation tab
/// to the Profile & Settings tab (index = 4) by mutating Riverpod's
/// [rootNavigationIndexProvider]. This preserves state across the application
/// [IndexedStack] while seamlessly redirecting user focus. If a custom
/// [onAvatarTap] callback is supplied, it takes precedence.
class DashboardHeader extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
          onTap: () {
            if (onAvatarTap != null) {
              onAvatarTap!();
            } else {
              AppLogger.info('Switching root tab to Profile');
              ref.read(rootNavigationIndexProvider.notifier).state = 4;
            }
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
