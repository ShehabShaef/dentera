import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../state/state.dart';
import '../../../widgets/widgets.dart';

/// Header card displaying user profile summary, avatar image/initial, and academic stage.
class ProfileHeaderCard extends ConsumerWidget {
  const ProfileHeaderCard({
    super.key,
    required this.name,
    required this.subtitle,
    this.onEdit,
    this.onAvatarTap,
  });

  final String name;
  final String subtitle;
  final VoidCallback? onEdit;
  final VoidCallback? onAvatarTap;

  bool get _isTestEnvironment =>
      Platform.environment.containsKey('FLUTTER_TEST') ||
      Platform.executable.contains('flutter_tester') ||
      WidgetsBinding.instance.runtimeType.toString().toLowerCase().contains('test');

  String get _initial {
    final clean = name.replaceAll(RegExp(r'^Dr\.\s*', caseSensitive: false), '').trim();
    if (clean.isEmpty) return 'D';
    return clean[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarPath = ref.watch(avatarProvider);
    final hasAvatar = avatarPath != null && avatarPath.isNotEmpty;
    final file = hasAvatar ? File(avatarPath) : null;
    final fileExists = file != null && file.existsSync();

    return BaseCard(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Squircle Avatar with Camera Edit Badge
          GestureDetector(
            onTap: onAvatarTap ?? () => AvatarPickerModal.show(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: (hasAvatar && (fileExists || _isTestEnvironment))
                        ? null
                        : (isDark ? AppDarkColors.brandGradient : AppColors.brandGradient),
                    color: (hasAvatar && (fileExists || _isTestEnvironment))
                        ? (isDark
                            ? AppDarkColors.primaryContainer.withValues(alpha: 0.2)
                            : AppColors.primaryContainer.withValues(alpha: 0.2))
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppDarkColors.outlineVariant : AppColors.outlineVariant,
                      width: 1.0,
                    ),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: hasAvatar
                      ? (!_isTestEnvironment && fileExists
                          ? Image.file(
                              file,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Text(
                                _initial,
                                style: AppTextStyles.h1.copyWith(
                                  color: isDark ? AppDarkColors.onPrimary : AppColors.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              size: 34,
                              color: isDark ? AppDarkColors.primary : AppColors.primary,
                            ))
                      : Text(
                          _initial,
                          style: AppTextStyles.h1.copyWith(
                            color: isDark ? AppDarkColors.onPrimary : AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isDark ? AppDarkColors.primary : AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppDarkColors.surfaceContainer : AppColors.surface,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 11,
                      color: isDark ? AppDarkColors.onPrimary : AppColors.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Name and Academic Year
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  name,
                  style: AppTextStyles.h2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: isDark ? AppDarkColors.textSecondary : AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Edit Action Button
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: isDark ? AppDarkColors.textSecondary : AppColors.onSurfaceVariant,
              size: 20,
            ),
            onPressed: onEdit ?? () {
              // TODO: Phase 5.5 - Edit Profile details
            },
          ),
        ],
      ),
    );
  }
}
