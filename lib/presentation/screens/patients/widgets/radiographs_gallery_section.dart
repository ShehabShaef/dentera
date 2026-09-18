import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../domain/entities/entities.dart';
import '../../../state/state.dart';
import '../../../widgets/cards/base_card.dart';
import '../../../widgets/modals/add_radiograph_modal.dart';
import '../../../widgets/radiographs/radiograph_viewer_modal.dart';

/// Embedded gallery section in the Patient Case Sheet displaying offline-available
/// dental radiographs (periapical, bitewings, panoramic) with interactive zoom viewer launch.
class RadiographsGallerySection extends ConsumerWidget {
  const RadiographsGallerySection({
    super.key,
    required this.patient,
  });

  final Patient patient;

  bool get _isTestEnvironment =>
      Platform.environment.containsKey('FLUTTER_TEST') ||
      Platform.executable.contains('flutter_tester') ||
      WidgetsBinding.instance.runtimeType.toString().toLowerCase().contains('test');

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'periapical':
        return AppColors.primary;
      case 'bitewing':
        return AppColors.secondary;
      case 'panoramic':
        return const Color(0xFFD97706);
      default:
        return AppColors.outline;
    }
  }

  void _openAddRadiograph(BuildContext context) {
    AddRadiographModal.show(
      context,
      patientId: patient.id,
      patientName: patient.name,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radiographsAsync = ref.watch(radiographsByPatientProvider(patient.id));

    return BaseCard(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header Row
          Row(
            children: <Widget>[
              Icon(
                Icons.camera_alt_outlined,
                size: 20,
                color: isDark ? AppDarkColors.primaryTeal : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'Radiographs',
                            style: AppTextStyles.h2.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppDarkColors.textPrimary : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          radiographsAsync.when(
                            data: (items) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppDarkColors.primaryTeal.withValues(alpha: 0.15)
                                    : AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${items.length}',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppDarkColors.primaryTeal : AppColors.primary,
                                ),
                              ),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (err, stack) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                      label: const Text('Attach X-Ray'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(color: isDark ? AppDarkColors.borderMuted : AppColors.primary),
                      ),
                      onPressed: () => _openAddRadiograph(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Content Area
          radiographsAsync.when(
            data: (radiographs) {
              if (radiographs.isEmpty) {
                return _buildEmptyState(context);
              }
              return _buildRadiographsList(context, ref, radiographs);
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'Failed to load radiographs: $err',
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceContainer : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.image_search_outlined,
            size: 24,
            color: isDark ? AppDarkColors.textMuted : AppColors.outlineVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No radiographs attached. Attach periapical, bitewing, or panoramic X-rays for offline diagnostic review.',
              style: AppTextStyles.caption.copyWith(
                color: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            onPressed: () => _openAddRadiograph(context),
            child: const Text('Attach'),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiographsList(
    BuildContext context,
    WidgetRef ref,
    List<PatientRadiograph> radiographs,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: radiographs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = radiographs[index];
          final typeColor = _typeColor(item.type);
          final formattedDate = DateFormat('MMM d, yyyy').format(item.captureDate);
          final file = File(item.filePath);
          final exists = file.existsSync();

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => RadiographViewerModal.show(
              context,
              radiograph: item,
              patientName: patient.name,
            ),
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // Dark slate radiograph backdrop
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppDarkColors.borderSubtle : AppColors.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Thumbnail preview
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        (!_isTestEnvironment && exists)
                            ? Image.file(
                                file,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderThumbnail(),
                              )
                            : _buildPlaceholderThumbnail(),
                        // Top Type Tag Badge
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: typeColor, width: 1),
                            ),
                            child: Text(
                              item.type,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Metadata Bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    color: isDark ? AppDarkColors.surfaceContainer : AppColors.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          formattedDate,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppDarkColors.textPrimary : AppColors.onSurface,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.notes != null && item.notes!.trim().isNotEmpty) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(
                            item.notes!.trim(),
                            style: AppTextStyles.caption.copyWith(
                              color: isDark ? AppDarkColors.textSecondary : AppColors.onSurfaceVariant,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderThumbnail() {
    return Container(
      color: const Color(0xFF1E293B),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.camera_alt_outlined,
              size: 28,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              'X-Ray',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white60,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
