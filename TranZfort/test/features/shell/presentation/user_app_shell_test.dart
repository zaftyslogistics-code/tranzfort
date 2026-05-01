import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/providers/app_locale_providers.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/core/services/contextual_tts_service.dart';
import 'package:tranzfort/src/features/auth/data/auth_repository.dart';
import 'package:tranzfort/src/features/communication/data/chat_repository.dart';
import 'package:tranzfort/src/features/communication/providers/chat_providers.dart';
import 'package:tranzfort/src/features/shell/presentation/user_app_shell.dart';
import 'package:tranzfort/src/features/notifications/providers/notification_providers.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

class _FixedAppLocaleController extends AppLocaleController {
  _FixedAppLocaleController(String languageCode)
      : super(
          _FakeAuthRepository(),
          profileLanguageCode: languageCode,
        ) {
    state = AppLocaleState(
      locale: Locale(languageCode),
      isInitialized: true,
      isSaving: false,
      failure: null,
    );
  }
}

class _FakeAuthRepository extends AuthRepository {
  int signOutCalls = 0;

  _FakeAuthRepository() : super(null);

  @override
  Future<Result<void>> signOutAndClearLocalState() async {
    signOutCalls += 1;
    return const Success<void>(null);
  }
}

class _NoopChatBackend implements ChatBackend {
  const _NoopChatBackend();

  @override
  Future<List<Map<String, dynamic>>> fetchConversations({required String userId, required AppUserRole role}) async =>
      const <Map<String, dynamic>>[];

  @override
  Future<Object?> fetchConversation(String conversationId) async => null;

  @override
  Stream<List<Map<String, dynamic>>> watchConversations({required String userId, required AppUserRole role}) =>
      const Stream<List<Map<String, dynamic>>>.empty();

  @override
  Future<List<Map<String, dynamic>>> fetchMessages({required String conversationId}) async => const <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> fetchMessagesPaginated({
    required String conversationId,
    int limit = 50,
    DateTime? beforeCreatedAt,
    String? beforeMessageId,
  }) async => const <Map<String, dynamic>>[];

  @override
  Stream<List<Map<String, dynamic>>> watchMessages({required String conversationId}) =>
      const Stream<List<Map<String, dynamic>>>.empty();

  @override
  Future<Map<String, dynamic>?> fetchLatestMessage({required String conversationId}) async => null;

  @override
  Future<bool> fetchHasUnread({required String conversationId, required String currentUserId}) async => false;

  @override
  Future<Map<String, dynamic>?> fetchLoadContext(String loadId) async => null;

  @override
  Future<Map<String, dynamic>?> fetchProfile(String profileId) async => null;

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId) async => null;

  @override
  Future<Map<String, dynamic>?> fetchBookingContext({required String loadId, required String truckerId}) async => null;

  @override
  Future<String> createOrGetConversation({required String supplierId, required String truckerId, required String loadId}) async =>
      'conversation-1';

  @override
  Future<String> sendMessage({required String conversationId, required ChatMessageType type, String? messageId, String? textBody, String? attachmentPath, Map<String, dynamic>? structuredPayload}) async =>
      'message-1';

  @override
  Future<void> markMessagesRead({required String conversationId, required String readerId}) async {}

  @override
  Future<int> fetchUnreadConversationCount() async => 0;
}

class _TestInboxController extends InboxController {
  _TestInboxController(this._initialState)
      : super(
          ChatRepository(
            const _NoopChatBackend(),
            () => 'profile-1',
            () => AppUserRole.trucker,
          ),
        ) {
    state = _initialState;
  }

  final InboxState _initialState;

  @override
  Future<void> load() async {}
}

class _FakeContextualTtsService extends ContextualTtsService {
  _FakeContextualTtsService()
      : super(
          setLanguageFn: (_) async {},
          setSpeechRateFn: (_) async {},
          speakFn: (_) async {},
          stopFn: () async {},
          preferencesFn: SharedPreferences.getInstance,
          getVoices: Future<dynamic>.value([]),
          setVoiceFn: (_) async {},
        );

  String? lastLanguageCode;
  String? lastMessage;
  int speakCalls = 0;

  @override
  Future<ContextualTtsOutcome> speakSummary({required String languageCode, required String message}) async {
    lastLanguageCode = languageCode;
    lastMessage = message;
    speakCalls += 1;
    return ContextualTtsOutcome.spoken;
  }
}

ConversationPreview _conversation(String id, {bool hasUnread = false}) {
  return ConversationPreview(
    id: id,
    supplierId: 'supplier-1',
    truckerId: 'trucker-1',
    loadId: 'load-1',
    tripId: 'trip-1',
    routeLabel: 'Chandrapur, Maharashtra > Mumbai, Maharashtra',
    loadMaterial: 'Coal',
    loadPriceAmount: 62500,
    loadStatusLabel: 'active',
    pickupDate: DateTime(2026, 3, 11),
    supplierName: 'Amit Supplier',
    supplierMobile: '+919876543210',
    supplierCompanyName: 'Amit Logistics',
    truckerName: 'Ravi Trucker',
    truckerMobile: '+919812345678',
    truckDisplayLabel: 'MH12AB1234 - Tata Ace Gold',
    bookingRequestId: 'booking-1',
    bookingStatusLabel: 'approved',
    latestMessagePreview: 'Latest update',
    lastMessageAt: DateTime(2026, 3, 10, 9),
    hasUnread: hasUnread,
    isArchived: false,
    createdAt: DateTime(2026, 3, 10, 8),
  );
}

Widget _buildApp({
  required int unreadNotifications,
  required InboxState inboxState,
  int unreadConversations = 0,
}) {
  final resolvedTtsService = ContextualTtsService(
    setLanguageFn: (_) async {},
    setSpeechRateFn: (_) async {},
    speakFn: (_) async {},
    stopFn: () async {},
    preferencesFn: SharedPreferences.getInstance,
    getVoices: Future<dynamic>.value([]),
    setVoiceFn: (_) async {},
  );

  return ProviderScope(
    overrides: [
      appLocaleProvider.overrideWith((ref) => _FixedAppLocaleController('en')),
      contextualTtsServiceProvider.overrideWithValue(resolvedTtsService),
      currentAuthStateProvider.overrideWithValue(
        const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.trucker,
          isBanned: false,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
      inboxProvider.overrideWith((ref) => _TestInboxController(inboxState)),
      unreadConversationCountProvider.overrideWith((ref) => Stream<int>.value(unreadConversations)),
      shellUnreadNotificationCountProvider.overrideWith((ref) => Stream<int>.value(unreadNotifications)),
      unreadNotificationCountProvider.overrideWith((ref) => unreadNotifications),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: UserAppShell(
        currentLocation: AppRoutes.truckerDashboardPath,
        role: AppUserRole.trucker,
        child: const SizedBox.shrink(),
      ),
    ),
  );
}

Widget _buildRoutedApp({
  required int unreadNotifications,
  required InboxState inboxState,
  int unreadConversations = 0,
  String currentLocation = AppRoutes.supplierDashboardPath,
  AppUserRole role = AppUserRole.supplier,
  _FakeAuthRepository? authRepository,
  ContextualTtsService? ttsService,
}) {
  final resolvedTtsService = ttsService ??
      ContextualTtsService(
        setLanguageFn: (_) async {},
        setSpeechRateFn: (_) async {},
        speakFn: (_) async {},
        stopFn: () async {},
        preferencesFn: SharedPreferences.getInstance,
        getVoices: Future<dynamic>.value([]),
        setVoiceFn: (_) async {},
      );

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => UserAppShell(
          currentLocation: currentLocation,
          role: role,
          child: const SizedBox.shrink(),
        ),
      ),
      GoRoute(
        path: '/assistant',
        builder: (context, state) => const Scaffold(body: Text('Assistant opened')),
      ),
      GoRoute(
        path: AppRoutes.notificationsPath,
        builder: (context, state) => const Scaffold(body: Text('Notifications opened')),
      ),
      GoRoute(
        path: AppRoutes.supplierDashboardPath,
        builder: (context, state) => const Scaffold(body: Text('Supplier dashboard opened')),
      ),
      GoRoute(
        path: AppRoutes.truckerDashboardPath,
        builder: (context, state) => const Scaffold(body: Text('Trucker dashboard opened')),
      ),
      GoRoute(
        path: AppRoutes.messagesPath,
        builder: (context, state) => const Scaffold(body: Text('Messages opened')),
      ),
      GoRoute(
        path: AppRoutes.myLoadsPath,
        builder: (context, state) => const Scaffold(body: Text('My loads opened')),
      ),
      GoRoute(
        path: AppRoutes.supplierTripsPath,
        builder: (context, state) => const Scaffold(body: Text('Supplier trips opened')),
      ),
      GoRoute(
        path: AppRoutes.tripsPath,
        builder: (context, state) => const Scaffold(body: Text('Trips opened')),
      ),
      GoRoute(
        path: AppRoutes.findLoadsPath,
        builder: (context, state) => const Scaffold(body: Text('Find loads opened')),
      ),
      GoRoute(
        path: AppRoutes.settingsPath,
        builder: (context, state) => const Scaffold(body: Text('Settings opened')),
      ),
      GoRoute(
        path: AppRoutes.fleetPath,
        builder: (context, state) => const Scaffold(body: Text('Fleet opened')),
      ),
      GoRoute(
        path: AppRoutes.authPath,
        builder: (context, state) => const Scaffold(body: Text('Auth screen opened')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      appLocaleProvider.overrideWith((ref) => _FixedAppLocaleController('en')),
      contextualTtsServiceProvider.overrideWithValue(resolvedTtsService),
      currentAuthStateProvider.overrideWithValue(
        AuthStateSnapshot(
          hasSession: true,
          role: role,
          isBanned: false,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
      inboxProvider.overrideWith((ref) => _TestInboxController(inboxState)),
      unreadConversationCountProvider.overrideWith((ref) => Stream<int>.value(unreadConversations)),
      shellUnreadNotificationCountProvider.overrideWith((ref) => Stream<int>.value(unreadNotifications)),
      unreadNotificationCountProvider.overrideWith((ref) => unreadNotifications),
      if (authRepository != null) authRepositoryProvider.overrideWithValue(authRepository),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  Future<void> openShellDrawer(WidgetTester tester) async {
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold).first);
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();
  }

  testWidgets('shows unread notification badge in the top app bar bell', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(
        unreadNotifications: 3,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: <ConversationPreview>[_conversation('conversation-1', hasUnread: true)],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Notifications'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  }, semanticsEnabled: false);

  testWidgets('top app bar shows notifications voice assistance language toggle and profile actions', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(
        unreadNotifications: 0,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: const <ConversationPreview>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Notifications'), findsOneWidget);
    expect(find.byTooltip('Voice assistance'), findsOneWidget);
    expect(find.byTooltip('Switch language'), findsOneWidget);
    expect(find.byTooltip('Profile'), findsOneWidget);
  }, semanticsEnabled: false);

  testWidgets('top app bar voice assistance action is visible', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        unreadNotifications: 0,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: <ConversationPreview>[_conversation('conversation-1', hasUnread: true)],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Voice assistance'), findsOneWidget);
  }, semanticsEnabled: false);

  testWidgets('top app bar voice assistance uses shell title as fallback summary', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    final ttsService = _FakeContextualTtsService();

    await tester.pumpWidget(
      _buildRoutedApp(
        unreadNotifications: 0,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: const <ConversationPreview>[],
        ),
        role: AppUserRole.supplier,
        currentLocation: AppRoutes.supplierDashboardPath,
        ttsService: ttsService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Voice assistance'));
    await tester.pumpAndSettle();

    expect(ttsService.speakCalls, 1);
    expect(ttsService.lastMessage, 'Supplier dashboard');
    expect(find.text('Voice guidance is unavailable right now.'), findsNothing);
  }, semanticsEnabled: false);

  testWidgets('drawer assistant item is not visible', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        unreadNotifications: 0,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: const <ConversationPreview>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await openShellDrawer(tester);

    expect(find.text('Assistant'), findsNothing);
  }, semanticsEnabled: false);

  testWidgets('drawer does not include messages item', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        unreadNotifications: 0,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: const <ConversationPreview>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await openShellDrawer(tester);

    final drawerScope = find.byType(UserAppDrawerContent);
    expect(
      find.descendant(of: drawerScope, matching: find.text('Messages')),
      findsNothing,
    );
  }, semanticsEnabled: false);

  testWidgets('messages is a bottom navigation destination for truckers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        unreadNotifications: 0,
        currentLocation: AppRoutes.truckerDashboardPath,
        role: AppUserRole.trucker,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: const <ConversationPreview>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final navigationBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navigationBar.destinations, hasLength(4));
    expect(find.text('Messages'), findsOneWidget);
  }, semanticsEnabled: false);

  testWidgets('drawer does not include notifications item', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        unreadNotifications: 0,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: const <ConversationPreview>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await openShellDrawer(tester);

    final drawerScope = find.byType(UserAppDrawerContent);
    expect(
      find.descendant(of: drawerScope, matching: find.text('Notifications')),
      findsNothing,
    );
  }, semanticsEnabled: false);

  testWidgets('drawer unread badges no longer render because messages and notifications are not drawer items', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildRoutedApp(
        unreadNotifications: 3,
        unreadConversations: 1,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: <ConversationPreview>[_conversation('conversation-1', hasUnread: true)],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await openShellDrawer(tester);

    final drawerScope = find.byType(UserAppDrawerContent);
    expect(
      find.descendant(of: drawerScope, matching: find.text('Messages')),
      findsNothing,
    );
    expect(
      find.descendant(of: drawerScope, matching: find.text('Notifications')),
      findsNothing,
    );
  }, semanticsEnabled: false);

  testWidgets('drawer language item routes to settings', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        unreadNotifications: 0,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: const <ConversationPreview>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await openShellDrawer(tester);

    await tester.scrollUntilVisible(find.text('Language'), 100);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    expect(find.text('Settings opened'), findsOneWidget);
  }, semanticsEnabled: false);

  testWidgets('drawer fleet item routes truckers to fleet', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        unreadNotifications: 0,
        currentLocation: AppRoutes.truckerDashboardPath,
        role: AppUserRole.trucker,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: const <ConversationPreview>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await openShellDrawer(tester);

    await tester.tap(find.text('Fleet'));
    await tester.pumpAndSettle();

    expect(find.text('Fleet opened'), findsOneWidget);
  }, semanticsEnabled: false);

  testWidgets('drawer sign out item signs out and routes to auth', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    final authRepository = _FakeAuthRepository();

    await tester.pumpWidget(
      _buildRoutedApp(
        unreadNotifications: 0,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: const <ConversationPreview>[],
        ),
        authRepository: authRepository,
      ),
    );
    await tester.pumpAndSettle();

    await openShellDrawer(tester);

    await tester.scrollUntilVisible(find.text('Sign out'), 100);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Auth screen opened'), findsOneWidget);
    expect(authRepository.signOutCalls, 1);
  }, semanticsEnabled: false);

  testWidgets('bottom navigation routes suppliers to my loads', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        unreadNotifications: 0,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: const <ConversationPreview>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Loads'));
    await tester.pumpAndSettle();

    expect(find.text('My loads opened'), findsOneWidget);
  }, semanticsEnabled: false);

  testWidgets('bottom navigation routes suppliers to trips', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        unreadNotifications: 0,
        currentLocation: AppRoutes.supplierDashboardPath,
        role: AppUserRole.supplier,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: const <ConversationPreview>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trips'));
    await tester.pumpAndSettle();

    expect(find.text('Supplier trips opened'), findsOneWidget);
  }, semanticsEnabled: false);

  testWidgets('bottom navigation routes suppliers to messages', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        unreadNotifications: 0,
        currentLocation: AppRoutes.supplierDashboardPath,
        role: AppUserRole.supplier,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: const <ConversationPreview>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Messages'));
    await tester.pumpAndSettle();

    expect(find.text('Messages opened'), findsOneWidget);
  }, semanticsEnabled: false);

  testWidgets('supplier post load route keeps loads tab selected without showing top-level app bar', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        unreadNotifications: 0,
        currentLocation: AppRoutes.postLoadPath,
        role: AppUserRole.supplier,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: const <ConversationPreview>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final navigationBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navigationBar.selectedIndex, 1);
    expect(find.byType(AppBar), findsNothing);
  }, semanticsEnabled: false);

  testWidgets('trucker load detail route keeps find loads tab selected', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        unreadNotifications: 0,
        currentLocation: '${AppRoutes.loadDetailPath}/load-42',
        role: AppUserRole.trucker,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: const <ConversationPreview>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final navigationBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navigationBar.selectedIndex, 1);
  }, semanticsEnabled: false);

  testWidgets('bottom navigation routes truckers to find loads', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        unreadNotifications: 0,
        currentLocation: AppRoutes.truckerDashboardPath,
        role: AppUserRole.trucker,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: const <ConversationPreview>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Find'));
    await tester.pumpAndSettle();

    expect(find.text('Find loads opened'), findsOneWidget);
  }, semanticsEnabled: false);

  testWidgets('bottom navigation routes truckers to trips', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        unreadNotifications: 0,
        currentLocation: AppRoutes.truckerDashboardPath,
        role: AppUserRole.trucker,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: const <ConversationPreview>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trips'));
    await tester.pumpAndSettle();

    expect(find.text('Trips opened'), findsOneWidget);
  }, semanticsEnabled: false);

  testWidgets('bottom navigation routes truckers to messages', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        unreadNotifications: 0,
        currentLocation: AppRoutes.truckerDashboardPath,
        role: AppUserRole.trucker,
        inboxState: InboxState.initial().copyWith(
          isLoading: false,
          conversations: const <ConversationPreview>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Messages'));
    await tester.pumpAndSettle();

    expect(find.text('Messages opened'), findsOneWidget);
  }, semanticsEnabled: false);

}
