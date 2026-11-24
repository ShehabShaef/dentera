import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logging/app_logger.dart';

/// Representation of the student clinician's saved profile credentials.
class UserProfile {
  const UserProfile({
    this.firstName = 'Shehab',
    this.lastName = 'Shaif',
    String? name,
    required this.university,
    required this.academicYear,
    this.isGuest = false,
  }) : _legacyName = name;

  final String firstName;
  final String lastName;
  final String? _legacyName;
  final String university;
  final String academicYear;
  final bool isGuest;

  /// Returns the full formatted doctor name with programmatic prefix: "Dr. [FirstName] [LastName]".
  String formattedFullDoctorName([String? locale]) {
    final isAr = locale?.toLowerCase().startsWith('ar') ?? false;
    final prefix = isAr ? 'د.' : 'Dr.';
    if (isGuest) {
      return isAr ? 'د. ضيف' : 'Dr. Guest';
    }
    final cleanFirst = PreferencesRepository.stripDoctorPrefix(firstName).trim();
    final cleanLast = PreferencesRepository.stripDoctorPrefix(lastName).trim();
    final full = '$cleanFirst $cleanLast'.trim();
    if (full.isEmpty) {
      if (_legacyName != null && _legacyName.trim().isNotEmpty) {
        final cleanLegacy = PreferencesRepository.stripDoctorPrefix(_legacyName).trim();
        return cleanLegacy.isEmpty ? '$prefix Doctor' : '$prefix $cleanLegacy';
      }
      return isAr ? 'د. طبيب' : 'Dr. Doctor';
    }
    return '$prefix $full';
  }

  /// Returns the short formatted doctor name: "Dr. [FirstName]".
  String formattedShortDoctorName([String? locale]) {
    final isAr = locale?.toLowerCase().startsWith('ar') ?? false;
    final prefix = isAr ? 'د.' : 'Dr.';
    if (isGuest) {
      return isAr ? 'د. ضيف' : 'Dr. Guest';
    }
    final cleanFirst = PreferencesRepository.stripDoctorPrefix(firstName).trim();
    if (cleanFirst.isNotEmpty) {
      return '$prefix $cleanFirst';
    }
    if (_legacyName != null && _legacyName.trim().isNotEmpty) {
      final cleanLegacy = PreferencesRepository.stripDoctorPrefix(_legacyName).trim();
      final first = cleanLegacy.split(RegExp(r'\s+')).first;
      return '$prefix $first';
    }
    return isAr ? 'د. طبيب' : 'Dr. Doctor';
  }

  /// Enforces programmatic "Dr." prefix for full clinician name.
  String get name => formattedFullDoctorName();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          firstName == other.firstName &&
          lastName == other.lastName &&
          university == other.university &&
          academicYear == other.academicYear &&
          isGuest == other.isGuest;

  @override
  int get hashCode =>
      firstName.hashCode ^
      lastName.hashCode ^
      university.hashCode ^
      academicYear.hashCode ^
      isGuest.hashCode;
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
  static const String _keyDoctorFirstName = 'doctorFirstName';
  static const String _keyDoctorLastName = 'doctorLastName';
  static const String _keyDoctorName = 'doctorName';
  static const String _keyUniversity = 'university';
  static const String _keyAcademicYear = 'academicYear';
  static const String _keyRemindersEnabled = 'remindersEnabled';
  static const String _keyThemeMode = 'themeMode';
  static const String _keyLocale = 'locale';
  static const String _keyFollowUpAlertsEnabled = 'followUpAlertsEnabled';
  static const String _keyAvatarPath = 'avatarPath';
  static const String _keyIsGuest = 'isGuest';

  /// Returns the system/device default languageCode ('ar' if system locale is Arabic, otherwise 'en').
  static String get defaultDeviceLanguageCode {
    try {
      final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode.toLowerCase();
      if (code == 'ar') return 'ar';
    } catch (_) {}
    return 'en';
  }

  /// Strips any manual "Dr.", "Dr", "Doctor", "د.", "د/", or "د " prefix.
  static String stripDoctorPrefix(String raw) {
    var s = raw.trim();
    final pattern = RegExp(r'^(dr\.|dr|doctor|د\.|د/|د)\s*', caseSensitive: false);
    while (pattern.hasMatch(s)) {
      s = s.replaceFirst(pattern, '').trim();
    }
    return s;
  }

  /// Splits a full name string into (firstName, lastName) after stripping manual prefixes.
  static (String, String) splitFullName(String fullName) {
    final clean = stripDoctorPrefix(fullName).trim();
    if (clean.isEmpty) return ('', '');
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return (parts[0], '');
    }
    final first = parts[0];
    final last = parts.sublist(1).join(' ');
    return (first, last);
  }

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

  /// Checks if the current user profile is operating in Guest Mode.
  Future<bool> isGuest() async {
    final prefs = await _instance;
    return prefs.getBool(_keyIsGuest) ?? false;
  }

  /// Persists the user profile details captured during onboarding or profile editing.
  /// Supports separate [firstName] and [lastName], [isGuest] mode, with backward-compatible fallback for legacy [name].
  Future<void> saveUserProfile({
    String? firstName,
    String? lastName,
    String? name,
    required String university,
    required String academicYear,
    bool isGuest = false,
  }) async {
    final prefs = await _instance;

    String effectiveFirst = firstName ?? '';
    String effectiveLast = lastName ?? '';

    if (effectiveFirst.isEmpty && effectiveLast.isEmpty && name != null) {
      final split = splitFullName(name);
      effectiveFirst = split.$1;
      effectiveLast = split.$2;
    } else {
      effectiveFirst = stripDoctorPrefix(effectiveFirst);
      effectiveLast = stripDoctorPrefix(effectiveLast);
    }

    final fullName = '$effectiveFirst $effectiveLast'.trim();
    final legacyDoctorName = fullName.isNotEmpty ? 'Dr. $fullName' : 'Dr. Doctor';

    await Future.wait(<Future<bool>>[
      prefs.setString(_keyDoctorFirstName, effectiveFirst),
      prefs.setString(_keyDoctorLastName, effectiveLast),
      prefs.setString(_keyDoctorName, legacyDoctorName),
      prefs.setString(_keyUniversity, university),
      prefs.setString(_keyAcademicYear, academicYear),
      prefs.setBool(_keyIsGuest, isGuest),
      prefs.setBool(_keyHasCompletedOnboarding, true),
    ]);
    AppLogger.info('Profile details updated successfully: Dr. $effectiveFirst $effectiveLast (isGuest: $isGuest)');
  }

  /// Retrieves the doctor's first name, with automatic fallback/migration from legacy doctorName.
  Future<String?> getDoctorFirstName() async {
    final prefs = await _instance;
    final first = prefs.getString(_keyDoctorFirstName);
    if (first != null && first.isNotEmpty) {
      return first;
    }
    // Fallback: migrate from legacy _keyDoctorName
    final legacyName = prefs.getString(_keyDoctorName);
    if (legacyName != null && legacyName.isNotEmpty) {
      final split = splitFullName(legacyName);
      if (split.$1.isNotEmpty) {
        await prefs.setString(_keyDoctorFirstName, split.$1);
        if (split.$2.isNotEmpty) {
          await prefs.setString(_keyDoctorLastName, split.$2);
        }
        return split.$1;
      }
    }
    return null;
  }

  /// Retrieves the doctor's last name, with automatic fallback/migration from legacy doctorName.
  Future<String?> getDoctorLastName() async {
    final prefs = await _instance;
    final last = prefs.getString(_keyDoctorLastName);
    if (last != null) {
      return last;
    }
    // Fallback: migrate from legacy _keyDoctorName
    final legacyName = prefs.getString(_keyDoctorName);
    if (legacyName != null && legacyName.isNotEmpty) {
      final split = splitFullName(legacyName);
      if (split.$2.isNotEmpty) {
        await prefs.setString(_keyDoctorLastName, split.$2);
        if (split.$1.isNotEmpty && prefs.getString(_keyDoctorFirstName) == null) {
          await prefs.setString(_keyDoctorFirstName, split.$1);
        }
        return split.$2;
      }
    }
    return null;
  }

  /// Retrieves the saved student doctor's formatted name with "Dr." prefix.
  Future<String?> getDoctorName([String? locale]) async {
    final prefs = await _instance;
    final first = await getDoctorFirstName();
    final last = await getDoctorLastName();
    if (first != null && first.isNotEmpty) {
      final full = '$first ${last ?? ''}'.trim();
      final prefix = (locale?.toLowerCase().startsWith('ar') ?? false) ? 'د.' : 'Dr.';
      return '$prefix $full';
    }
    final legacy = prefs.getString(_keyDoctorName);
    if (legacy != null && legacy.isNotEmpty) {
      final clean = stripDoctorPrefix(legacy).trim();
      final prefix = (locale?.toLowerCase().startsWith('ar') ?? false) ? 'د.' : 'Dr.';
      return clean.isNotEmpty ? '$prefix $clean' : '$prefix Doctor';
    }
    return null;
  }

  /// Formatted short doctor name (e.g. "Dr. Shehab").
  Future<String> getFormattedShortDoctorName([String? locale]) async {
    final first = await getDoctorFirstName();
    final prefix = (locale?.toLowerCase().startsWith('ar') ?? false) ? 'د.' : 'Dr.';
    if (first != null && first.isNotEmpty) {
      return '$prefix $first';
    }
    return (locale?.toLowerCase().startsWith('ar') ?? false) ? 'د. طبيب' : 'Dr. Doctor';
  }

  /// Formatted full doctor name (e.g. "Dr. Shehab Shaif").
  Future<String> getFormattedFullDoctorName([String? locale]) async {
    final name = await getDoctorName(locale);
    if (name != null && name.isNotEmpty) return name;
    return (locale?.toLowerCase().startsWith('ar') ?? false) ? 'د. طبيب' : 'Dr. Doctor';
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

  /// Retrieves the saved profile avatar file path, or null if none is set.
  Future<String?> getAvatarPath() async {
    final prefs = await _instance;
    return prefs.getString(_keyAvatarPath);
  }

  /// Persists the custom profile avatar file path.
  Future<void> saveAvatarPath(String path) async {
    final prefs = await _instance;
    await prefs.setString(_keyAvatarPath, path);
    AppLogger.info('User preference updated: Avatar path set to $path');
  }

  /// Removes the saved profile avatar file path.
  Future<void> clearAvatarPath() async {
    final prefs = await _instance;
    await prefs.remove(_keyAvatarPath);
    AppLogger.info('User preference updated: Avatar path removed');
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

  /// Retrieves the saved language locale (e.g., 'en', 'ar').
  /// If no explicit preference has been saved yet, auto-detects device language:
  /// defaults to 'ar' if device language is Arabic, otherwise 'en'.
  Future<String> getLocale() async {
    final prefs = await _instance;
    final saved = prefs.getString(_keyLocale);
    if (saved != null && saved.isNotEmpty) {
      return saved;
    }
    return defaultDeviceLanguageCode;
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
    final avatarPath = prefs.getString(_keyAvatarPath);
    if (avatarPath != null) {
      try {
        final file = File(avatarPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        AppLogger.warning('Failed to delete avatar file on clearAll: $e');
      }
    }
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
  LocaleNotifier(this._repository) : super(PreferencesRepository.defaultDeviceLanguageCode) {
    _loadInitialLocale();
  }

  final PreferencesRepository _repository;

  Future<void> _loadInitialLocale() async {
    final savedLocale = await _repository.getLocale();
    if (state != savedLocale) {
      state = savedLocale;
    }
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
      final first = await _repository.getDoctorFirstName() ?? 'Shehab';
      final last = await _repository.getDoctorLastName() ?? 'Shaif';
      final uni = await _repository.getUniversity() ?? 'Dental School';
      final year = await _repository.getAcademicYear() ?? '5th Year';
      final isGuest = await _repository.isGuest();
      state = AsyncValue.data(UserProfile(
        firstName: first,
        lastName: last,
        university: uni,
        academicYear: year,
        isGuest: isGuest,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? name,
    required String university,
    required String academicYear,
    bool isGuest = false,
  }) async {
    await _repository.saveUserProfile(
      firstName: firstName,
      lastName: lastName,
      name: name,
      university: university,
      academicYear: academicYear,
      isGuest: isGuest,
    );
    await loadProfile();
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

/// Reactive StateNotifier managing user clinician profile avatar file path.
class AvatarNotifier extends StateNotifier<String?> {
  AvatarNotifier(this._repository) : super(null) {
    _loadInitialAvatar();
  }

  final PreferencesRepository _repository;

  bool get _isTestEnvironment =>
      Platform.environment.containsKey('FLUTTER_TEST') ||
      Platform.executable.contains('flutter_tester') ||
      WidgetsBinding.instance.runtimeType.toString().toLowerCase().contains('test');

  Future<void> _loadInitialAvatar() async {
    final path = await _repository.getAvatarPath();
    if (path != null) {
      if (_isTestEnvironment || File(path).existsSync()) {
        state = path;
        return;
      }
    }
    state = null;
  }

  /// Updates the avatar file path in memory and persists to preferences.
  Future<void> setAvatarPath(String path) async {
    state = path;
    await _repository.saveAvatarPath(path);
  }

  /// Removes the avatar, deletes the sandboxed file from disk, and updates preferences.
  Future<void> clearAvatar() async {
    final currentPath = state ?? await _repository.getAvatarPath();
    if (currentPath != null) {
      try {
        final file = File(currentPath);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        AppLogger.warning('Failed to delete avatar file from disk: $e');
      }
    }
    state = null;
    await _repository.clearAvatarPath();
  }

  /// Picks an image from [source] (camera or gallery), resizes to max 512x512 with 85% quality,
  /// saves to sandboxed `app_flutter/profile_avatar.jpg`, and updates state.
  Future<String?> pickAndSaveAvatar({
    required ImageSource source,
    ImagePicker? picker,
  }) async {
    try {
      final imagePicker = picker ?? ImagePicker();
      final picked = await imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return null;

      final Directory appDir;
      if (_isTestEnvironment) {
        appDir = Directory.systemTemp;
      } else {
        Directory dir;
        try {
          dir = await getApplicationDocumentsDirectory();
        } catch (_) {
          dir = Directory.systemTemp;
        }
        appDir = dir;
      }

      final destinationPath = p.join(appDir.path, 'profile_avatar.jpg');
      final sourceFile = File(picked.path);
      if (await sourceFile.exists()) {
        await sourceFile.copy(destinationPath);
      } else {
        final destFile = File(destinationPath);
        if (!await destFile.exists()) {
          await destFile.create(recursive: true);
        }
      }

      await setAvatarPath(destinationPath);
      return destinationPath;
    } catch (e) {
      AppLogger.error('Failed to pick and save profile avatar', e);
      rethrow;
    }
  }
}

/// Reactive provider for the student clinician's avatar file path.
final avatarProvider = StateNotifierProvider<AvatarNotifier, String?>((ref) {
  final repo = ref.watch(preferencesRepositoryProvider);
  return AvatarNotifier(repo);
});

