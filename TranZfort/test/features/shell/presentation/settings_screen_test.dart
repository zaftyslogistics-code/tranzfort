import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/services/contextual_tts_service.dart';
import 'package:tranzfort/src/features/auth/data/auth_repository.dart';
import 'package:tranzfort/src/features/notifications/data/push_runtime_service.dart';
import 'package:tranzfort/src/features/shell/presentation/shell_destinations.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

class _FakeContextualTtsService extends ContextualTtsService {
  String? lastLanguageCode;
  String? lastMessage;

  _FakeContextualTtsService()
      : super(
          setLanguageFn: (_) async {},
          setSpeechRateFn: (_) async {},
          speakFn: (_) async {},
          stopFn: () async {},
          preferencesFn: SharedPreferences.getInstance,
        );

  @override
  Future<ContextualTtsOutcome> speakSummary({required String languageCode, required String message}) async {
    lastLanguageCode = languageCode;
    lastMessage = message;
    return ContextualTtsOutcome.spoken;
  }
}

Widget _buildApp(
  PushPermissionSnapshot snapshot, {
  _FakeContextualTtsService? ttsService,
  String roleType = 'supplier',
}) {
  final resolvedTtsService = ttsService ?? _FakeContextualTtsService();
  return ProviderScope(
    overrides: [
      currentProfileProvider.overrideWithValue(
        AsyncData<UserProfile?>(
          UserProfile(
            id: 'user-1',
            fullName: 'Test User',
            mobile: '9999999999',
            email: 'test@example.com',
            roleType: roleType,
            isBanned: false,
            accountDeletionStatus: 'active',
            trustSafetyStatus: 'normal',
          ),
        ),
      ),
      pushPermissionSnapshotProvider.overrideWith((ref) async => snapshot),
      contextualTtsServiceProvider.overrideWithValue(resolvedTtsService),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: SettingsScreen()),
          ),
          GoRoute(
            path: AppRoutes.profilePath,
            builder: (context, state) => const Scaffold(body: Text('Profile opened')),
          ),
          GoRoute(
            path: AppRoutes.notificationsPath,
            builder: (context, state) => const Scaffold(body: Text('Notifications opened')),
          ),
          GoRoute(
            path: AppRoutes.supportPath,
            builder: (context, state) => const Scaffold(body: Text('Support opened')),
          ),
          GoRoute(
            path: AppRoutes.deleteAccountPath,
            builder: (context, state) => const Scaffold(body: Text('Delete account opened')),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('settings screen shows request permission action when push permission is not determined', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(const PushPermissionSnapshot(PushPermissionStatus.notDetermined)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Push notifications'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Not requested yet'), findsOneWidget);
    expect(find.text('Supplier'), findsOneWidget);
    expect(find.text('Request permission'), findsOneWidget);
    expect(find.text('Refresh status'), findsOneWidget);
  });

  testWidgets('settings screen shows blocked guidance when push permission is denied', (tester) async {
    await tester.pumpWidget(
      _buildApp(const PushPermissionSnapshot(PushPermissionStatus.denied)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Blocked in system settings'), findsOneWidget);
    expect(find.textContaining('Open your device notification settings'), findsOneWidget);
    expect(find.text('Request permission'), findsNothing);
    expect(find.text('Refresh status'), findsOneWidget);
  });

  testWidgets('settings screen hear summary action triggers contextual TTS', (tester) async {
    final ttsService = _FakeContextualTtsService();

    await tester.pumpWidget(
      _buildApp(
        const PushPermissionSnapshot(PushPermissionStatus.notDetermined),
        ttsService: ttsService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hear summary'));
    await tester.pumpAndSettle();

    expect(ttsService.lastLanguageCode, 'en');
    expect(ttsService.lastMessage, contains('Settings screen.'));
    expect(ttsService.lastMessage, contains('Language is set to English.'));
  });

  testWidgets('settings screen connected profile route opens profile', (tester) async {
    await tester.pumpWidget(_buildApp(const PushPermissionSnapshot(PushPermissionStatus.notDetermined)));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Profile'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile opened'), findsOneWidget);
  });

  testWidgets('settings screen connected profile route opens profile for truckers', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        const PushPermissionSnapshot(PushPermissionStatus.notDetermined),
        roleType: 'trucker',
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Profile'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile opened'), findsOneWidget);
  });

  testWidgets('settings screen connected notifications route opens notifications', (tester) async {
    await tester.pumpWidget(_buildApp(const PushPermissionSnapshot(PushPermissionStatus.notDetermined)));
    await tester.pumpAndSettle();

    final notificationsRouteTile = find.text('Notifications').last;

    await tester.scrollUntilVisible(
      notificationsRouteTile,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(notificationsRouteTile);
    await tester.pumpAndSettle();

    expect(find.text('Notifications opened'), findsOneWidget);
  });

  testWidgets('settings screen connected notifications route opens notifications for truckers', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        const PushPermissionSnapshot(PushPermissionStatus.notDetermined),
        roleType: 'trucker',
      ),
    );
    await tester.pumpAndSettle();

    final notificationsRouteTile = find.text('Notifications').last;

    await tester.scrollUntilVisible(
      notificationsRouteTile,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(notificationsRouteTile);
    await tester.pumpAndSettle();

    expect(find.text('Notifications opened'), findsOneWidget);
  });

  testWidgets('settings screen connected support route opens support', (tester) async {
    await tester.pumpWidget(_buildApp(const PushPermissionSnapshot(PushPermissionStatus.notDetermined)));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Support'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('settings screen connected support route opens support for truckers', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        const PushPermissionSnapshot(PushPermissionStatus.notDetermined),
        roleType: 'trucker',
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Support'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('settings screen connected delete-account route opens delete account', (tester) async {
    await tester.pumpWidget(_buildApp(const PushPermissionSnapshot(PushPermissionStatus.notDetermined)));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Delete account'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    expect(find.text('Delete account opened'), findsOneWidget);
  });

  testWidgets('settings screen connected delete-account route opens delete account for truckers', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        const PushPermissionSnapshot(PushPermissionStatus.notDetermined),
        roleType: 'trucker',
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Delete account'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    expect(find.text('Delete account opened'), findsOneWidget);
  });
}
