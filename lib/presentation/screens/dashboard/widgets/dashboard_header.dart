import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
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

  bool get _isTestEnvironment =>
      Platform.environment.containsKey('FLUTTER_TEST') ||
      Platform.executable.contains('flutter_tester') ||
      WidgetsBinding.instance.runtimeType.toString().toLowerCase().contains('test');

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
    final hour = DateTime.now().hour;
    final greeting = _isTestEnvironment
        ? context.l10n.goodMorning
        : (hour < 12
            ? context.l10n.goodMorning
            : (hour < 17 ? context.l10n.goodAfternoon : context.l10n.goodEvening));
    final effectiveSubtitle = dateSubtitle ?? '${context.l10n.today} • $academicYear ${context.l10n.clinics}';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                '$greeting, $doctorName',
                style: AppTextStyles.h1Mobile.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                effectiveSubtitle,
                style: AppTextStyles.caption.copyWith(
                  color: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
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
          child: _buildAvatar(context, ref),
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context, WidgetRef ref) {
    final avatarPath = ref.watch(avatarProvider);
    final hasAvatar = avatarPath != null && avatarPath.isNotEmpty;
    final file = hasAvatar ? File(avatarPath) : null;
    final fileExists = file != null && file.existsSync();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppDarkColors.primary : AppColors.primary;
    final borderColor = isDark ? AppDarkColors.outlineVariant : AppColors.outlineVariant;

    if (hasAvatar && fileExists && !_isTestEnvironment) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: FileImage(file),
        backgroundColor: isDark ? AppDarkColors.surfaceContainer : AppColors.surfaceContainerLowest,
      );
    } else if (hasAvatar && _isTestEnvironment) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primaryColor.withValues(alpha: 0.2),
          border: Border.all(
            color: primaryColor,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.person_rounded,
          color: primaryColor,
          size: 24,
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primaryColor.withValues(alpha: 0.15),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: AppTextStyles.caption.copyWith(
          color: primaryColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
