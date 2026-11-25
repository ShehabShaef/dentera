import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/core/services/account_recovery_service.dart';
import 'package:dentera/core/services/database_backup_service.dart';
import 'package:dentera/core/services/local_notification_service.dart';
import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/database/app_database.dart';
import 'package:dentera/data/database/database_providers.dart';
import 'package:dentera/data/repositories/preferences_repository.dart';
import 'package:dentera/domain/entities/entities.dart';
import 'package:dentera/l10n/l10n.dart';
import 'package:dentera/main.dart';
import 'package:dentera/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:dentera/presentation/screens/profile/profile_screen.dart';
import 'package:dentera/presentation/screens/root_navigation_screen.dart';
import 'package:dentera/presentation/state/state.dart';
import 'package:dentera/presentation/widgets/modals/modals.dart';

import '../../setup/test_setup.dart';

class _SpyNotificationService extends LocalNotificationService {
  _SpyNotificationService();

  int cancelAllCount = 0;

  @override
  Future<void> cancelAllReminders() async {
    cancelAllCount += 1;
  }
}

class _InMemoryFakeAppDatabase implements AppDatabase {
  int resetCallCount = 0;

  @override
  Future<String> getDatabasePath() async => 'non_existent_widget_test_dentera.db';

  @override
  Future<void> resetAllData({PreferencesRepository? preferencesRepository}) async {
    resetCallCount += 1;
    final prefsRepo = preferencesRepository ?? PreferencesRepository();
    await prefsRepo.clearAll(markExplicitReset: true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Issue #68: Account Recovery & Real SQLite Repeatable Reset (FFI)', () {
    late Directory docsDir;
    late Directory supportDir;

    setUpAll(() {
      setupDatabaseTests();
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      docsDir = Directory.systemTemp.createTempSync('dentera_recovery_docs_');
      supportDir = Directory.systemTemp.createTempSync('dentera_recovery_support_');
    });

    tearDown(() async {
      await AppDatabase.instance.close();
      if (docsDir.existsSync()) docsDir.deleteSync(recursive: true);
      if (supportDir.existsSync()) supportDir.deleteSync(recursive: true);
    });

    test('Scenario B: explicit reset before uninstall leaves 0 SQLite rows, clears artifacts, and suppresses recovery prompt', () async {
      final db = await AppDatabase.instance.database;
      final prefsRepo = PreferencesRepository();
      final spyNotif = _SpyNotificationService();

      final container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(spyNotif),
          accountRecoveryServiceProvider.overrideWith((ref) {
            return AccountRecoveryService(
              preferencesRepository: prefsRepo,
              appDatabase: AppDatabase.instance,
              ref: ref,
              getDocumentsDirectoryFn: () async => docsDir,
              getSupportDirectoryFn: () async => supportDir,
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      // 1. Seed a Real User with profile, baseline clinics/requirements, and clinical patient data.
      const profile = UserProfile(
        firstName: 'Ahmed',
        lastName: 'Hassan',
        university: 'Cairo University',
        academicYear: '5th Year',
        isGuest: false,
      );
      await prefsRepo.saveUserProfile(
        firstName: profile.firstName,
        lastName: profile.lastName,
        university: profile.university,
        academicYear: profile.academicYear,
        isGuest: false,
      );
      await container.read(onboardingSeederProvider)(isGuest: false, academicYear: '5th Year');
      await container.read(accountRecoveryServiceProvider).writeRecoverySnapshotAndInstallMarker(profile);

      await db.insert('patients', {
        'id': 'pat-1',
        'name': 'Mona Ali',
        'age': 28,
        'gender': 'Female',
        'createdAt': DateTime.now().toIso8601String(),
      });

      expect(File(p.join(docsDir.path, AccountRecoveryService.recoveryMetadataFileName)).existsSync(), isTrue);
      expect(File(p.join(supportDir.path, AccountRecoveryService.installMarkerFileName)).existsSync(), isTrue);
      expect(await prefsRepo.wasExplicitlyReset(), isFalse);

      // 2. Execute full app reset before uninstall.
      await container.read(databaseBackupServiceProvider).resetAllData();

      expect(spyNotif.cancelAllCount, equals(1));
      expect(await prefsRepo.hasCompletedOnboarding(), isFalse);
      expect(await prefsRepo.wasExplicitlyReset(), isTrue);
      expect(File(p.join(docsDir.path, AccountRecoveryService.recoveryMetadataFileName)).existsSync(), isFalse);
      expect(File(p.join(supportDir.path, AccountRecoveryService.installMarkerFileName)).existsSync(), isFalse);

      for (final table in const [
        'patients',
        'clinics',
        'requirements',
        'case_records',
        'appointments',
        'case_visits',
        'treatment_plans',
        'patient_radiographs',
      ]) {
        final rows = await db.query(table);
        expect(rows, isEmpty, reason: 'Table $table must be empty after reset');
      }

      // 3. Simulate uninstall + reinstall (install marker missing, wasExplicitlyReset persisted).
      final freshRecoveryService = AccountRecoveryService(
        preferencesRepository: prefsRepo,
        appDatabase: AppDatabase.instance,
        getDocumentsDirectoryFn: () async => docsDir,
        getSupportDirectoryFn: () async => supportDir,
      );
      final candidate = await freshRecoveryService.detectRecoverableAccount();
      expect(candidate, isNull);
    });

    test('Scenario A: uninstall without reset preserves backed-up data and surfaces recovery candidate for Continue or Start New', () async {
      final db = await AppDatabase.instance.database;
      final prefsRepo = PreferencesRepository();
      final spyNotif = _SpyNotificationService();

      final container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(spyNotif),
          accountRecoveryServiceProvider.overrideWith((ref) {
            return AccountRecoveryService(
              preferencesRepository: prefsRepo,
              appDatabase: AppDatabase.instance,
              ref: ref,
              getDocumentsDirectoryFn: () async => docsDir,
              getSupportDirectoryFn: () async => supportDir,
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      // Setup user + patient data
      const profile = UserProfile(
        firstName: 'Layla',
        lastName: 'Mansour',
        university: 'Alexandria University',
        academicYear: '4th Year',
        isGuest: false,
      );
      await prefsRepo.saveUserProfile(
        firstName: profile.firstName,
        lastName: profile.lastName,
        university: profile.university,
        academicYear: profile.academicYear,
        isGuest: false,
      );
      await container.read(onboardingSeederProvider)(isGuest: false, academicYear: '4th Year');
      await container.read(accountRecoveryServiceProvider).writeRecoverySnapshotAndInstallMarker(profile);

      await db.insert('patients', {
        'id': 'pat-keep',
        'name': 'Tariq Nabil',
        'age': 34,
        'gender': 'Male',
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Normal launch on same install must NOT show recovery prompt (install marker exists).
      final normalLaunchCandidate = await container.read(accountRecoveryServiceProvider).detectRecoverableAccount();
      expect(normalLaunchCandidate, isNull);

      // Simulate uninstall + reinstall: remove ONLY install marker (excluded from backup),
      // keep backed-up prefs, recovery metadata, and SQLite records.
      final markerFile = File(p.join(supportDir.path, AccountRecoveryService.installMarkerFileName));
      await markerFile.delete();

      final candidateA1 = await container.read(accountRecoveryServiceProvider).detectRecoverableAccount();
      expect(candidateA1, isNotNull);
      expect(candidateA1!.formattedDoctorName('en'), equals('Dr. Layla Mansour'));
      expect(candidateA1.academicYear, equals('4th Year'));

      // Even if SharedPreferences were cleared on reinstall and only recovery metadata + DB survived, recovery still detects user!
      await prefsRepo.clearAll(markExplicitReset: false);
      final candidateA2 = await container.read(accountRecoveryServiceProvider).detectRecoverableAccount();
      expect(candidateA2, isNotNull);
      expect(candidateA2!.formattedDoctorName('en'), equals('Dr. Layla Mansour'));
      expect(candidateA2.academicYear, equals('4th Year'));

      // Option 1: Continue with Existing Data -> restores prefs + marker, keeps DB patients intact.
      await container.read(accountRecoveryServiceProvider).continueWithRecoveredAccount(candidateA2);
      expect(await prefsRepo.hasCompletedOnboarding(), isTrue);
      expect(await prefsRepo.wasExplicitlyReset(), isFalse);
      expect(await container.read(accountRecoveryServiceProvider).hasInstallMarker(), isTrue);
      expect((await db.query('patients')).length, equals(1));
      // Subsequent launch skips recovery prompt cleanly
      expect(await container.read(accountRecoveryServiceProvider).detectRecoverableAccount(), isNull);

      // Simulate another reinstall -> Option 2: Start New Account -> wipes DB & sets wasExplicitlyReset
      await markerFile.delete();
      final candidateA3 = await container.read(accountRecoveryServiceProvider).detectRecoverableAccount();
      expect(candidateA3, isNotNull);

      await container.read(accountRecoveryServiceProvider).discardAndStartFresh();
      expect((await db.query('patients')), isEmpty);
      expect(await prefsRepo.hasCompletedOnboarding(), isFalse);
      expect(await prefsRepo.wasExplicitlyReset(), isTrue);
      expect(await container.read(accountRecoveryServiceProvider).detectRecoverableAccount(), isNull);
    });

    test('Guest Mode sessions do not trigger personal account recovery on reinstall', () async {
      final prefsRepo = PreferencesRepository();
      final service = AccountRecoveryService(
        preferencesRepository: prefsRepo,
        appDatabase: AppDatabase.instance,
        getDocumentsDirectoryFn: () async => docsDir,
        getSupportDirectoryFn: () async => supportDir,
      );

      await prefsRepo.saveUserProfile(
        firstName: 'Guest',
        lastName: '',
        university: 'Guest Dental University',
        academicYear: '5th Year',
        isGuest: true,
      );
      await service.writeRecoverySnapshotAndInstallMarker(
        const UserProfile(
          firstName: 'Guest',
          lastName: '',
          university: 'Guest Dental University',
          academicYear: '5th Year',
          isGuest: true,
        ),
      );

      // Even if install marker disappears after reinstall, Guest session is ignored.
      final marker = File(p.join(supportDir.path, AccountRecoveryService.installMarkerFileName));
      if (marker.existsSync()) marker.deleteSync();
      expect(await service.detectRecoverableAccount(), isNull);
    });

    test('DatabaseBackupService.resetAllData resets navigation, UI filter states, and invalidates userProfileProvider', () async {
      await AppDatabase.instance.database;
      final spyNotif = _SpyNotificationService();
      final container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(spyNotif),
          accountRecoveryServiceProvider.overrideWith((ref) {
            return AccountRecoveryService(
              preferencesRepository: PreferencesRepository(),
              appDatabase: AppDatabase.instance,
              ref: ref,
              getDocumentsDirectoryFn: () async => docsDir,
              getSupportDirectoryFn: () async => supportDir,
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      // Dirty UI state across tabs & filters
      container.read(rootNavigationIndexProvider.notifier).state = 4;
      container.read(patientSearchQueryProvider.notifier).state = 'Omar';
      container.read(patientFilterCategoryProvider.notifier).state = 'Endodontics';
      container.read(selectedClinicCategoryProvider.notifier).state = 'Surgical';

      await container.read(databaseBackupServiceProvider).resetAllData();

      expect(spyNotif.cancelAllCount, equals(1));
      expect(container.read(rootNavigationIndexProvider), equals(0));
      expect(container.read(patientSearchQueryProvider), isEmpty);
      expect(container.read(patientFilterCategoryProvider), equals('All'));
      expect(container.read(selectedClinicCategoryProvider), equals('All'));
    });

    test('Consecutive SQLite FFI reset cycles (1st, 2nd, 3rd) leave zero ghost data across rebuilds', () async {
      final db = await AppDatabase.instance.database;
      final prefsRepo = PreferencesRepository();
      final spyNotif = _SpyNotificationService();

      final container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(spyNotif),
          accountRecoveryServiceProvider.overrideWith((ref) {
            return AccountRecoveryService(
              preferencesRepository: prefsRepo,
              appDatabase: AppDatabase.instance,
              ref: ref,
              getDocumentsDirectoryFn: () async => docsDir,
              getSupportDirectoryFn: () async => supportDir,
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      for (int cycle = 1; cycle <= 3; cycle++) {
        // Complete onboarding (alternate Guest -> Real -> Guest to verify no ghost preset leaks)
        final isGuest = cycle == 1;
        await prefsRepo.saveUserProfile(
          firstName: isGuest ? 'Guest' : 'Nadia$cycle',
          lastName: isGuest ? '' : 'Salem',
          university: 'Dentera Dental College',
          academicYear: '5th Year',
          isGuest: isGuest,
        );
        await container.read(onboardingSeederProvider)(
          isGuest: isGuest,
          academicYear: '5th Year',
        );

        if (!isGuest) {
          // Real user must start with 0 patients/cases/appointments — zero ghost preset data from cycle 1!
          expect((await db.query('patients')), isEmpty);
          expect((await db.query('case_records')), isEmpty);
          expect((await db.query('appointments')), isEmpty);
        } else {
          expect((await db.query('patients')), isNotEmpty);
        }

        await container.read(databaseBackupServiceProvider).resetAllData();

        expect(spyNotif.cancelAllCount, equals(cycle));
        expect(await prefsRepo.hasCompletedOnboarding(), isFalse);
        expect(await prefsRepo.wasExplicitlyReset(), isTrue);
        expect((await db.query('patients')), isEmpty);
        expect((await db.query('clinics')), isEmpty);
        expect((await db.query('requirements')), isEmpty);
      }
    });
  });

  group('Issue #68: Repeatable UI Reset Flow, Redesigned Button, and Recovery UI Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    List<Override> buildUiTestOverrides({
      required _InMemoryFakeAppDatabase fakeDb,
      required _SpyNotificationService spyNotif,
      AccountRecoveryCandidate? initialRecoveryCandidate,
      VoidCallback? onContinueCalled,
      VoidCallback? onDiscardCalled,
    }) {
      return [
        appDatabaseProvider.overrideWithValue(fakeDb),
        notificationServiceProvider.overrideWithValue(spyNotif),
        onboardingSeederProvider.overrideWithValue(({required isGuest, required academicYear}) async {}),
        dailyAppointmentsProvider.overrideWith((ref, date) => <Appointment>[]),
        upcomingAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
        patientListProvider.overrideWith((ref) => <Patient>[]),
        allCasesProvider.overrideWith((ref) => <CaseRecord>[]),
        allRequirementsProvider.overrideWith((ref) => <Requirement>[]),
        clinicListProvider.overrideWith((ref) => <Clinic>[]),
        allAppointmentsProvider.overrideWith((ref) => <Appointment>[]),
        startupRecoveryCandidateProvider.overrideWith((ref) async => initialRecoveryCandidate),
        if (onContinueCalled != null || onDiscardCalled != null)
          accountRecoveryServiceProvider.overrideWith((ref) {
            return _StubAccountRecoveryService(
              preferencesRepository: PreferencesRepository(),
              appDatabase: fakeDb,
              ref: ref,
              onContinue: onContinueCalled,
              onDiscard: onDiscardCalled,
            );
          }),
      ];
    }

    Future<void> completeGuestOnboardingFromOnboardingScreen(WidgetTester tester) async {
      expect(find.byType(OnboardingScreen), findsOneWidget);
      final guestBtn = find.widgetWithText(TextButton, 'Continue as a guest');
      await tester.ensureVisible(guestBtn);
      await tester.tap(guestBtn);
      await tester.pumpAndSettle();
      expect(find.byType(RootNavigationScreen), findsOneWidget);
    }

    Future<void> openProfileAndConfirmReset(WidgetTester tester) async {
      // Navigate to Profile tab using bottom navigation Profile label/icon
      final profileTab = find.text('Profile');
      await tester.tap(profileTab.last);
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);

      final resetBtn = find.byKey(const Key('profile_reset_button'));
      await tester.ensureVisible(resetBtn);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      expect(find.text('Danger Zone'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).last, 'RESET');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wipe All Data'));
      await tester.pumpAndSettle();
    }

    testWidgets('Reset All Clinical Data works repeatedly across 3 consecutive full Onboarding -> Profile -> Reset cycles', (WidgetTester tester) async {
      final fakeDb = _InMemoryFakeAppDatabase();
      final spyNotif = _SpyNotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: buildUiTestOverrides(fakeDb: fakeDb, spyNotif: spyNotif),
          child: const DenteraApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Cycle 1: Onboarding -> Profile -> 1st Reset -> returns cleanly to OnboardingScreen
      await completeGuestOnboardingFromOnboardingScreen(tester);
      await openProfileAndConfirmReset(tester);

      expect(fakeDb.resetCallCount, equals(1));
      expect(spyNotif.cancelAllCount, equals(1));
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(ProfileScreen), findsNothing);

      // Cycle 2 (after pushReplacement removed InitializationScreen): Onboarding -> Profile -> 2nd Reset -> returns to OnboardingScreen!
      await completeGuestOnboardingFromOnboardingScreen(tester);
      await openProfileAndConfirmReset(tester);

      expect(fakeDb.resetCallCount, equals(2));
      expect(spyNotif.cancelAllCount, equals(2));
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(ProfileScreen), findsNothing);

      // Cycle 3: Onboarding -> Profile -> 3rd Reset -> returns to OnboardingScreen cleanly!
      await completeGuestOnboardingFromOnboardingScreen(tester);
      await openProfileAndConfirmReset(tester);

      expect(fakeDb.resetCallCount, equals(3));
      expect(spyNotif.cancelAllCount, equals(3));
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(ProfileScreen), findsNothing);
    });

    testWidgets('Redesigned Profile reset button and DatabaseResetModal render sleekly in Light & Dark Mode', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'doctorFirstName': 'Tariq',
        'doctorLastName': 'Al-Harbi',
        'university': 'King Saud University',
        'academicYear': '5th Year',
        'hasCompletedOnboarding': true,
      });

      for (final theme in <ThemeData>[AppTheme.lightTheme, AppTheme.darkTheme]) {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: theme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              home: const ProfileScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final resetBtnFinder = find.byKey(const Key('profile_reset_button'));
        expect(resetBtnFinder, findsOneWidget);
        expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

        await tester.ensureVisible(resetBtnFinder);
        final rect = tester.getRect(resetBtnFinder);
        // Verify compact refined vertical dimensions
        expect(rect.height, lessThanOrEqualTo(48.0));

        await tester.tap(resetBtnFinder);
        await tester.pumpAndSettle();

        expect(find.text('Danger Zone'), findsOneWidget);
        expect(find.text('Wipe All Data'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Scenario A UI: AccountRecoveryScreen displays Dr. Name (Year) and Continue routes to workspace', (WidgetTester tester) async {
      final fakeDb = _InMemoryFakeAppDatabase();
      final spyNotif = _SpyNotificationService();
      bool continueTapped = false;

      const candidate = AccountRecoveryCandidate(
        firstName: 'Ahmed',
        lastName: 'Hassan',
        university: 'Cairo University',
        academicYear: '5th Year',
        fromSharedPreferences: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: buildUiTestOverrides(
            fakeDb: fakeDb,
            spyNotif: spyNotif,
            initialRecoveryCandidate: candidate,
            onContinueCalled: () => continueTapped = true,
          ),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const InitializationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccountRecoveryScreen), findsOneWidget);
      expect(
        find.text(
          'Found existing data for Dr. Ahmed Hassan (5th Year). Would you like to continue with your previous account or start a new account?',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('recovery_continue_button')));
      await tester.pumpAndSettle();

      expect(continueTapped, isTrue);
      expect(find.byType(RootNavigationScreen), findsOneWidget);
    });

    testWidgets('Scenario A UI: Start New Account action wipes data and routes cleanly to OnboardingScreen', (WidgetTester tester) async {
      final fakeDb = _InMemoryFakeAppDatabase();
      final spyNotif = _SpyNotificationService();
      bool startNewTapped = false;

      const candidate = AccountRecoveryCandidate(
        firstName: 'Ahmed',
        lastName: 'Hassan',
        university: 'Cairo University',
        academicYear: '5th Year',
        fromSharedPreferences: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: buildUiTestOverrides(
            fakeDb: fakeDb,
            spyNotif: spyNotif,
            initialRecoveryCandidate: candidate,
            onDiscardCalled: () => startNewTapped = true,
          ),
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const InitializationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccountRecoveryScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('recovery_start_fresh_button')));
      await tester.pumpAndSettle();

      expect(startNewTapped, isTrue);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('Scenario B UI: post-reset relaunch skips recovery prompt and opens OnboardingScreen directly', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'wasExplicitlyReset': true,
        'hasCompletedOnboarding': false,
      });

      final fakeDb = _InMemoryFakeAppDatabase();
      final spyNotif = _SpyNotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(fakeDb),
            notificationServiceProvider.overrideWithValue(spyNotif),
            accountRecoveryServiceProvider.overrideWith((ref) {
              return AccountRecoveryService(
                preferencesRepository: PreferencesRepository(),
                appDatabase: fakeDb,
                ref: ref,
              );
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const InitializationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccountRecoveryScreen), findsNothing);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('AccountRecoveryScreen renders Arabic RTL localized prompt cleanly', (WidgetTester tester) async {
      const candidate = AccountRecoveryCandidate(
        firstName: 'أحمد',
        lastName: 'حسن',
        university: 'جامعة القاهرة',
        academicYear: '5th Year',
        fromSharedPreferences: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ar'),
            home: const AccountRecoveryScreen(candidate: candidate),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تم العثور على حساب سابق'), findsOneWidget);
      expect(find.text('المتابعة بالبيانات الحالية'), findsOneWidget);
      expect(find.text('البدء بحساب جديد'), findsOneWidget);
      final dir = Directionality.of(tester.element(find.byType(AccountRecoveryScreen)));
      expect(dir, TextDirection.rtl);
    });
  });
}

class _StubAccountRecoveryService extends AccountRecoveryService {
  _StubAccountRecoveryService({
    required super.preferencesRepository,
    required super.appDatabase,
    super.ref,
    this.onContinue,
    this.onDiscard,
  });

  final VoidCallback? onContinue;
  final VoidCallback? onDiscard;

  @override
  Future<void> continueWithRecoveredAccount(AccountRecoveryCandidate candidate) async {
    onContinue?.call();
  }

  @override
  Future<void> discardAndStartFresh() async {
    onDiscard?.call();
  }
}
