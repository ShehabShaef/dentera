import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/database_backup_service.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/theme/theme.dart';
import '../../../data/repositories/preferences_repository.dart';
import '../../widgets/modals/database_reset_modal.dart';
import 'widgets/widgets.dart';

/// Profile & Settings screen managing user profile, preferences, and offline backups.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _onToggleAgendaReminders(bool value) async {
    await ref.read(agendaRemindersProvider.notifier).setRemindersEnabled(value);
    if (!value) {
      // Opt-out: cancel all pending notification intents
      await ref.read(notificationServiceProvider).cancelAllReminders();
    }
  }

  Future<void> _showThemeSelectionDialog(BuildContext context) async {
    final current = ref.read(themeModeProvider);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Choose App Theme',
            style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w600),
          ),
          content: RadioGroup<ThemeMode>(
            groupValue: current,
            onChanged: (mode) {
              if (mode != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(mode);
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: Text('System Default'),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Light'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Dark'),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLanguageSelectionDialog(BuildContext context) async {
    final current = ref.read(localeProvider);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Choose Language',
            style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w600),
          ),
          content: RadioGroup<String>(
            groupValue: current,
            onChanged: (locale) {
              if (locale != null) {
                ref.read(localeProvider.notifier).setLocale(locale);
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: Text('English'),
                  value: 'en',
                ),
                RadioListTile<String>(
                  title: Text('العربية (Arabic)'),
                  value: 'ar',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onExportDatabase() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final backupService = ref.read(databaseBackupServiceProvider);
      final result = await backupService.exportDatabase();

      if (!mounted) return;

      if (result.isSuccess) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Database backup created successfully.',
              style: AppTextStyles.bodyMd.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ?? 'Failed to export database backup.',
              style: AppTextStyles.bodyMd.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Export failed: $e',
            style: AppTextStyles.bodyMd.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onRestoreDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore Database Backup?'),
        content: const Text(
          'Restoring a database will overwrite your current clinical data, patients, and quotas with the selected backup file.\n\nAre you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final backupService = ref.read(databaseBackupServiceProvider);
      final result = await backupService.importDatabase();

      if (!mounted) return;

      if (result.isSuccess) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Database restored successfully. Clinical records reloaded.',
              style: AppTextStyles.bodyMd.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (result.isCancelled) {
        // Restore cancelled by user: no disruptive toast needed
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ?? 'Failed to restore database.',
              style: AppTextStyles.bodyMd.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Restore failed: $e',
            style: AppTextStyles.bodyMd.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onResetAllData() async {
    final didReset = await DatabaseResetModal.show(context);
    if (didReset == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All clinical data and preferences have been successfully reset.',
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
    final userProfileAsync = ref.watch(userProfileProvider);
    final userProfile = userProfileAsync.valueOrNull ??
        const UserProfile(
          name: 'Dr. Shehab Shaif',
          university: 'Dental School',
          academicYear: '5th Year',
        );
    final doctorName = userProfile.name;
    final academicYear = userProfile.academicYear;
    final university = userProfile.university;
    final subtitle = '$academicYear Clinical Student • $university';

    final currentThemeMode = ref.watch(themeModeProvider);
    final themeLabel = switch (currentThemeMode) {
      ThemeMode.system => 'System Default',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };

    final currentLocale = ref.watch(localeProvider);
    final languageLabel = switch (currentLocale) {
      'ar' => 'العربية (Arabic)',
      _ => 'English',
    };

    final agendaRemindersEnabled = ref.watch(agendaRemindersProvider);
    final followUpAlertsEnabled = ref.watch(followUpAlertsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTextStyles.h1Mobile.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 1. Profile Header Card
                  ProfileHeaderCard(
                    name: doctorName,
                    subtitle: subtitle,
                    onEdit: () => EditProfileModal.show(context),
                  ),
                  const SizedBox(height: 24),

                  // 2. Preferences
                  SettingsGroupCard(
                    title: 'Preferences',
                    children: <Widget>[
                      SettingsListTile(
                        icon: Icons.dark_mode_outlined,
                        title: 'App Theme',
                        showDivider: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              themeLabel,
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: AppColors.outlineVariant,
                            ),
                          ],
                        ),
                        onTap: () => _showThemeSelectionDialog(context),
                      ),
                      SettingsListTile(
                        icon: Icons.language_outlined,
                        title: 'Language',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              languageLabel,
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: AppColors.outlineVariant,
                            ),
                          ],
                        ),
                        onTap: () => _showLanguageSelectionDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. Local Notifications
                  SettingsGroupCard(
                    title: 'Local Notifications',
                    children: <Widget>[
                      SettingsListTile(
                        icon: Icons.event_outlined,
                        title: 'Next-Day Agenda Reminders',
                        showDivider: true,
                        trailing: Switch.adaptive(
                          value: agendaRemindersEnabled,
                          activeTrackColor: AppColors.secondary,
                          onChanged: _onToggleAgendaReminders,
                        ),
                      ),
                      SettingsListTile(
                        icon: Icons.notifications_active_outlined,
                        title: 'Patient Follow-up Alerts',
                        trailing: Switch.adaptive(
                          value: followUpAlertsEnabled,
                          activeTrackColor: AppColors.secondary,
                          onChanged: (val) {
                            ref.read(followUpAlertsProvider.notifier).setAlertsEnabled(val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4. Data & Offline Backup
                  SettingsGroupCard(
                    title: 'Data & Offline Backup',
                    children: <Widget>[
                      SettingsListTile(
                        icon: Icons.download_rounded,
                        title: 'Export Local Backup',
                        subtitle: 'Save an encrypted SQLite copy to your device',
                        showDivider: true,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.outlineVariant,
                        ),
                        onTap: _onExportDatabase,
                      ),
                      SettingsListTile(
                        icon: Icons.upload_rounded,
                        title: 'Restore from Backup',
                        subtitle: 'Import data from a local backup file',
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.outlineVariant,
                        ),
                        onTap: _onRestoreDatabase,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 5. About & Security
                  SettingsGroupCard(
                    title: 'About',
                    children: <Widget>[
                      SettingsListTile(
                        icon: Icons.info_outline_rounded,
                        title: 'App Version',
                        showDivider: true,
                        trailing: Text(
                          'v0.1.0 (Offline Build)',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SettingsListTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Privacy & Security',
                        trailing: Text(
                          '100% On-Device',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 6. Danger Zone
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _onResetAllData,
                      icon: const Icon(
                        Icons.delete_forever_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      label: Text(
                        'Reset All Clinical Data',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error, width: 1.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
