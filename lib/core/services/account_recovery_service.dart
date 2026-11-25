import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/database/app_database.dart';
import '../../data/database/database_providers.dart';
import '../../data/repositories/preferences_repository.dart';
import '../logging/app_logger.dart';
import 'database_backup_service.dart';

/// Immutable snapshot of recoverable offline clinician account data discovered on launch
/// after an app reinstall where Android backup preserved user data without the
/// installation-local sentinel marker.
class AccountRecoveryCandidate {
  const AccountRecoveryCandidate({
    required this.firstName,
    required this.lastName,
    required this.university,
    required this.academicYear,
    this.legacyName,
    this.fromSharedPreferences = false,
    this.fromRecoveryMetadata = false,
    this.hasClinicalDatabaseRecords = false,
  });

  final String firstName;
  final String lastName;
  final String university;
  final String academicYear;
  final String? legacyName;
  final bool fromSharedPreferences;
  final bool fromRecoveryMetadata;
  final bool hasClinicalDatabaseRecords;

  /// Builds a [UserProfile] representation for locale-aware formatted display names.
  UserProfile toUserProfile() {
    return UserProfile(
      firstName: firstName.trim().isNotEmpty ? firstName.trim() : 'Doctor',
      lastName: lastName.trim(),
      name: legacyName,
      university: university.trim().isNotEmpty ? university.trim() : 'Dental School',
      academicYear: academicYear.trim().isNotEmpty ? academicYear.trim() : '5th Year',
      isGuest: false,
    );
  }

  /// Returns `"Dr. [First] [Last]"` (or Arabic equivalent `"د. [First] [Last]"`).
  String formattedDoctorName([String? locale]) {
    return toUserProfile().formattedFullDoctorName(locale);
  }
}

/// Offline service managing install verification markers, account recovery metadata,
/// reinstall data detection, and clean reset/continuation flows.
///
/// **Offline Architecture & Install Marker Mechanism:**
/// - Android Auto Backup (`backup_rules.xml` & `data_extraction_rules.xml`) backs up
///   the SQLite database (`dentera.db`), `SharedPreferences`, and `dentera_recovery_meta.json`,
///   while intentionally excluding [installMarkerFileName] (`dentera_install_verified`).
/// - On normal launches after onboarding on the same installation, `dentera_install_verified`
///   exists locally, so startup proceeds directly without any recovery prompt.
/// - After an uninstall + reinstall where data survived via OS backup, the install marker is
///   missing (`!hasInstallMarker()`). If `!wasExplicitlyReset()` and non-guest profile or
///   clinical DB records are present, [detectRecoverableAccount] surfaces an
///   [AccountRecoveryCandidate] so the clinician can choose to continue or start fresh.
/// - If the user explicitly reset the app before uninstalling (`wasExplicitlyReset == true`),
///   recovery metadata is cleared and [detectRecoverableAccount] returns `null` (Scenario B),
///   routing straight to a fresh onboarding screen with zero leftover data.
class AccountRecoveryService {
  AccountRecoveryService({
    required this.preferencesRepository,
    required this.appDatabase,
    this.ref,
    this.onResetAllData,
    Future<Directory> Function()? getDocumentsDirectoryFn,
    Future<Directory> Function()? getSupportDirectoryFn,
  })  : _customDocumentsDirectoryFn = getDocumentsDirectoryFn,
        _customSupportDirectoryFn = getSupportDirectoryFn;

  final PreferencesRepository preferencesRepository;
  final AppDatabase appDatabase;
  final Ref? ref;
  final Future<void> Function()? onResetAllData;
  final Future<Directory> Function()? _customDocumentsDirectoryFn;
  final Future<Directory> Function()? _customSupportDirectoryFn;

  bool get _isFlutterTest =>
      Platform.environment.containsKey('FLUTTER_TEST') ||
      Platform.executable.contains('flutter_tester');

  /// Name of the JSON file persisted inside app documents holding non-guest clinician metadata.
  static const String recoveryMetadataFileName = 'dentera_recovery_meta.json';

  /// Name of the installation-local sentinel excluded from Android Auto Backup.
  static const String installMarkerFileName = 'dentera_install_verified';

  Future<Directory?> _resolveDocumentsDir() async {
    if (_customDocumentsDirectoryFn != null) {
      try {
        return await _customDocumentsDirectoryFn();
      } catch (e) {
        AppLogger.debug('[AccountRecoveryService] Custom documents directory unavailable: $e');
        return null;
      }
    }
    if (_isFlutterTest) {
      return null;
    }
    try {
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      AppLogger.debug('[AccountRecoveryService] Documents directory unavailable: $e');
      return null;
    }
  }

  Future<Directory?> _resolveSupportDir() async {
    if (_customSupportDirectoryFn != null) {
      try {
        return await _customSupportDirectoryFn();
      } catch (e) {
        AppLogger.debug('[AccountRecoveryService] Custom support directory unavailable: $e');
        return null;
      }
    }
    if (_isFlutterTest) {
      return null;
    }
    try {
      return await getApplicationSupportDirectory();
    } catch (e) {
      AppLogger.debug('[AccountRecoveryService] Support directory unavailable: $e');
      return null;
    }
  }

  /// Writes the local installation sentinel so normal restarts do not trigger recovery prompts.
  Future<void> markInstallVerified() async {
    final supportDir = await _resolveSupportDir();
    if (supportDir == null) return;

    try {
      if (!supportDir.existsSync()) {
        supportDir.createSync(recursive: true);
      }
      final markerFile = File(p.join(supportDir.path, installMarkerFileName));
      markerFile.writeAsStringSync(
        jsonEncode(<String, dynamic>{
          'verified': true,
          'verifiedAt': DateTime.now().toIso8601String(),
        }),
        flush: true,
      );
      AppLogger.debug('[AccountRecoveryService] Install marker verified at ${markerFile.path}');
    } catch (e, st) {
      AppLogger.error('[AccountRecoveryService] Failed writing install marker: $e', e, st);
    }
  }

  /// Returns `true` when the installation-local sentinel file exists on disk.
  Future<bool> hasInstallMarker() async {
    final supportDir = await _resolveSupportDir();
    if (supportDir == null) return false;

    try {
      final markerFile = File(p.join(supportDir.path, installMarkerFileName));
      return markerFile.existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Persists non-guest clinician profile metadata to [recoveryMetadataFileName] and marks
  /// this installation as verified.
  ///
  /// For Guest profiles (`isGuest == true`), removes any stale recovery metadata file so
  /// sample guest sessions never prompt as personal accounts after reinstall.
  Future<void> writeRecoverySnapshotAndInstallMarker(UserProfile profile) async {
    await markInstallVerified();

    final docsDir = await _resolveDocumentsDir();
    if (docsDir == null) return;

    final metaFile = File(p.join(docsDir.path, recoveryMetadataFileName));
    if (profile.isGuest) {
      try {
        if (metaFile.existsSync()) {
          metaFile.deleteSync();
        }
      } catch (e) {
        AppLogger.debug('[AccountRecoveryService] Could not remove guest metadata file: $e');
      }
      return;
    }

    try {
      if (!docsDir.existsSync()) {
        docsDir.createSync(recursive: true);
      }
      metaFile.writeAsStringSync(
        jsonEncode(<String, dynamic>{
          'firstName': profile.firstName.trim(),
          'lastName': profile.lastName.trim(),
          'university': profile.university.trim(),
          'academicYear': profile.academicYear.trim(),
          'isGuest': false,
          'updatedAt': DateTime.now().toIso8601String(),
        }),
        flush: true,
      );
      AppLogger.info('[AccountRecoveryService] Recovery snapshot persisted for ${profile.formattedFullDoctorName()}');
    } catch (e, st) {
      AppLogger.error('[AccountRecoveryService] Failed persisting recovery snapshot: $e', e, st);
    }
  }

  /// Deletes both [recoveryMetadataFileName] and [installMarkerFileName] during a full reset.
  Future<void> clearAllRecoveryArtifacts() async {
    final docsDir = await _resolveDocumentsDir();
    if (docsDir != null) {
      try {
        final metaFile = File(p.join(docsDir.path, recoveryMetadataFileName));
        if (metaFile.existsSync()) {
          metaFile.deleteSync();
        }
      } catch (e) {
        AppLogger.debug('[AccountRecoveryService] Failed deleting recovery metadata file: $e');
      }
    }

    final supportDir = await _resolveSupportDir();
    if (supportDir != null) {
      try {
        final markerFile = File(p.join(supportDir.path, installMarkerFileName));
        if (markerFile.existsSync()) {
          markerFile.deleteSync();
        }
      } catch (e) {
        AppLogger.debug('[AccountRecoveryService] Failed deleting install marker file: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> _readRecoveryMetadata() async {
    final docsDir = await _resolveDocumentsDir();
    if (docsDir == null) return null;

    try {
      final metaFile = File(p.join(docsDir.path, recoveryMetadataFileName));
      if (!metaFile.existsSync()) return null;

      final raw = metaFile.readAsStringSync();
      if (raw.trim().isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (e) {
      AppLogger.debug('[AccountRecoveryService] Failed reading recovery metadata: $e');
      return null;
    }
  }

  Future<bool> _hasExistingClinicalDatabaseRecords() async {
    if (_isFlutterTest && _customDocumentsDirectoryFn == null) {
      return false;
    }
    try {
      final dbPath = await appDatabase.getDatabasePath();
      final dbFile = File(dbPath);
      if (!dbFile.existsSync()) return false;
      final size = dbFile.lengthSync();
      if (size <= 0) return false;

      final db = await appDatabase.database;
      final patientsCount =
          ((await db.rawQuery('SELECT COUNT(*) AS cnt FROM patients;')).first['cnt'] as int?) ?? 0;
      if (patientsCount > 0) return true;

      final casesCount =
          ((await db.rawQuery('SELECT COUNT(*) AS cnt FROM case_records;')).first['cnt'] as int?) ?? 0;
      if (casesCount > 0) return true;

      final appointmentsCount =
          ((await db.rawQuery('SELECT COUNT(*) AS cnt FROM appointments;')).first['cnt'] as int?) ?? 0;
      return appointmentsCount > 0;
    } catch (e) {
      AppLogger.debug('[AccountRecoveryService] Skipping DB clinical check on startup: $e');
      return false;
    }
  }

  /// Inspects preferences, backed-up metadata, and an existing SQLite database file to detect
  /// non-guest clinician data left behind by an uninstall without explicit reset.
  ///
  /// Returns `null` when:
  /// - The user explicitly reset the app before uninstalling (`wasExplicitlyReset == true`),
  /// - The current installation already has its local [installMarkerFileName] sentinel, or
  /// - No non-guest profile or clinical database records exist (true fresh install).
  Future<AccountRecoveryCandidate?> detectRecoverableAccount() async {
    final explicitlyReset = await preferencesRepository.wasExplicitlyReset();
    if (explicitlyReset) {
      AppLogger.info('[AccountRecoveryService] wasExplicitlyReset is true — bypassing account recovery (Scenario B).');
      return null;
    }

    final installVerified = await hasInstallMarker();
    if (installVerified) {
      return null;
    }

    final hasOnboarding = await preferencesRepository.hasCompletedOnboarding();
    final isGuestPref = await preferencesRepository.isGuest();
    if (hasOnboarding && isGuestPref) {
      AppLogger.debug('[AccountRecoveryService] Ignoring Guest Mode data during reinstall check.');
      return null;
    }

    final prefFirst = (await preferencesRepository.getDoctorFirstName())?.trim() ?? '';
    final prefLast = (await preferencesRepository.getDoctorLastName())?.trim() ?? '';
    final prefLegacy = (await preferencesRepository.getDoctorName())?.trim();
    final prefUniversity = (await preferencesRepository.getUniversity())?.trim() ?? '';
    final prefYear = (await preferencesRepository.getAcademicYear())?.trim() ?? '';

    final hasPrefProfile = hasOnboarding &&
        !isGuestPref &&
        (prefFirst.isNotEmpty || prefLast.isNotEmpty || (prefLegacy != null && prefLegacy.isNotEmpty));

    final meta = await _readRecoveryMetadata();
    final metaIsGuest = meta != null && meta['isGuest'] == true;
    final metaFirst = meta != null ? (meta['firstName'] as String?)?.trim() ?? '' : '';
    final metaLast = meta != null ? (meta['lastName'] as String?)?.trim() ?? '' : '';
    final metaUniversity = meta != null ? (meta['university'] as String?)?.trim() ?? '' : '';
    final metaYear = meta != null ? (meta['academicYear'] as String?)?.trim() ?? '' : '';
    final hasMetaProfile = meta != null && !metaIsGuest && (metaFirst.isNotEmpty || metaLast.isNotEmpty);

    if (metaIsGuest && !hasPrefProfile) {
      return null;
    }

    final hasDbRecords = await _hasExistingClinicalDatabaseRecords();

    if (!hasPrefProfile && !hasMetaProfile && !hasDbRecords) {
      return null;
    }

    final resolvedFirst = hasPrefProfile
        ? prefFirst
        : (hasMetaProfile ? metaFirst : 'Doctor');
    final resolvedLast = hasPrefProfile
        ? prefLast
        : (hasMetaProfile ? metaLast : '');
    final resolvedUniversity = prefUniversity.isNotEmpty
        ? prefUniversity
        : (metaUniversity.isNotEmpty ? metaUniversity : 'Dental School');
    final resolvedYear = prefYear.isNotEmpty
        ? prefYear
        : (metaYear.isNotEmpty ? metaYear : '5th Year');

    final candidate = AccountRecoveryCandidate(
      firstName: resolvedFirst,
      lastName: resolvedLast,
      university: resolvedUniversity,
      academicYear: resolvedYear,
      legacyName: prefLegacy,
      fromSharedPreferences: hasPrefProfile,
      fromRecoveryMetadata: hasMetaProfile,
      hasClinicalDatabaseRecords: hasDbRecords,
    );

    AppLogger.info(
      '[AccountRecoveryService] Detected recoverable clinician account: '
      '${candidate.formattedDoctorName()} (${candidate.academicYear})',
    );
    return candidate;
  }

  /// Restores/confirms [candidate] as the active non-guest clinician, marks this install
  /// verified, refreshes profile & domain providers, and prepares entry to [RootNavigationScreen].
  Future<void> continueWithRecoveredAccount(AccountRecoveryCandidate candidate) async {
    AppLogger.info(
      '[AccountRecoveryService] Continuing with recovered account: ${candidate.formattedDoctorName()}',
    );
    await preferencesRepository.saveUserProfile(
      firstName: candidate.firstName,
      lastName: candidate.lastName,
      university: candidate.university,
      academicYear: candidate.academicYear,
      isGuest: false,
    );

    await writeRecoverySnapshotAndInstallMarker(candidate.toUserProfile());

    final activeRef = ref;
    if (activeRef != null) {
      if (activeRef.exists(userProfileProvider)) {
        await activeRef.read(userProfileProvider.notifier).loadProfile();
      }
      activeRef.read(databaseBackupServiceProvider).invalidateRiverpodState();
    }
  }

  /// Discards any recovered account state by running a complete database/preference/file wipe,
  /// ensuring a pristine onboarding flow for a new clinician account.
  Future<void> discardAndStartFresh() async {
    AppLogger.warning('[AccountRecoveryService] User selected Start New Account — wiping previous data cleanly.');
    final resetFn = onResetAllData;
    if (resetFn != null) {
      await resetFn();
    } else if (ref != null) {
      await ref!.read(databaseBackupServiceProvider).resetAllData(
            preferencesRepository: preferencesRepository,
          );
    } else {
      await appDatabase.resetAllData(preferencesRepository: preferencesRepository);
      await clearAllRecoveryArtifacts();
    }

    // Explicitly reinforce reset markers so onboarding launches with a blank slate.
    await preferencesRepository.setWasExplicitlyReset(true);

    final activeRef = ref;
    if (activeRef != null) {
      if (activeRef.exists(onboardingStatusProvider)) {
        activeRef.invalidate(onboardingStatusProvider);
      }
      if (activeRef.exists(startupRecoveryCandidateProvider)) {
        activeRef.invalidate(startupRecoveryCandidateProvider);
      }
    }
  }
}

/// Riverpod provider exposing [AccountRecoveryService].
final accountRecoveryServiceProvider = Provider<AccountRecoveryService>((ref) {
  return AccountRecoveryService(
    preferencesRepository: ref.read(preferencesRepositoryProvider),
    appDatabase: ref.read(appDatabaseProvider),
    ref: ref,
  );
});

/// Startup recovery check evaluated before routing to [OnboardingScreen].
///
/// Only triggers when `onboardingStatusProvider` is `false` (or when an installation sentinel
/// is missing after OS backup restore). Returns `null` for fresh installs, verified installs,
/// and post-reset relaunches.
final startupRecoveryCandidateProvider = FutureProvider<AccountRecoveryCandidate?>((ref) async {
  final service = ref.read(accountRecoveryServiceProvider);
  return await service.detectRecoverableAccount();
});
