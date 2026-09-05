import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/services/database_backup_service.dart';
import '../../../core/theme/theme.dart';
import '../buttons/buttons.dart';
import '../inputs/inputs.dart';

/// Modal bottom sheet providing a destructive confirmation barrier for resetting
/// all local SQLite tables and student preferences.
///
/// **Safety Constraint:**
/// The destructive action button remains strictly disabled until the user explicitly
/// types the keyword `"RESET"` (case-sensitive) into the validation text field.
class DatabaseResetModal extends ConsumerStatefulWidget {
  const DatabaseResetModal({super.key});

  /// Convenience static method to summon the [DatabaseResetModal] bottom sheet.
  ///
  /// Logs an audit [AppLogger.warning] whenever the danger zone modal is opened.
  static Future<bool?> show(BuildContext context) {
    AppLogger.warning('Danger Zone accessed: Opened DatabaseResetModal.');
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DatabaseResetModal(),
    );
  }

  @override
  ConsumerState<DatabaseResetModal> createState() => _DatabaseResetModalState();
}

class _DatabaseResetModalState extends ConsumerState<DatabaseResetModal> {
  final TextEditingController _confirmationController = TextEditingController();
  bool _isResetEnabled = false;
  bool _isResetting = false;

  static const String _requiredKeyword = 'RESET';

  @override
  void initState() {
    super.initState();
    _confirmationController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _confirmationController.removeListener(_onTextChanged);
    _confirmationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isMatch = _confirmationController.text.trim() == _requiredKeyword;
    if (isMatch != _isResetEnabled) {
      setState(() {
        _isResetEnabled = isMatch;
      });
    }
  }

  Future<void> _handleConfirmReset() async {
    if (!_isResetEnabled || _isResetting) return;

    setState(() {
      _isResetting = true;
    });

    try {
      final backupService = ref.read(databaseBackupServiceProvider);
      await backupService.resetAllData();

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResetting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to reset database: $e',
            style: AppTextStyles.bodyMd.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: bottomInset + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Danger Warning Icon and Title
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Danger Zone',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Reset All Clinical Data',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Detailed Irreversible Warning
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
            ),
            child: Text(
              'This action is completely destructive and irreversible. All patients, clinical requirements, logged case sheets, appointments, and user preferences will be permanently wiped from your device.',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Verification prompt
          Text(
            'Type "RESET" in all caps below to confirm:',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          // Text Field for "RESET" confirmation
          DenteraTextField(
            controller: _confirmationController,
            hintText: 'Type RESET to confirm',
            textCapitalization: TextCapitalization.characters,
            autofocus: true,
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: <Widget>[
              Expanded(
                child: SecondaryButton(
                  text: 'Cancel',
                  onPressed: _isResetting ? null : () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isResetEnabled && !_isResetting
                        ? AppColors.error
                        : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isResetEnabled && !_isResetting ? _handleConfirmReset : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: _isResetting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Wipe All Data',
                                style: AppTextStyles.h2.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _isResetEnabled && !_isResetting
                                      ? Colors.white
                                      : AppColors.outline,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
