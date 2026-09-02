import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// Reusable tile component for settings menus, preferences, and data tools.
class SettingsListTile extends StatelessWidget {
  const SettingsListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                crossAxisAlignment: subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: <Widget>[
                  // Leading Icon
                  Icon(
                    icon,
                    size: 22,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 14),

                  // Title & Optional Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (subtitle != null) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Trailing Widget
                  if (trailing != null) ...<Widget>[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 0.8,
            color: AppColors.surfaceVariant,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
