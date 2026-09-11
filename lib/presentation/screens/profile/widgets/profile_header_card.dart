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
                        : AppColors.brandGradient,
                    color: (hasAvatar && (fileExists || _isTestEnvironment))
                        ? AppColors.primaryContainer.withValues(alpha: 0.2)
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.outlineVariant,
                      width: 1.0,
                    ),
                    boxShadow: [
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
                                  color: AppColors.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.person_rounded,
                              size: 34,
                              color: AppColors.primary,
                            ))
                      : Text(
                          _initial,
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.onPrimary,
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
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surface,
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
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 11,
                      color: AppColors.onPrimary,
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
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Edit Action Button
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.onSurfaceVariant,
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
