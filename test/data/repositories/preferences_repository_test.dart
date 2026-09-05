import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/data/repositories/preferences_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreferencesRepository Unit Tests', () {
    late PreferencesRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = PreferencesRepository();
    });

    test('ThemeMode defaults to system and persists updates correctly', () async {
      final initialMode = await repository.getThemeMode();
      expect(initialMode, equals(ThemeMode.system));

      await repository.setThemeMode(ThemeMode.dark);
      expect(await repository.getThemeMode(), equals(ThemeMode.dark));

      await repository.setThemeMode(ThemeMode.light);
      expect(await repository.getThemeMode(), equals(ThemeMode.light));
    });

    test('ThemeMode gracefully falls back to system on invalid saved value', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'invalid_mode_name'});
      final mode = await repository.getThemeMode();
      expect(mode, equals(ThemeMode.system));
    });

    test('Locale defaults to "en" and persists updates correctly', () async {
      final initialLocale = await repository.getLocale();
      expect(initialLocale, equals('en'));

      await repository.setLocale('ar');
      expect(await repository.getLocale(), equals('ar'));
    });

    test('Follow-up alerts default to true and persist updates', () async {
      final initialAlerts = await repository.getFollowUpAlertsEnabled();
      expect(initialAlerts, isTrue);

      await repository.setFollowUpAlertsEnabled(false);
      expect(await repository.getFollowUpAlertsEnabled(), isFalse);

      await repository.setFollowUpAlertsEnabled(true);
      expect(await repository.getFollowUpAlertsEnabled(), isTrue);
    });

    test('Reminders enabled defaults to true and persists updates', () async {
      expect(await repository.getRemindersEnabled(), isTrue);

      await repository.setRemindersEnabled(false);
      expect(await repository.getRemindersEnabled(), isFalse);
    });

    test('saveUserProfile persists and retrieves doctor credentials', () async {
      expect(await repository.getDoctorName(), isNull);
      expect(await repository.getUniversity(), isNull);
      expect(await repository.getAcademicYear(), isNull);

      await repository.saveUserProfile(
        name: 'Dr. John Doe',
        university: 'Cairo University',
        academicYear: '4th Year',
      );

      expect(await repository.getDoctorName(), equals('Dr. John Doe'));
      expect(await repository.getUniversity(), equals('Cairo University'));
      expect(await repository.getAcademicYear(), equals('4th Year'));
    });

    test('clearAll wipes all stored keys from preferences', () async {
      await repository.setThemeMode(ThemeMode.dark);
      await repository.setLocale('ar');
      await repository.setFollowUpAlertsEnabled(false);
      await repository.saveUserProfile(
        name: 'Dr. Test',
        university: 'Test Uni',
        academicYear: 'Final Year',
      );

      await repository.clearAll();

      expect(await repository.getThemeMode(), equals(ThemeMode.system));
      expect(await repository.getLocale(), equals('en'));
      expect(await repository.getFollowUpAlertsEnabled(), isTrue);
      expect(await repository.getDoctorName(), isNull);
    });
  });

  group('Riverpod Notifiers Unit Tests', () {
    late PreferencesRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = PreferencesRepository();
    });

    test('ThemeModeNotifier initial value and state transition', () async {
      final notifier = ThemeModeNotifier(repository);
      expect(notifier.state, equals(ThemeMode.system));

      await notifier.setThemeMode(ThemeMode.dark);
      expect(notifier.state, equals(ThemeMode.dark));
      expect(await repository.getThemeMode(), equals(ThemeMode.dark));
    });

    test('LocaleNotifier initial value and state transition', () async {
      final notifier = LocaleNotifier(repository);
      expect(notifier.state, equals('en'));

      await notifier.setLocale('ar');
      expect(notifier.state, equals('ar'));
      expect(await repository.getLocale(), equals('ar'));
    });

    test('FollowUpAlertsNotifier initial value and state transition', () async {
      final notifier = FollowUpAlertsNotifier(repository);
      expect(notifier.state, isTrue);

      await notifier.setAlertsEnabled(false);
      expect(notifier.state, isFalse);
      expect(await repository.getFollowUpAlertsEnabled(), isFalse);
    });

    test('AgendaRemindersNotifier initial value and state transition', () async {
      final notifier = AgendaRemindersNotifier(repository);
      expect(notifier.state, isTrue);

      await notifier.setRemindersEnabled(false);
      expect(notifier.state, isFalse);
      expect(await repository.getRemindersEnabled(), isFalse);
    });

    test('UserProfileNotifier loads defaults and updates reactively', () async {
      final notifier = UserProfileNotifier(repository);
      await notifier.loadProfile();

      final profile = notifier.state.value;
      expect(profile, isNotNull);
      expect(profile!.name, equals('Dr. Shehab Shaif'));
      expect(profile.university, equals('Dental School'));
      expect(profile.academicYear, equals('5th Year'));

      await notifier.updateProfile(
        name: 'Dr. Jane Smith',
        university: 'Oxford',
        academicYear: 'Intern',
      );

      final updatedProfile = notifier.state.value;
      expect(updatedProfile!.name, equals('Dr. Jane Smith'));
      expect(updatedProfile.university, equals('Oxford'));
      expect(updatedProfile.academicYear, equals('Intern'));

      expect(await repository.getDoctorName(), equals('Dr. Jane Smith'));
    });
  });
}
