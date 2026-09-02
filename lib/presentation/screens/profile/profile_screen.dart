import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/local_notification_service.dart';
import '../../../core/theme/theme.dart';
import '../../../data/repositories/preferences_repository.dart';
import 'widgets/widgets.dart';

/// Profile & Settings screen managing user profile, preferences, and offline backups.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _agendaRemindersEnabled = true;
  bool _followUpAlertsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefsRepo = ref.read(preferencesRepositoryProvider);
    final reminders = await prefsRepo.getRemindersEnabled();
    if (mounted) {
      setState(() {
        _agendaRemindersEnabled = reminders;
      });
    }
  }

  Future<void> _onToggleAgendaReminders(bool value) async {
    setState(() {
      _agendaRemindersEnabled = value;
    });

    final prefsRepo = ref.read(preferencesRepositoryProvider);
    await prefsRepo.setRemindersEnabled(value);

    if (!value) {
      // Opt-out: cancel all pending notification intents
      await ref.read(notificationServiceProvider).cancelAllReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefsRepo = ref.watch(preferencesRepositoryProvider);

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
        child: FutureBuilder<Map<String, String?>>(
          future: Future.wait([
            prefsRepo.getDoctorName(),
            prefsRepo.getAcademicYear(),
            prefsRepo.getUniversity(),
          ]).then((results) => {
                'name': results[0],
                'year': results[1],
                'university': results[2],
              }),
          builder: (context, snapshot) {
            final doctorName = snapshot.data?['name'] ?? 'Dr. Shehab Shaif';
            final academicYear = snapshot.data?['year'] ?? '5th Year';
            final university = snapshot.data?['university'] ?? 'Dental School';
            final subtitle = '$academicYear Clinical Student • $university';

            return SingleChildScrollView(
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
                        onEdit: () {
                          // TODO: Phase 5.5 - Edit Profile Modal
                        },
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
                                  'System Default',
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
                            onTap: () {
                              // TODO: Theme selection modal
                            },
                          ),
                          SettingsListTile(
                            icon: Icons.language_outlined,
                            title: 'Language',
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  'English',
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
                            onTap: () {
                              // TODO: Language selection modal
                            },
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
                              value: _agendaRemindersEnabled,
                              activeTrackColor: AppColors.secondary,
                              onChanged: _onToggleAgendaReminders,
                            ),
                          ),
                          SettingsListTile(
                            icon: Icons.notifications_active_outlined,
                            title: 'Patient Follow-up Alerts',
                            trailing: Switch.adaptive(
                              value: _followUpAlertsEnabled,
                              activeTrackColor: AppColors.secondary,
                              onChanged: (val) {
                                setState(() {
                                  _followUpAlertsEnabled = val;
                                });
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
                            onTap: () {
                              // TODO: Phase 7 - Trigger local SQLite export
                            },
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
                            onTap: () {
                              // TODO: Phase 7 - Trigger local SQLite import
                            },
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
                          onPressed: () {
                            // TODO: Phase 7 - Confirm reset clinical database
                          },
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
            );
          },
        ),
      ),
    );
  }
}
