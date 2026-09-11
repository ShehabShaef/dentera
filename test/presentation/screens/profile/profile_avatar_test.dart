import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentera/core/theme/theme.dart';
import 'package:dentera/data/repositories/preferences_repository.dart';
import 'package:dentera/presentation/screens/dashboard/widgets/dashboard_header.dart';
import 'package:dentera/presentation/screens/profile/widgets/edit_profile_modal.dart';
import 'package:dentera/presentation/screens/profile/widgets/profile_header_card.dart';
import 'package:dentera/presentation/widgets/modals/avatar_picker_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesRepository mockPrefsRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockPrefsRepo = PreferencesRepository();
  });

  Widget buildTestableApp({
    required Widget child,
    List<dynamic> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(mockPrefsRepo),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: child),
      ),
    );
  }

  group('User Profile Avatar Widget & Flow Tests (Issue #20)', () {
    testWidgets('DashboardHeader renders initials when no avatar is set', (tester) async {
      await tester.pumpWidget(
        buildTestableApp(
          child: const DashboardHeader(
            doctorName: 'Dr. Shehab Shaif',
            academicYear: '5th Year',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SS'), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsNothing);
    });

    testWidgets('DashboardHeader renders avatar widget when avatar path is present', (tester) async {
      final notifier = AvatarNotifier(mockPrefsRepo);
      await notifier.setAvatarPath('/mock/profile_avatar.jpg');

      await tester.pumpWidget(
        buildTestableApp(
          overrides: [
            avatarProvider.overrideWith((ref) => notifier),
          ],
          child: const DashboardHeader(
            doctorName: 'Dr. Shehab Shaif',
            academicYear: '5th Year',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      expect(find.text('SS'), findsNothing);
    });

    testWidgets('ProfileHeaderCard displays initials and camera badge when no avatar is set', (tester) async {
      await tester.pumpWidget(
        buildTestableApp(
          child: const ProfileHeaderCard(
            name: 'Dr. Sarah Smith',
            subtitle: 'Dental School • 4th Year',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('S'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    });

    testWidgets('ProfileHeaderCard displays avatar when set and tapping opens AvatarPickerModal', (tester) async {
      final notifier = AvatarNotifier(mockPrefsRepo);
      await notifier.setAvatarPath('/mock/profile_avatar.jpg');

      await tester.pumpWidget(
        buildTestableApp(
          overrides: [
            avatarProvider.overrideWith((ref) => notifier),
          ],
          child: const ProfileHeaderCard(
            name: 'Dr. Sarah Smith',
            subtitle: 'Dental School • 4th Year',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);

      // Tap on avatar area
      await tester.tap(find.byIcon(Icons.camera_alt_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(AvatarPickerModal), findsOneWidget);
      expect(find.text('Profile Photo'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Remove Photo'), findsOneWidget);
    });

    testWidgets('AvatarPickerModal hides Remove Photo when no avatar is active', (tester) async {
      await tester.pumpWidget(
        buildTestableApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AvatarPickerModal.show(context),
              child: const Text('Open Picker'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.byType(AvatarPickerModal), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Remove Photo'), findsNothing);
    });

    testWidgets('AvatarPickerModal Remove Photo removes avatar and closes modal', (tester) async {
      final notifier = AvatarNotifier(mockPrefsRepo);
      await notifier.setAvatarPath('/mock/profile_avatar.jpg');

      await tester.pumpWidget(
        buildTestableApp(
          overrides: [
            avatarProvider.overrideWith((ref) => notifier),
          ],
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AvatarPickerModal.show(context),
              child: const Text('Open Picker'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Remove Photo'), findsOneWidget);
      await tester.tap(find.text('Remove Photo'));
      await tester.pumpAndSettle();

      expect(find.byType(AvatarPickerModal), findsNothing);
      expect(notifier.state, isNull);
      expect(await mockPrefsRepo.getAvatarPath(), isNull);
    });

    testWidgets('EditProfileModal displays avatar preview with Change Photo button and opens picker', (tester) async {
      await tester.pumpWidget(
        buildTestableApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => EditProfileModal.show(context),
              child: const Text('Open Edit'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Edit'));
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileModal), findsOneWidget);
      expect(find.text('Change Photo'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);

      await tester.tap(find.text('Change Photo'));
      await tester.pumpAndSettle();

      expect(find.byType(AvatarPickerModal), findsOneWidget);
    });
  });
}
