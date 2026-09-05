import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logging/app_logger.dart';

/// Representation of the student clinician's saved profile credentials.
class UserProfile {
  const UserProfile({
    required this.name,
    required this.university,
    required this.academicYear,
  });

  final String name;
  final String university;
  final String academicYear;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          university == other.university &&
          academicYear == other.academicYear;

  @override
  int get hashCode => name.hashCode ^ university.hashCode ^ academicYear.hashCode;
}

/// Central offline preferences and configuration repository for Dentera.
///
/// Wraps [SharedPreferences] to persistently retain clinical student identity,
/// UI theme modes, application language locales, and local notification toggles.
///
/// **Pre-Frame Initialization Architecture:**
/// To eliminate UI flashing or unexpected theme changes after startup, preferences such as
/// `themeMode` and `locale` are initialized synchronously or bound through reactive Riverpod
/// StateNotifier providers connected to the root [MaterialApp] in `main.dart`.
/// When the app boots, Riverpod evaluates [themeModeProvider] and [localeProvider],
/// applying the stored theme mode (System, Light, or Dark) and language locale before the
/// initial widget frame completes rendering.
class PreferencesRepository {
  PreferencesRepository([SharedPreferences? prefs]) : _prefs = prefs;

  SharedPreferences? _prefs;

  static const String _keyHasCompletedOnboarding = 'hasCompletedOnboarding';
  static const String _keyDoctorName = 'doctorName';
  static const String _keyUniversity = 'university';
  static const String _keyAcademicYear = 'academicYear';
  static const String _keyRemindersEnabled = 'remindersEnabled';
  static const String _keyThemeMode = 'themeMode';
  static const String _keyLocale = 'locale';
  static const String _keyFollowUpAlertsEnabled = 'followUpAlertsEnabled';

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Checks if the user has already completed the initial onboarding walkthrough.
  Future<bool> hasCompletedOnboarding() async {
    final prefs = await _instance;
    return prefs.getBool(_keyHasCompletedOnboarding) ?? false;
  }

  /// Flags onboarding as completed.
  Future<void> setCompletedOnboarding(bool completed) async {
    final prefs = await _instance;
    await prefs.setBool(_keyHasCompletedOnboarding, completed);
    AppLogger.info('User preference updated: Onboarding completed = $completed');
  }

  /// Persists the user profile details captured during onboarding or profile editing.
  Future<void> saveUserProfile({
    required String name,
    required String university,
    required String academicYear,
  }) async {
    final prefs = await _instance;
    await Future.wait(<Future<bool>>[
      prefs.setString(_keyDoctorName, name),
      prefs.setString(_keyUniversity, university),
      prefs.setString(_keyAcademicYear, academicYear),
      prefs.setBool(_keyHasCompletedOnboarding, true),
    ]);
    AppLogger.info('Profile details updated successfully');
  }

  /// Retrieves the saved student doctor's name.
  Future<String?> getDoctorName() async {
    final prefs = await _instance;
    return prefs.getString(_keyDoctorName);
  }

  /// Retrieves the saved academic institution/university.
  Future<String?> getUniversity() async {
    final prefs = await _instance;
    return prefs.getString(_keyUniversity);
  }

  /// Retrieves the saved academic year classification.
  Future<String?> getAcademicYear() async {
    final prefs = await _instance;
    return prefs.getString(_keyAcademicYear);
  }

  /// Checks if next-day clinical agenda reminders are enabled. Default is true.
  Future<bool> getRemindersEnabled() async {
    final prefs = await _instance;
    return prefs.getBool(_keyRemindersEnabled) ?? true;
  }

  /// Persists the next-day clinical agenda reminders preference.
  Future<void> setRemindersEnabled(bool enabled) async {
    final prefs = await _instance;
    await prefs.setBool(_keyRemindersEnabled, enabled);
    AppLogger.info('User preference updated: Next-day agenda reminders ${enabled ? "enabled" : "disabled"}');
  }

  /// Retrieves the active application theme mode (system, light, or dark).
  Future<ThemeMode> getThemeMode() async {
    final prefs = await _instance;
    final value = prefs.getString(_keyThemeMode);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Persists the application theme mode preference.
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await _instance;
    await prefs.setString(_keyThemeMode, mode.name);
    AppLogger.info('User preference updated: ThemeMode set to ${mode.name}');
  }

  /// Retrieves the saved language locale (e.g., 'en', 'ar'). Default is 'en'.
  Future<String> getLocale() async {
    final prefs = await _instance;
    return prefs.getString(_keyLocale) ?? 'en';
  }

  /// Persists the language locale preference.
  Future<void> setLocale(String locale) async {
    final prefs = await _instance;
    await prefs.setString(_keyLocale, locale);
    AppLogger.info('User preference updated: Locale set to $locale');
  }

  /// Checks if patient follow-up alert notifications are enabled. Default is true.
  Future<bool> getFollowUpAlertsEnabled() async {
    final prefs = await _instance;
    return prefs.getBool(_keyFollowUpAlertsEnabled) ?? true;
  }

  /// Persists the patient follow-up alerts preference.
  Future<void> setFollowUpAlertsEnabled(bool enabled) async {
    final prefs = await _instance;
    await prefs.setBool(_keyFollowUpAlertsEnabled, enabled);
    AppLogger.info('User preference updated: Patient follow-up alerts ${enabled ? "enabled" : "disabled"}');
  }

  /// Completely wipes all persisted preferences from disk.
  Future<void> clearAll() async {
    final prefs = await _instance;
    await prefs.clear();
    AppLogger.info('All preferences cleared from disk');
  }
}

// =============================================================================
// REACTIVE RIVERPOD STATE NOTIFIERS & PROVIDERS
// =============================================================================

/// Riverpod provider for the singleton [PreferencesRepository] instance.
final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository();
});

/// Reactive StateNotifier managing the active [ThemeMode].
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._repository) : super(ThemeMode.system) {
    _loadInitialTheme();
  }

  final PreferencesRepository _repository;

  Future<void> _loadInitialTheme() async {
    final savedMode = await _repository.getThemeMode();
    state = savedMode;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _repository.setThemeMode(mode);
  }
}

/// Reactive provider for the active [ThemeMode].
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final repo = ref.watch(preferencesRepositoryProvider);
  return ThemeModeNotifier(repo);
});

/// Reactive StateNotifier managing the active language locale string (e.g. 'en', 'ar').
class LocaleNotifier extends StateNotifier<String> {
  LocaleNotifier(this._repository) : super('en') {
    _loadInitialLocale();
  }

  final PreferencesRepository _repository;

  Future<void> _loadInitialLocale() async {
    final savedLocale = await _repository.getLocale();
    state = savedLocale;
  }

  Future<void> setLocale(String locale) async {
    state = locale;
    await _repository.setLocale(locale);
  }
}

/// Reactive provider for the active language locale.
final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  final repo = ref.watch(preferencesRepositoryProvider);
  return LocaleNotifier(repo);
});

/// Reactive StateNotifier managing patient follow-up alert toggles.
class FollowUpAlertsNotifier extends StateNotifier<bool> {
  FollowUpAlertsNotifier(this._repository) : super(true) {
    _loadInitialAlerts();
  }

  final PreferencesRepository _repository;

  Future<void> _loadInitialAlerts() async {
    final enabled = await _repository.getFollowUpAlertsEnabled();
    state = enabled;
  }

  Future<void> setAlertsEnabled(bool enabled) async {
    state = enabled;
    await _repository.setFollowUpAlertsEnabled(enabled);
  }
}

/// Reactive provider for patient follow-up alerts toggle.
final followUpAlertsProvider = StateNotifierProvider<FollowUpAlertsNotifier, bool>((ref) {
  final repo = ref.watch(preferencesRepositoryProvider);
  return FollowUpAlertsNotifier(repo);
});

/// Reactive StateNotifier managing next-day agenda reminder toggles.
class AgendaRemindersNotifier extends StateNotifier<bool> {
  AgendaRemindersNotifier(this._repository) : super(true) {
    _loadInitialReminders();
  }

  final PreferencesRepository _repository;

  Future<void> _loadInitialReminders() async {
    final enabled = await _repository.getRemindersEnabled();
    state = enabled;
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    state = enabled;
    await _repository.setRemindersEnabled(enabled);
  }
}

/// Reactive provider for next-day agenda reminders toggle.
final agendaRemindersProvider = StateNotifierProvider<AgendaRemindersNotifier, bool>((ref) {
  final repo = ref.watch(preferencesRepositoryProvider);
  return AgendaRemindersNotifier(repo);
});

/// Reactive StateNotifier managing user clinician credentials across the application.
class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile>> {
  UserProfileNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProfile();
  }

  final PreferencesRepository _repository;

  Future<void> loadProfile() async {
    try {
      final name = await _repository.getDoctorName() ?? 'Dr. Shehab Shaif';
      final uni = await _repository.getUniversity() ?? 'Dental School';
      final year = await _repository.getAcademicYear() ?? '5th Year';
      state = AsyncValue.data(UserProfile(
        name: name,
        university: uni,
        academicYear: year,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile({
    required String name,
    required String university,
    required String academicYear,
  }) async {
    await _repository.saveUserProfile(
      name: name,
      university: university,
      academicYear: academicYear,
    );
    state = AsyncValue.data(UserProfile(
      name: name,
      university: university,
      academicYear: academicYear,
    ));
  }
}

/// Reactive provider for the student clinician's profile state.
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile>>((ref) {
  final repo = ref.watch(preferencesRepositoryProvider);
  return UserProfileNotifier(repo);
});

/// Riverpod FutureProvider checking onboarding completion status.
final onboardingStatusProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(preferencesRepositoryProvider);
  return repo.hasCompletedOnboarding();
});

/// Backwards-compatible provider for tracking reminders preference.
final remindersEnabledProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(preferencesRepositoryProvider);
  return repo.getRemindersEnabled();
});
