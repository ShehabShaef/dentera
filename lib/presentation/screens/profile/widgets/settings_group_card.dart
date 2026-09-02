import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// Group card container for grouping related settings tiles.
class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
              width: 1.0,
            ),
            boxShadow: AppColors.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}
