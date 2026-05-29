import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/providers/app_locale_providers.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/auth/data/auth_repository.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/core/services/contextual_tts_service.dart';
import 'package:tranzfort/src/features/notifications/data/notification_repository.dart';
import 'package:tranzfort/src/features/notifications/data/notification_tts_service.dart';
import 'package:tranzfort/src/features/notifications/presentation/notifications_screen.dart';
import 'package:tranzfort/src/features/notifications/providers/notification_providers.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(null);
}

class _FixedAppLocaleController extends AppLocaleController {
  _FixedAppLocaleController(String languageCode)
      : super(
          _FakeAuthRepository(),
          profileLanguageCode: languageCode,
        ) {
    state = state.copyWith(
      locale: Locale(languageCode),
      isInitialized: true,
      clearFailure: true,
    );
  }
}

class _NoopNotificationBackend implements NotificationBackend {
  @override
  Future<List<Map<String, dynamic>>> fetchNotifications({required String userId, int limit = 20, DateTime? before}) async =>
      const <Map<String, dynamic>>[];

  @override
  Stream<List<Map<String, dynamic>>> watchNotifications({required String userId}) =>
      const Stream<List<Map<String, dynamic>>>.empty();

  @override
  Future<int> fetchUnreadCount({required String userId}) async => 0;

  @override
  Future<void> markNotificationRead({required String notificationId}) async {}

  @override
  Future<void> markAllNotificationsRead() async {}
}

class _TestNotificationsController extends NotificationsController {
  String? lastMarkedId;
  int loadMoreCalls = 0;
  Result<void> markAllReadResult = const Success<void>(null);

  _TestNotificationsController(NotificationsState state)
      : super(NotificationRepository(_NoopNotificationBackend(), () => 'user-1')) {
    this.state = state;
  }

  @override
  Future<void> load() async {}

  @override
  Future<Result<void>> markRead(String notificationId) async {
    lastMarkedId = notificationId;
    state = state.copyWith(
      notifications: state.notifications
          .map(
            (item) => item.id == notificationId
                ? AppNotification(
                    id: item.id,
                    type: item.type,
                    priority: item.priority,
                    titleText: item.titleText,
                    bodyText: item.bodyText,
                    relatedLoadId: item.relatedLoadId,
                    relatedTripId: item.relatedTripId,
                    relatedCaseId: item.relatedCaseId,
                    actionRouteHint: item.actionRouteHint,
                    isRead: true,
                    readAt: DateTime(2026, 3, 10, 11),
                    createdAt: item.createdAt,
                  )
                : item,
          )
          .toList(growable: false),
      clearFailure: true,
    );
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> markAllRead() async {
    if (markAllReadResult.isFailure) {
      return markAllReadResult;
    }
    state = state.copyWith(
      notifications: state.notifications
          .map(
            (item) => AppNotification(
              id: item.id,
              type: item.type,
              priority: item.priority,
              titleText: item.titleText,
              bodyText: item.bodyText,
              relatedLoadId: item.relatedLoadId,
              relatedTripId: item.relatedTripId,
              relatedCaseId: item.relatedCaseId,
              actionRouteHint: item.actionRouteHint,
              isRead: true,
              readAt: DateTime(2026, 3, 10, 11),
              createdAt: item.createdAt,
            ),
          )
          .toList(growable: false),
      clearFailure: true,
    );
    return const Success<void>(null);
  }

  @override
  Future<void> loadMore() async {
    loadMoreCalls += 1;
  }
}

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
          getVoices: Future<dynamic>.value([]),
          setVoiceFn: (_) async {},
        );

  @override
  Future<ContextualTtsOutcome> speakSummary({required String languageCode, required String message}) async {
    lastLanguageCode = languageCode;
    lastMessage = message;
    return ContextualTtsOutcome.spoken;
  }
}

class _FakeNotificationTtsService extends NotificationTtsService {
  AppNotification? lastNotification;
  AppUserRole? lastRole;

  _FakeNotificationTtsService()
      : super(
          contextualTtsService: _FakeContextualTtsService(),
        );

  @override
  Future<void> speakNotificationOpen(AppNotification notification, AppUserRole role) async {
    lastNotification = notification;
    lastRole = role;
  }
}

AppNotification _notification(
  String id, {
  required String title,
  required String body,
  required DateTime createdAt,
  AppNotificationPriority priority = AppNotificationPriority.medium,
  bool isRead = false,
}) {
  return AppNotification(
    id: id,
    type: AppNotificationType.bookingUpdate,
    priority: priority,
    titleText: title,
    bodyText: body,
    relatedLoadId: 'load-1',
    relatedTripId: 'trip-1',
    relatedCaseId: null,
    actionRouteHint: '/trip-detail/trip-1',
    isRead: isRead,
    readAt: isRead ? DateTime(2026, 3, 10, 11) : null,
    createdAt: createdAt,
  );
}

Widget _buildApp(
  _TestNotificationsController controller, {
  _FakeNotificationTtsService? ttsService,
  _FakeContextualTtsService? contextualTtsService,
  AppUserRole role = AppUserRole.trucker,
}) {
  final resolvedTtsService = ttsService ?? _FakeNotificationTtsService();
  final resolvedContextualTtsService = contextualTtsService ?? _FakeContextualTtsService();
  return ProviderScope(
    overrides: [
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
      notificationsProvider.overrideWith((ref) => controller),
      notificationTtsServiceProvider.overrideWithValue(resolvedTtsService),
      contextualTtsServiceProvider.overrideWithValue(resolvedContextualTtsService),
      appLocaleProvider.overrideWith((ref) => _FixedAppLocaleController('en')),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: NotificationsScreen(),
    ),
  );
}

Widget _buildRoutedApp(
  _TestNotificationsController controller, {
  _FakeNotificationTtsService? ttsService,
  AppUserRole role = AppUserRole.trucker,
}) {
  final resolvedTtsService = ttsService ?? _FakeNotificationTtsService();
  final router = GoRouter(
    initialLocation: AppRoutes.notificationsPath,
    routes: [
      GoRoute(
        path: AppRoutes.notificationsPath,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.tripDetailPath}/:tripId',
        builder: (context, state) => Text('Trip detail ${state.pathParameters['tripId']}'),
      ),
      GoRoute(
        path: '${AppRoutes.loadDetailPath}/:loadId',
        builder: (context, state) => Text('Load detail ${state.pathParameters['loadId']}'),
      ),
      GoRoute(
        path: AppRoutes.findLoadsPath,
        builder: (context, state) => const Text('Find loads'),
      ),
      GoRoute(
        path: AppRoutes.myLoadsPath,
        builder: (context, state) => const Text('My loads'),
      ),
      GoRoute(
        path: '${AppRoutes.chatPath}/:caseId',
        builder: (context, state) => Text('Chat ${state.pathParameters['caseId']}'),
      ),
      GoRoute(
        path: AppRoutes.fleetPath,
        builder: (context, state) => const Text('Fleet route'),
      ),
      GoRoute(
        path: AppRoutes.truckerVerificationPath,
        builder: (context, state) => const Text('Trucker verification'),
      ),
      GoRoute(
        path: AppRoutes.supplierVerificationPath,
        builder: (context, state) => const Text('Supplier verification'),
      ),
      GoRoute(
        path: AppRoutes.truckerDashboardPath,
        builder: (context, state) => const Text('Trucker dashboard'),
      ),
      GoRoute(
        path: AppRoutes.supplierDashboardPath,
        builder: (context, state) => const Text('Supplier dashboard'),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
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
      notificationsProvider.overrideWith((ref) => controller),
      notificationTtsServiceProvider.overrideWithValue(resolvedTtsService),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('renders grouped notifications with overview and high priority treatment', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 12);
    final yesterday = today.subtract(const Duration(days: 1));
    final controller = _TestNotificationsController(
      NotificationsState.initial().copyWith(
        isLoading: false,
        hasResolvedInitialLoad: true,
        hasMore: false,
        notifications: [
          _notification(
            'notification-1',
            title: 'Booking Approved!',
            body: 'Head to pickup for Coal Chandrapur>Mumbai',
            createdAt: today,
            priority: AppNotificationPriority.high,
          ),
          _notification(
            'notification-2',
            title: 'Trip milestone',
            body: 'Your trip has reached the destination gate',
            createdAt: yesterday,
            isRead: true,
          ),
        ],
      ),
    );

    await tester.pumpWidget(_buildApp(controller));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('1 unread'), findsOneWidget);
    expect(find.text('1 high priority'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('HIGH'), findsOneWidget);
    expect(find.text('Booking Approved!'), findsOneWidget);
    expect(find.text('Trip milestone'), findsOneWidget);
  });

  testWidgets('marks all notifications read from app bar action', (tester) async {
    final controller = _TestNotificationsController(
      NotificationsState.initial().copyWith(
        isLoading: false,
        hasResolvedInitialLoad: true,
        hasMore: false,
        notifications: [
          _notification(
            'notification-1',
            title: 'Booking Approved!',
            body: 'Head to pickup for Coal Chandrapur>Mumbai',
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      ),
    );

    await tester.pumpWidget(_buildApp(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark All Read'));
    await tester.pumpAndSettle();

    expect(controller.state.notifications.every((item) => item.isRead), isTrue);
    expect(find.text('All notifications marked as read'), findsOneWidget);
  });

  testWidgets('shows sanitized mark-all-read failure copy', (tester) async {
    final controller = _TestNotificationsController(
      NotificationsState.initial().copyWith(
        isLoading: false,
        hasResolvedInitialLoad: true,
        hasMore: false,
        notifications: [
          _notification(
            'notification-1',
            title: 'Booking Approved!',
            body: 'Head to pickup for Coal Chandrapur>Mumbai',
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      ),
    )..markAllReadResult = const Failure<void>(UnknownFailure(message: 'PostgrestException: leaked detail'));

    await tester.pumpWidget(_buildApp(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark All Read'));
    await tester.pumpAndSettle();

    expect(
      find.text('We could not mark all notifications as read right now. Retry shortly from the notifications screen.'),
      findsOneWidget,
    );
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
  });

  testWidgets('renders notifications empty state', (tester) async {
    final controller = _TestNotificationsController(
      NotificationsState.initial().copyWith(
        isLoading: false,
        hasResolvedInitialLoad: true,
        hasMore: false,
        notifications: const <AppNotification>[],
      ),
    );

    await tester.pumpWidget(_buildApp(controller));
    await tester.pumpAndSettle();

    expect(find.text('All caught up!'), findsOneWidget);
    expect(find.text('No new notifications.'), findsOneWidget);
  });

  testWidgets('supplier notifications empty state opens my loads route', (tester) async {
    final controller = _TestNotificationsController(
      NotificationsState.initial().copyWith(
        isLoading: false,
        hasResolvedInitialLoad: true,
        hasMore: false,
        notifications: const <AppNotification>[],
      ),
    );

    await tester.pumpWidget(_buildRoutedApp(controller, role: AppUserRole.supplier));
    await tester.pumpAndSettle();

    expect(find.text('Open my loads'), findsOneWidget);

    await tester.tap(find.text('Open my loads'));
    await tester.pumpAndSettle();

    expect(find.text('My loads'), findsOneWidget);
  });

  testWidgets('trucker notifications empty state opens find loads route', (tester) async {
    final controller = _TestNotificationsController(
      NotificationsState.initial().copyWith(
        isLoading: false,
        hasResolvedInitialLoad: true,
        hasMore: false,
        notifications: const <AppNotification>[],
      ),
    );

    await tester.pumpWidget(_buildRoutedApp(controller, role: AppUserRole.trucker));
    await tester.pumpAndSettle();

    expect(find.text('Find loads'), findsOneWidget);

    await tester.tap(find.text('Find loads'));
    await tester.pumpAndSettle();

    expect(find.text('Find loads'), findsWidgets);
  });

  testWidgets('load more button requests another page when more notifications are available', (tester) async {
    final controller = _TestNotificationsController(
      NotificationsState.initial().copyWith(
        isLoading: false,
        hasResolvedInitialLoad: true,
        hasMore: true,
        notifications: [
          _notification(
            'notification-1',
            title: 'Booking Approved!',
            body: 'Head to pickup for Coal Chandrapur>Mumbai',
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      ),
    );

    await tester.pumpWidget(_buildApp(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Load More'));
    await tester.pumpAndSettle();

    expect(controller.loadMoreCalls, 1);
  });

  testWidgets('renders notifications error state', (tester) async {
    final controller = _TestNotificationsController(
      NotificationsState.initial().copyWith(
        isLoading: false,
        hasResolvedInitialLoad: true,
        hasMore: false,
        notifications: const <AppNotification>[],
        failure: const ServerFailure(message: 'Unable to load notifications'),
      ),
    );

    await tester.pumpWidget(_buildApp(controller));
    await tester.pumpAndSettle();

    expect(find.text('Unable to load notifications'), findsOneWidget);
    expect(
      find.text('We could not load your notifications right now. Retry shortly to refresh the latest alerts and updates.'),
      findsOneWidget,
    );
  });

  testWidgets('tapping unread notification marks it read', (tester) async {
    final controller = _TestNotificationsController(
      NotificationsState.initial().copyWith(
        isLoading: false,
        hasResolvedInitialLoad: true,
        hasMore: false,
        notifications: [
          _notification(
            'notification-1',
            title: 'Booking Approved!',
            body: 'Head to pickup for Coal Chandrapur>Mumbai',
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      ),
    );

    await tester.pumpWidget(_buildRoutedApp(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Booking Approved!'));
    await tester.pumpAndSettle();

    expect(controller.lastMarkedId, 'notification-1');
    expect(find.text('Trip detail trip-1'), findsOneWidget);
  });

  testWidgets('tapping booking rejected notification triggers trucker TTS before routing', (tester) async {
    final ttsService = _FakeNotificationTtsService();
    final controller = _TestNotificationsController(
      NotificationsState.initial().copyWith(
        isLoading: false,
        hasResolvedInitialLoad: true,
        hasMore: false,
        notifications: [
          AppNotification(
            id: 'notification-1',
            type: AppNotificationType.bookingUpdate,
            priority: AppNotificationPriority.high,
            titleText: 'Booking Rejected',
            bodyText: 'Your booking for Coal was not approved. Reason: Timing mismatch',
            relatedLoadId: 'load-1',
            relatedTripId: null,
            relatedCaseId: null,
            actionRouteHint: AppRoutes.findLoadsPath,
            isRead: false,
            readAt: null,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      ),
    );

    await tester.pumpWidget(_buildRoutedApp(controller, ttsService: ttsService));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Booking Rejected'));
    await tester.pumpAndSettle();

    expect(controller.lastMarkedId, 'notification-1');
    expect(ttsService.lastNotification?.titleText, 'Booking Rejected');
    expect(ttsService.lastRole, AppUserRole.trucker);
    expect(find.text('Find loads'), findsOneWidget);
  });

  testWidgets('notifications overview hear summary action triggers contextual TTS', (tester) async {
    final contextualTtsService = _FakeContextualTtsService();
    final controller = _TestNotificationsController(
      NotificationsState.initial().copyWith(
        isLoading: false,
        hasResolvedInitialLoad: true,
        hasMore: false,
        notifications: [
          _notification(
            'notification-1',
            title: 'Booking Approved!',
            body: 'Head to pickup for Coal Chandrapur>Mumbai',
            createdAt: DateTime(2026, 3, 10, 12),
            priority: AppNotificationPriority.high,
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        controller,
        contextualTtsService: contextualTtsService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hear summary'));
    await tester.pumpAndSettle();

    expect(contextualTtsService.lastLanguageCode, 'en');
    expect(contextualTtsService.lastMessage, contains('Notifications screen.'));
    expect(contextualTtsService.lastMessage, contains('1 unread notifications'));
  });

  testWidgets('tapping notification deep-links to supported route hint', (tester) async {
    final controller = _TestNotificationsController(
      NotificationsState.initial().copyWith(
        isLoading: false,
        hasResolvedInitialLoad: true,
        hasMore: false,
        notifications: [
          _notification(
            'notification-1',
            title: 'Trip Completed!',
            body: 'Rate your experience',
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      ),
    );

    await tester.pumpWidget(_buildRoutedApp(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trip Completed!'));
    await tester.pumpAndSettle();

    expect(controller.lastMarkedId, 'notification-1');
    expect(find.text('Trip detail trip-1'), findsOneWidget);
  });

  testWidgets('tapping notification deep-links to supported chat placeholder route', (tester) async {
    final controller = _TestNotificationsController(
      NotificationsState.initial().copyWith(
        isLoading: false,
        hasResolvedInitialLoad: true,
        hasMore: false,
        notifications: [
          AppNotification(
            id: 'notification-1',
            type: AppNotificationType.messageReceived,
            priority: AppNotificationPriority.medium,
            titleText: 'New message received',
            bodyText: 'A transporter replied in chat',
            relatedLoadId: 'load-1',
            relatedTripId: null,
            relatedCaseId: 'case-9',
            actionRouteHint: '/chat/{caseId}',
            isRead: false,
            readAt: null,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      ),
    );

    await tester.pumpWidget(_buildRoutedApp(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New message received'));
    await tester.pumpAndSettle();

    expect(controller.lastMarkedId, 'notification-1');
    expect(find.text('Chat case-9'), findsOneWidget);
  });

  testWidgets('tapping notification deep-links to stale my-fleet hint via fleet route', (tester) async {
    final controller = _TestNotificationsController(
      NotificationsState.initial().copyWith(
        isLoading: false,
        hasResolvedInitialLoad: true,
        hasMore: false,
        notifications: [
          AppNotification(
            id: 'notification-1',
            type: AppNotificationType.verificationUpdate,
            priority: AppNotificationPriority.medium,
            titleText: 'Truck approval needed',
            bodyText: 'Open your fleet to review the latest truck status.',
            relatedLoadId: null,
            relatedTripId: null,
            relatedCaseId: null,
            actionRouteHint: '/my-fleet',
            isRead: false,
            readAt: null,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      ),
    );

    await tester.pumpWidget(_buildRoutedApp(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Truck approval needed'));
    await tester.pumpAndSettle();

    expect(controller.lastMarkedId, 'notification-1');
    expect(find.text('Fleet route'), findsOneWidget);
  });

  testWidgets('tapping notification falls back to related load route when no action hint exists', (tester) async {
    final controller = _TestNotificationsController(
      NotificationsState.initial().copyWith(
        isLoading: false,
        hasResolvedInitialLoad: true,
        hasMore: false,
        notifications: [
          AppNotification(
            id: 'notification-1',
            type: AppNotificationType.bookingUpdate,
            priority: AppNotificationPriority.medium,
            titleText: 'Load updated',
            bodyText: 'A load update is ready for review.',
            relatedLoadId: 'load-7',
            relatedTripId: null,
            relatedCaseId: null,
            actionRouteHint: null,
            isRead: false,
            readAt: null,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      ),
    );

    await tester.pumpWidget(_buildRoutedApp(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Load updated'));
    await tester.pumpAndSettle();

    expect(controller.lastMarkedId, 'notification-1');
    expect(find.text('Load detail load-7'), findsOneWidget);
  });

  testWidgets('tapping verification notification opens trucker verification for trucker role', (tester) async {
    final controller = _TestNotificationsController(
      NotificationsState.initial().copyWith(
        isLoading: false,
        hasResolvedInitialLoad: true,
        hasMore: false,
        notifications: [
          AppNotification(
            id: 'notification-1',
            type: AppNotificationType.verificationUpdate,
            priority: AppNotificationPriority.medium,
            titleText: 'Verification Update',
            bodyText: 'Please review your verification feedback.',
            relatedLoadId: null,
            relatedTripId: null,
            relatedCaseId: 'case-1',
            actionRouteHint: '/verification',
            isRead: false,
            readAt: null,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      ),
    );

    await tester.pumpWidget(_buildRoutedApp(controller, role: AppUserRole.trucker));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Verification Update'));
    await tester.pumpAndSettle();

    expect(controller.lastMarkedId, 'notification-1');
    expect(find.text('Trucker verification'), findsOneWidget);
  });

  testWidgets('tapping verification notification opens supplier verification for supplier role', (tester) async {
    final controller = _TestNotificationsController(
      NotificationsState.initial().copyWith(
        isLoading: false,
        hasResolvedInitialLoad: true,
        hasMore: false,
        notifications: [
          AppNotification(
            id: 'notification-1',
            type: AppNotificationType.verificationUpdate,
            priority: AppNotificationPriority.medium,
            titleText: 'Verification Update',
            bodyText: 'Please review your verification feedback.',
            relatedLoadId: null,
            relatedTripId: null,
            relatedCaseId: 'case-1',
            actionRouteHint: '/verification',
            isRead: false,
            readAt: null,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      ),
    );

    await tester.pumpWidget(_buildRoutedApp(controller, role: AppUserRole.supplier));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Verification Update'));
    await tester.pumpAndSettle();

    expect(controller.lastMarkedId, 'notification-1');
    expect(find.text('Supplier verification'), findsOneWidget);
  });

  testWidgets('tapping notification falls back for unsupported route hint', (tester) async {
    final controller = _TestNotificationsController(
      NotificationsState.initial().copyWith(
        isLoading: false,
        hasResolvedInitialLoad: true,
        hasMore: false,
        notifications: [
          AppNotification(
            id: 'notification-1',
            type: AppNotificationType.supportUpdate,
            priority: AppNotificationPriority.medium,
            titleText: 'Support Reply',
            bodyText: 'Your ticket has a new response',
            relatedLoadId: null,
            relatedTripId: null,
            relatedCaseId: 'ticket-1',
            actionRouteHint: '/support-ticket/{caseId}',
            isRead: false,
            readAt: null,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      ),
    );

    await tester.pumpWidget(_buildRoutedApp(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Support Reply'));
    await tester.pumpAndSettle();

    expect(controller.lastMarkedId, 'notification-1');
    expect(find.text('Trucker dashboard'), findsOneWidget);
  });
}
