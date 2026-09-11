import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/theme.dart';
import '../../state/state.dart';
import '../cards/cards.dart';
import '../dentera_snackbar.dart';

/// Modal bottom sheet allowing clinicians to upload, change, or remove their profile avatar.
class AvatarPickerModal extends ConsumerStatefulWidget {
  const AvatarPickerModal({super.key});

  /// Convenience static method to display the [AvatarPickerModal] bottom sheet.
  static Future<String?> show(BuildContext context) {
    AppLogger.info('Opened AvatarPickerModal');
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AvatarPickerModal(),
    );
  }

  @override
  ConsumerState<AvatarPickerModal> createState() => _AvatarPickerModalState();
}

class _AvatarPickerModalState extends ConsumerState<AvatarPickerModal> {
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoading = true);
    try {
      final savedPath = await ref.read(avatarProvider.notifier).pickAndSaveAvatar(source: source);
      if (savedPath != null && mounted) {
        setState(() => _isLoading = false);
        DenteraSnackBar.showSuccess(
          context,
          message: 'Profile photo updated successfully',
        );
        Navigator.of(context).pop(savedPath);
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      AppLogger.error('Failed to pick and save avatar: $e', e);
      if (mounted) {
        setState(() => _isLoading = false);
        DenteraSnackBar.showError(
          context,
          message: 'Failed to update profile photo: $e',
        );
      }
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(avatarProvider.notifier).clearAvatar();
      if (mounted) {
        setState(() => _isLoading = false);
        DenteraSnackBar.showSuccess(
          context,
          message: 'Profile photo removed',
        );
        Navigator.of(context).pop('');
      }
    } catch (e) {
      AppLogger.error('Failed to remove avatar: $e', e);
      if (mounted) {
        setState(() => _isLoading = false);
        DenteraSnackBar.showError(
          context,
          message: 'Failed to remove profile photo: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatar = ref.watch(avatarProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottomInset + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Profile Photo',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose an image source to update your avatar',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                tooltip: 'Close',
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else ...<Widget>[
            // 1. Camera Option
            BaseCard(
              padding: EdgeInsets.zero,
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Take Photo',
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Use camera to capture a new picture',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Gallery Option
            BaseCard(
              padding: EdgeInsets.zero,
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Select a photo from device photo library',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ),

            // 3. Remove Photo Option (if avatar is active)
            if (currentAvatar != null && currentAvatar.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              BaseCard(
                padding: EdgeInsets.zero,
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      'Remove Photo',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    subtitle: Text(
                      'Revert back to default clinician initials',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onTap: _removeAvatar,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
