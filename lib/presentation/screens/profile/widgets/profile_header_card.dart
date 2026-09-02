import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../widgets/widgets.dart';

/// Header card displaying user profile summary, avatar initial, and academic stage.
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.name,
    required this.subtitle,
    this.onEdit,
  });

  final String name;
  final String subtitle;
  final VoidCallback? onEdit;

  String get _initial {
    final clean = name.replaceAll(RegExp(r'^Dr\.\s*', caseSensitive: false), '').trim();
    if (clean.isEmpty) return 'D';
    return clean[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Large Brand Gradient Squircle Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              _initial,
              style: AppTextStyles.h1.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
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
