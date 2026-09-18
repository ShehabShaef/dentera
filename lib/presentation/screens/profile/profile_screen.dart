import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/database_backup_service.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/theme/theme.dart';
import '../../../data/repositories/preferences_repository.dart';
import '../../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/modals/modals.dart';
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
            context.l10n.chooseAppTheme,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: Text(context.l10n.themeSystem),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(context.l10n.light),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(context.l10n.dark),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.cancel),
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
            context.l10n.chooseLanguage,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: Text(context.l10n.english),
                  value: 'en',
                ),
                RadioListTile<String>(
                  title: Text(context.l10n.arabic),
                  value: 'ar',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.cancel),
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
        title: Text(context.l10n.restoreDatabaseBackupTitle),
        content: Text(
          context.l10n.restoreDatabaseConfirmationDetailed,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.restore),
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
      ThemeMode.system => context.l10n.themeSystem,
      ThemeMode.light => context.l10n.light,
      ThemeMode.dark => context.l10n.dark,
    };

    final currentLocale = ref.watch(localeProvider);
    final languageLabel = switch (currentLocale) {
      'ar' => context.l10n.arabic,
      _ => context.l10n.english,
    };

    final agendaRemindersEnabled = ref.watch(agendaRemindersProvider);
    final followUpAlertsEnabled = ref.watch(followUpAlertsProvider);
    final appVersion = ref.watch(appVersionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.settings,
          style: AppTextStyles.h1Mobile.copyWith(
            color: isDark ? AppDarkColors.textPrimary : AppColors.primary,
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
                    title: context.l10n.preferences,
                    children: <Widget>[
                      SettingsListTile(
                        icon: Icons.dark_mode_outlined,
                        title: context.l10n.appTheme,
                        showDivider: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              themeLabel,
                              style: AppTextStyles.bodyMd.copyWith(
                                color: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: isDark ? AppDarkColors.textMuted : AppColors.outlineVariant,
                            ),
                          ],
                        ),
                        onTap: () => _showThemeSelectionDialog(context),
                      ),
                      SettingsListTile(
                        icon: Icons.language_outlined,
                        title: context.l10n.language,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              languageLabel,
                              style: AppTextStyles.bodyMd.copyWith(
                                color: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: isDark ? AppDarkColors.textMuted : AppColors.outlineVariant,
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
                    title: context.l10n.localNotifications,
                    children: <Widget>[
                      SettingsListTile(
                        icon: Icons.event_outlined,
                        title: context.l10n.agendaReminders,
                        showDivider: true,
                        trailing: Switch.adaptive(
                           value: agendaRemindersEnabled,
                          activeTrackColor: isDark ? AppDarkColors.primaryTeal : AppColors.secondary,
                          onChanged: _onToggleAgendaReminders,
                        ),
                      ),
                      SettingsListTile(
                        icon: Icons.notifications_active_outlined,
                        title: context.l10n.patientFollowUpAlerts,
                        trailing: Switch.adaptive(
                          value: followUpAlertsEnabled,
                          activeTrackColor: isDark ? AppDarkColors.primaryTeal : AppColors.secondary,
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
                    title: context.l10n.dataAndOfflineBackup,
                    children: <Widget>[
                      SettingsListTile(
                        icon: Icons.picture_as_pdf_outlined,
                        title: context.l10n.generateQuotaReport,
                        subtitle: 'Supervisory academic PDF & CSV export',
                        showDivider: true,
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: isDark ? AppDarkColors.textMuted : AppColors.outlineVariant,
                        ),
                        onTap: () => GenerateQuotaReportModal.show(context),
                      ),
                      SettingsListTile(
                        icon: Icons.download_rounded,
                        title: context.l10n.exportLocalBackup,
                        subtitle: context.l10n.exportBackupSubtitle,
                        showDivider: true,
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: isDark ? AppDarkColors.textMuted : AppColors.outlineVariant,
                        ),
                        onTap: _onExportDatabase,
                      ),
                      SettingsListTile(
                        icon: Icons.upload_rounded,
                        title: context.l10n.restoreFromBackup,
                        subtitle: context.l10n.restoreBackupSubtitle,
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: isDark ? AppDarkColors.textMuted : AppColors.outlineVariant,
                        ),
                        onTap: _onRestoreDatabase,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 5. About & Security
                  SettingsGroupCard(
                    title: context.l10n.about,
                    children: <Widget>[
                      SettingsListTile(
                        icon: Icons.info_outline_rounded,
                        title: context.l10n.appVersion,
                        showDivider: true,
                        trailing: Text(
                          appVersion,
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppDarkColors.textMuted : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SettingsListTile(
                        icon: Icons.lock_outline_rounded,
                        title: context.l10n.privacyAndSecurity,
                        trailing: Text(
                          context.l10n.onDeviceOnly,
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppDarkColors.primaryTeal : AppColors.secondary,
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
                        context.l10n.resetAllClinicalData,
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
