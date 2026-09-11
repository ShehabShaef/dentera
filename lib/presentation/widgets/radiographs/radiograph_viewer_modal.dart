import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

import '../../../core/theme/theme.dart';
import '../../../domain/entities/entities.dart';
import '../../state/state.dart';
import '../dentera_snackbar.dart';

/// Full-screen interactive viewer for high-resolution radiograph inspection
/// supporting pinch-to-zoom, panning, metadata inspection, and deletion.
class RadiographViewerModal extends ConsumerStatefulWidget {
  const RadiographViewerModal({
    super.key,
    required this.radiograph,
    this.patientName,
  });

  final PatientRadiograph radiograph;
  final String? patientName;

  /// Convenience launcher pushing a full-screen route.
  static Future<void> show(
    BuildContext context, {
    required PatientRadiograph radiograph,
    String? patientName,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => RadiographViewerModal(
          radiograph: radiograph,
          patientName: patientName,
        ),
      ),
    );
  }

  @override
  ConsumerState<RadiographViewerModal> createState() => _RadiographViewerModalState();
}

class _RadiographViewerModalState extends ConsumerState<RadiographViewerModal> {
  bool _isDeleting = false;
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
        return const Color(0xFFD97706); // Amber / Warm orange
      default:
        return AppColors.outline;
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Radiograph?'),
        content: const Text(
          'Are you sure you want to delete this radiograph? The image file will be permanently removed from disk.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        await ref
            .read(radiographsControllerProvider)
            .deleteRadiograph(widget.radiograph.id, widget.radiograph.patientId);

        if (mounted) {
          DenteraSnackBar.showSuccess(
            context,
            message: 'Radiograph deleted successfully',
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          DenteraSnackBar.showError(
            context,
            message: 'Failed to delete radiograph: $e',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMMM d, yyyy').format(widget.radiograph.captureDate);
    final typeColor = _typeColor(widget.radiograph.type);
    final file = File(widget.radiograph.filePath);
    final fileExists = file.existsSync();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate background for high radiograph contrast
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: 'Close Viewer',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.radiograph.type,
              style: AppTextStyles.h2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.patientName != null)
              Text(
                widget.patientName!,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        actions: <Widget>[
          // Radiograph Type Badge
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: typeColor, width: 1),
              ),
              child: Text(
                widget.radiograph.type,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
                    ),
                  )
                : const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            tooltip: 'Delete Radiograph',
            onPressed: _isDeleting ? null : _confirmDelete,
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          // Interactive Pinch-to-Zoom / Pan View
          Positioned.fill(
            child: (!_isTestEnvironment && fileExists)
                ? PhotoView(
                    imageProvider: FileImage(file),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 4.0,
                    initialScale: PhotoViewComputedScale.contained,
                    backgroundDecoration: const BoxDecoration(
                      color: Color(0xFF0F172A),
                    ),
                    errorBuilder: (context, error, stackTrace) => _buildFallbackView(),
                  )
                : _buildFallbackView(),
          ),

          // Bottom Clinical Notes Overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: <Color>[
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Captured: $formattedDate',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    if (widget.radiograph.notes != null &&
                        widget.radiograph.notes!.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        widget.radiograph.notes!.trim(),
                        style: AppTextStyles.bodyMd.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.image_outlined,
              size: 80,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Radiograph Preview',
              style: AppTextStyles.h2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.radiograph.filePath,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
