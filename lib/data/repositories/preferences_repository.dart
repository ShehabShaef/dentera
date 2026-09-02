import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository for handling local device settings and onboarding state via SharedPreferences.
class PreferencesRepository {
  PreferencesRepository([SharedPreferences? prefs]) : _prefs = prefs;

  SharedPreferences? _prefs;

  static const String _keyHasCompletedOnboarding = 'hasCompletedOnboarding';
  static const String _keyDoctorName = 'doctorName';
  static const String _keyUniversity = 'university';
  static const String _keyAcademicYear = 'academicYear';
  static const String _keyRemindersEnabled = 'remindersEnabled';

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
  }

  /// Persists the user profile details captured during onboarding.
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
  }

  Future<String?> getDoctorName() async {
    final prefs = await _instance;
    return prefs.getString(_keyDoctorName);
  }

  Future<String?> getUniversity() async {
    final prefs = await _instance;
    return prefs.getString(_keyUniversity);
  }

  Future<String?> getAcademicYear() async {
    final prefs = await _instance;
    return prefs.getString(_keyAcademicYear);
  }

  /// Checks if local notification reminders are enabled. Default is true.
  Future<bool> getRemindersEnabled() async {
    final prefs = await _instance;
    return prefs.getBool(_keyRemindersEnabled) ?? true;
  }

  /// Sets notification reminders preference.
  Future<void> setRemindersEnabled(bool enabled) async {
    final prefs = await _instance;
    await prefs.setBool(_keyRemindersEnabled, enabled);
  }

  Future<void> clearAll() async {
    final prefs = await _instance;
    await prefs.clear();
  }
}

/// Riverpod provider for [PreferencesRepository].
final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository();
});

/// Riverpod FutureProvider checking onboarding completion status.
final onboardingStatusProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(preferencesRepositoryProvider);
  return repo.hasCompletedOnboarding();
});

/// Riverpod StateProvider for tracking reminders preference reactively.
final remindersEnabledProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(preferencesRepositoryProvider);
  return repo.getRemindersEnabled();
});
