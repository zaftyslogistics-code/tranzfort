import 'dart:async';
import 'dart:io';

import 'package:app/src/core/config/supabase_config.dart';
import 'package:app/src/core/error/app_failure.dart';
import 'package:app/src/core/error/result.dart';
import 'package:app/src/core/routing/app_router.dart';
import 'package:app/src/core/services/tts_service.dart';
import 'package:app/src/features/auth/providers/auth_providers.dart';
import 'package:app/src/features/bot/presentation/bot_chat_screen.dart';
import 'package:app/src/features/bot/services/basic_bot_service.dart';
import 'package:app/src/features/bot/services/bot_stt_service.dart';
import 'package:app/src/features/bot/services/conversation_state.dart';
import 'package:app/src/features/chat/presentation/chat_list_screen.dart';
import 'package:app/src/features/chat/presentation/chat_screen.dart';
import 'package:app/src/features/chat/providers/chat_providers.dart';
import 'package:app/src/features/fleet/presentation/my_fleet_screen.dart';
import 'package:app/src/features/fleet/providers/fleet_providers.dart';
import 'package:app/src/features/marketplace/presentation/load_detail_screen.dart';
import 'package:app/src/features/marketplace/presentation/find_loads_screen.dart';
import 'package:app/src/features/marketplace/presentation/my_loads_screen.dart';
import 'package:app/src/features/marketplace/providers/marketplace_providers.dart';
import 'package:app/src/features/notifications/presentation/notifications_screen.dart';
import 'package:app/src/features/notifications/providers/notifications_provider.dart';
import 'package:app/src/features/payout/presentation/payout_profile_screen.dart';
import 'package:app/src/features/payout/providers/payout_profile_provider.dart';
import 'package:app/src/features/settings/presentation/settings_screen.dart';
import 'package:app/src/features/trips/presentation/my_trips_screen.dart';
import 'package:app/src/features/trips/presentation/trip_detail_screen.dart';
import 'package:app/src/features/trips/providers/trips_providers.dart';
import 'package:app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _RouterHost extends ConsumerWidget {
  const _RouterHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
    );
  }
}

class _FakeFindLoadsNotifier extends FindLoadsNotifier {
  static int searchCalls = 0;
  static LoadFilters? lastFilters;

  _FakeFindLoadsNotifier(
    super.ref, {
    required List<Map<String, dynamic>> seededResults,
    required List<Map<String, dynamic>> seededTrucks,
  }) {
    state = FindLoadsState(
      isSearching: false,
      isLoadingMore: false,
      hasMorePages: false,
      currentPage: 1,
      results: seededResults,
      myTrucks: seededTrucks,
      filters: const LoadFilters(),
    );
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> search(LoadFilters filters) async {
    searchCalls += 1;
    lastFilters = filters;
    state = state.copyWith(
      isSearching: false,
      filters: filters,
    );
  }

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> resetFilters() async {}
}

class _FakeBookLoadActionNotifier extends LoadActionNotifier {
  _FakeBookLoadActionNotifier(super.ref);

  static int bookLoadWithTruckCalls = 0;
  static String? lastParentLoadId;
  static String? lastTruckId;

  @override
  Future<bool> bookLoadWithTruck({
    required String parentLoadId,
    required String truckId,
  }) async {
    bookLoadWithTruckCalls += 1;
    lastParentLoadId = parentLoadId;
    lastTruckId = truckId;
    state = const AsyncData(null);
    return true;
  }
}

class _ShellRouterHost extends StatelessWidget {
  const _ShellRouterHost({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
    );
  }
}

class _FakeTripActionNotifier extends TripActionNotifier {
  _FakeTripActionNotifier(super.ref);

  static bool startTripCalled = false;
  static bool markDeliveredCalled = false;
  static bool uploadLrCalled = false;
  static bool uploadPodCalled = false;

  @override
  Future<bool> startTrip(String tripId) async {
    startTripCalled = true;
    state = const AsyncData(null);
    return true;
  }

  @override
  Future<bool> markDelivered(String tripId) async {
    markDeliveredCalled = true;
    state = const AsyncData(null);
    return true;
  }

  @override
  Future<bool> uploadLr({required String tripId, required File lrFile}) async {
    uploadLrCalled = true;
    state = const AsyncData(null);
    return true;
  }

  @override
  Future<bool> uploadPod({required String tripId, required File podFile}) async {
    uploadPodCalled = true;
    state = const AsyncData(null);
    return true;
  }
}

class _FakeNotificationActionNotifier extends NotificationActionNotifier {
  _FakeNotificationActionNotifier(super.ref);

  static bool markAllCalled = false;
  static final markedReadIds = <String>[];

  @override
  Future<void> markRead(String notificationId) async {
    markedReadIds.add(notificationId);
    state = const AsyncData(null);
  }

  @override
  Future<void> markAllRead() async {
    markAllCalled = true;
    state = const AsyncData(null);
  }
}

class _FakeChatSendNotifier extends ChatSendNotifier {
  _FakeChatSendNotifier(super.ref);

  static final sentTexts = <String>[];

  @override
  Future<bool> sendText(String conversationId, String text) async {
    sentTexts.add(text.trim());
    state = const AsyncData(null);
    return true;
  }
}

class _FakeBotSttAllowNotifier extends BotSttNotifier {
  static int startCalls = 0;

  @override
  Future<Result<void>> startListening(
    void Function(String) onFinalResult,
  ) async {
    startCalls += 1;
    state = state.copyWith(
      isListening: true,
      partialTranscript: 'trip status',
      clearError: true,
    );
    onFinalResult('trip status');
    state = state.copyWith(isListening: false);
    return const Success(null);
  }

  @override
  Future<void> stopListening() async {
    state = state.copyWith(isListening: false);
  }
}

class _FakeBotSttDeniedNotifier extends BotSttNotifier {
  static int startCalls = 0;

  @override
  Future<Result<void>> startListening(
    void Function(String) onFinalResult,
  ) async {
    startCalls += 1;
    state = state.copyWith(
      isListening: false,
      lastError: AppFailureType.forbidden,
    );
    return const Failure(
      AppFailureType.forbidden,
      debugMessage: 'Microphone permission denied',
    );
  }
}

class _SeededBotActionNotifier extends BotChatNotifier {
  _SeededBotActionNotifier() {
    state = const ConversationState(
      messages: [
        {
          'text': 'Open add-truck workflow',
          'is_user': false,
          'action_route': '/my-fleet/add',
          'action_label': 'Open Add Truck',
        },
      ],
    );
  }
}

class _FakeFallbackBotService extends BasicBotService {
  _FakeFallbackBotService(this._ref)
    : super(_ref.read(botChatProvider.notifier), _ref.read(ttsServiceProvider));

  final Ref _ref;

  @override
  Future<void> handleInput(String input, ConversationState state) async {
    final notifier = _ref.read(botChatProvider.notifier);
    notifier.setProcessing(false);
    notifier.addMessage(input, isUser: true);
    notifier.addMessage(
      'Service temporarily unavailable. Please try again.',
      isUser: false,
    );
  }
}

GoRouter _buildShellRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/my-loads', builder: (context, state) => const MyLoadsScreen()),
      GoRoute(path: '/my-trips', builder: (context, state) => const MyTripsScreen()),
      GoRoute(
        path: '/trip-detail/:tripId',
        builder: (context, state) =>
            TripDetailScreen(tripId: state.pathParameters['tripId'] ?? ''),
      ),
      GoRoute(path: '/messages', builder: (context, state) => const ChatListScreen()),
      GoRoute(path: '/bot-chat', builder: (context, state) => const BotChatScreen()),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (context, state) =>
            ChatScreen(conversationId: state.pathParameters['conversationId'] ?? ''),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/my-fleet', builder: (context, state) => const MyFleetScreen()),
      GoRoute(
        path: '/my-fleet/add',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Add truck form'))),
      ),
      GoRoute(
        path: '/payout-profile',
        builder: (context, state) => const PayoutProfileScreen(),
      ),
      GoRoute(
        path: '/load-detail/:loadId',
        builder: (context, state) =>
            LoadDetailScreen(loadId: state.pathParameters['loadId'] ?? ''),
      ),
      GoRoute(
        path: '/find-loads',
        builder: (context, state) => const FindLoadsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Profile'))),
      ),
    ],
  );
}

AuthState _signedInAuthState() {
  final session = Session.fromJson({
    'access_token': 'core-flow-access-token',
    'token_type': 'bearer',
    'refresh_token': 'core-flow-refresh-token',
    'expires_in': 3600,
    'user': {
      'id': '11111111-1111-1111-1111-111111111111',
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'core-flow@tranzfort.app',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'created_at': '2026-02-27T00:00:00Z',
    },
  });

  return AuthState(AuthChangeEvent.signedIn, session);
}

void _setLargeViewport(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 3.0;
}

Map<String, dynamic> _fixtureSupplierLoad() {
  return {
    'id': 'load-4x',
    'origin_city': 'Mumbai',
    'dest_city': 'Pune',
    'material': 'Steel',
    'weight_tonnes': 24,
    'price': 64000,
    'trucks_needed': 2,
    'trucks_booked': 1,
    'status': 'active',
  };
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('User core 4.x remaining integration tests', () {
    testWidgets('X-BOOK-01/02: trucker discovers supplier load and creates booking request', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);
      _FakeBookLoadActionNotifier.bookLoadWithTruckCalls = 0;
      _FakeBookLoadActionNotifier.lastParentLoadId = null;
      _FakeBookLoadActionNotifier.lastTruckId = null;

      final seededLoad = {
        'id': 'load-x1',
        'supplier_id': 'supplier-x',
        'origin_city': 'Mumbai',
        'origin_state': 'Maharashtra',
        'dest_city': 'Pune',
        'dest_state': 'Maharashtra',
        'material': 'Steel',
        'weight_tonnes': 24,
        'price': 64000,
        'distance_km': 150,
        'trucks_needed': 2,
        'trucks_booked': 0,
        'required_truck_type': 'open',
        'required_tyres': const [10],
        'advance_percentage': 20,
        'poster_label': 'Fixture Supplier Pvt Ltd',
        'created_at': DateTime.now().toIso8601String(),
        'pickup_date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'trucker',
                'verification_status': 'verified',
                'mobile': '+919999999999',
              },
            ),
            findLoadsProvider.overrideWith(
              (ref) => _FakeFindLoadsNotifier(
                ref,
                seededResults: [seededLoad],
                seededTrucks: const [
                  {
                    'id': 'truck-verified-1',
                    'truck_number': 'MH12AB1234',
                    'body_type': 'open',
                    'tyres': 10,
                    'capacity_tonnes': 25,
                  },
                ],
              ),
            ),
            loadActionProvider.overrideWith((ref) => _FakeBookLoadActionNotifier(ref)),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/find-loads')),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 1200));

      expect(find.text('Mumbai → Pune'), findsOneWidget);
      expect(find.text('Steel'), findsOneWidget);

      final context = tester.element(find.byType(FindLoadsScreen));
      final container = ProviderScope.containerOf(context);
      final success = await container.read(loadActionProvider.notifier).bookLoadWithTruck(
        parentLoadId: 'load-x1',
        truckId: 'truck-verified-1',
      );

      expect(success, isTrue);
      expect(_FakeBookLoadActionNotifier.bookLoadWithTruckCalls, 1);
      expect(_FakeBookLoadActionNotifier.lastParentLoadId, 'load-x1');
      expect(_FakeBookLoadActionNotifier.lastTruckId, 'truck-verified-1');
    });

    testWidgets('T-DISC-03: trucker opens load detail from find-loads list', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);

      final seededLoad = {
        'id': 'load-disc-3',
        'supplier_id': 'supplier-x',
        'origin_city': 'Mumbai',
        'origin_state': 'Maharashtra',
        'dest_city': 'Pune',
        'dest_state': 'Maharashtra',
        'material': 'Steel',
        'weight_tonnes': 24,
        'price': 64000,
        'distance_km': 150,
        'trucks_needed': 1,
        'trucks_booked': 0,
        'required_truck_type': 'open',
        'required_tyres': const [10],
        'advance_percentage': 20,
        'poster_label': 'Fixture Supplier Pvt Ltd',
        'created_at': DateTime.now().toIso8601String(),
        'pickup_date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'trucker',
                'verification_status': 'verified',
                'mobile': '+919999999999',
              },
            ),
            findLoadsProvider.overrideWith(
              (ref) => _FakeFindLoadsNotifier(
                ref,
                seededResults: [seededLoad],
                seededTrucks: const [
                  {
                    'id': 'truck-verified-1',
                    'truck_number': 'MH12AB1234',
                    'body_type': 'open',
                    'tyres': 10,
                    'capacity_tonnes': 25,
                  },
                ],
              ),
            ),
            loadActionProvider.overrideWith((ref) => _FakeBookLoadActionNotifier(ref)),
            loadDetailProvider('load-disc-3').overrideWith(
              (ref) async => {
                'id': 'load-disc-3',
                'origin_city': 'Mumbai',
                'dest_city': 'Pune',
                'material': 'Steel',
                'weight_tonnes': 24,
                'price': 64000,
              },
            ),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/find-loads')),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 1200));
      await tester.tap(find.text('Mumbai → Pune').first);
      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.byType(LoadDetailScreen), findsOneWidget);
      expect(find.text('Load Detail'), findsAtLeastNWidgets(1));
    });

    testWidgets('T-DISC-02: discovery filter and sort interactions remain stable', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);
      _FakeFindLoadsNotifier.searchCalls = 0;
      _FakeFindLoadsNotifier.lastFilters = null;

      final seededLoad = {
        'id': 'load-disc-2',
        'supplier_id': 'supplier-x',
        'origin_city': 'Mumbai',
        'origin_state': 'Maharashtra',
        'dest_city': 'Pune',
        'dest_state': 'Maharashtra',
        'material': 'Steel',
        'weight_tonnes': 24,
        'price': 64000,
        'distance_km': 150,
        'trucks_needed': 1,
        'trucks_booked': 0,
        'required_truck_type': 'open',
        'required_tyres': const [10],
        'advance_percentage': 20,
        'poster_label': 'Fixture Supplier Pvt Ltd',
        'created_at': DateTime.now().toIso8601String(),
        'pickup_date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'trucker',
                'verification_status': 'verified',
                'mobile': '+919999999999',
              },
            ),
            findLoadsProvider.overrideWith(
              (ref) => _FakeFindLoadsNotifier(
                ref,
                seededResults: [seededLoad],
                seededTrucks: const [
                  {
                    'id': 'truck-verified-1',
                    'truck_number': 'MH12AB1234',
                    'body_type': 'open',
                    'tyres': 10,
                    'capacity_tonnes': 25,
                  },
                ],
              ),
            ),
            loadActionProvider.overrideWith((ref) => _FakeBookLoadActionNotifier(ref)),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/find-loads')),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      final context = tester.element(find.byType(FindLoadsScreen));
      final container = ProviderScope.containerOf(context);
      await container.read(findLoadsProvider.notifier).search(
        const LoadFilters(
          material: 'Steel',
          truckType: 'container',
          sortBy: 'price_high',
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(_FakeFindLoadsNotifier.searchCalls, 1);
      expect(_FakeFindLoadsNotifier.lastFilters, isNotNull);
      expect(_FakeFindLoadsNotifier.lastFilters!.material, 'Steel');
      expect(_FakeFindLoadsNotifier.lastFilters!.truckType, 'container');
      expect(_FakeFindLoadsNotifier.lastFilters!.sortBy, 'price_high');
    });

    testWidgets('4.1: Fully onboarded supplier reaches dashboard baseline', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(true),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'supplier',
                'mobile': '+919999999999',
              },
            ),
            myLoadsProvider(false).overrideWith(
              (ref) async => [_fixtureSupplierLoad()],
            ),
            myLoadsProvider(true).overrideWith((ref) async => const []),
          ],
          child: const _RouterHost(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('My Loads'), findsAtLeastNWidgets(1));
      expect(
        find.text('Track active loads, bookings, and fulfillment progress.'),
        findsOneWidget,
      );
    });

    testWidgets('4.3: Trucker trips cycle baseline with detail + start action', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);
      _FakeTripActionNotifier.startTripCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'trucker',
                'mobile': '+919999999999',
              },
            ),
            myTripsProvider(false).overrideWith(
              (ref) async => [
                {
                  'id': 'trip-1',
                  'stage': 'at_pickup',
                  'load': {
                    'id': 'load-1',
                    'origin_city': 'Jaipur',
                    'dest_city': 'Delhi',
                    'material': 'Cement',
                    'weight_tonnes': 16,
                  },
                  'truck': {'truck_number': 'RJ14AA1234'},
                },
              ],
            ),
            myTripsProvider(true).overrideWith((ref) async => const []),
            tripDetailProvider('trip-1').overrideWith(
              (ref) async => {
                'id': 'trip-1',
                'trucker_id': '11111111-1111-1111-1111-111111111111',
                'stage': 'at_pickup',
                'load': {
                  'id': 'load-1',
                  'supplier_id': 'supplier-1',
                  'origin_city': 'Jaipur',
                  'dest_city': 'Delhi',
                  'material': 'Cement',
                  'weight_tonnes': 16,
                  'distance_km': 280,
                  'price': 24000,
                },
                'truck': {'truck_number': 'RJ14AA1234'},
              },
            ),
            tripActionProvider.overrideWith((ref) => _FakeTripActionNotifier(ref)),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/my-trips')),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('My Trips'), findsAtLeastNWidgets(1));
      expect(find.text('Jaipur → Delhi'), findsOneWidget);

      await tester.tap(find.text('Jaipur → Delhi'));
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('Trip Detail'), findsOneWidget);
      expect(find.text('Trip Snapshot'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);

      await tester.ensureVisible(find.text('Start').first);
      await tester.tap(find.text('Start').first);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.ensureVisible(find.text('Start').last);
      await tester.tap(find.text('Start').last);
      await tester.pump(const Duration(milliseconds: 450));

      expect(_FakeTripActionNotifier.startTripCalled, isTrue);
    });

    testWidgets('T-TRIP-04/05: stage update and POD/LR upload action paths', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);
      _FakeTripActionNotifier.markDeliveredCalled = false;
      _FakeTripActionNotifier.uploadLrCalled = false;
      _FakeTripActionNotifier.uploadPodCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'trucker',
                'mobile': '+919999999999',
              },
            ),
            myTripsProvider(false).overrideWith(
              (ref) async => [
                {
                  'id': 'trip-progress-1',
                  'stage': 'in_transit',
                  'load': {
                    'id': 'load-progress-1',
                    'origin_city': 'Jaipur',
                    'dest_city': 'Delhi',
                    'material': 'Cement',
                    'weight_tonnes': 16,
                  },
                  'truck': {'truck_number': 'RJ14AA1234'},
                },
              ],
            ),
            myTripsProvider(true).overrideWith((ref) async => const []),
            tripDetailProvider('trip-progress-1').overrideWith(
              (ref) async => {
                'id': 'trip-progress-1',
                'trucker_id': '11111111-1111-1111-1111-111111111111',
                'stage': 'in_transit',
                'load': {
                  'id': 'load-progress-1',
                  'supplier_id': 'supplier-1',
                  'origin_city': 'Jaipur',
                  'dest_city': 'Delhi',
                  'material': 'Cement',
                  'weight_tonnes': 16,
                  'distance_km': 280,
                  'price': 24000,
                },
                'truck': {'truck_number': 'RJ14AA1234'},
              },
            ),
            tripActionProvider.overrideWith((ref) => _FakeTripActionNotifier(ref)),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/my-trips')),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      await tester.tap(find.text('Jaipur → Delhi'));
      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      final context = tester.element(find.byType(TripDetailScreen));
      final container = ProviderScope.containerOf(context);
      final markOk = await container.read(tripActionProvider.notifier).markDelivered(
        'trip-progress-1',
      );
      final lrOk = await container.read(tripActionProvider.notifier).uploadLr(
        tripId: 'trip-progress-1',
        lrFile: File('lr-fixture.jpg'),
      );
      final podOk = await container.read(tripActionProvider.notifier).uploadPod(
        tripId: 'trip-progress-1',
        podFile: File('pod-fixture.jpg'),
      );
      expect(markOk, isTrue);
      expect(lrOk, isTrue);
      expect(podOk, isTrue);
      expect(_FakeTripActionNotifier.markDeliveredCalled, isTrue);
      expect(_FakeTripActionNotifier.uploadLrCalled, isTrue);
      expect(_FakeTripActionNotifier.uploadPodCalled, isTrue);
    });

    testWidgets('X-BOOK-05 assignment reflected in trucker trips list', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'trucker',
                'mobile': '+919999999999',
              },
            ),
            myTripsProvider(false).overrideWith(
              (ref) async => [
                {
                  'id': 'trip-assigned-1',
                  'stage': 'at_pickup',
                  'load': {
                    'id': 'load-assigned-1',
                    'origin_city': 'Surat',
                    'dest_city': 'Nashik',
                    'material': 'Textile',
                    'weight_tonnes': 12,
                  },
                  'truck': {'truck_number': 'GJ05CC7788'},
                },
              ],
            ),
            myTripsProvider(true).overrideWith((ref) async => const []),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/my-trips')),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('My Trips'), findsAtLeastNWidgets(1));
      expect(find.text('Surat → Nashik'), findsOneWidget);
      expect(find.text('Textile'), findsOneWidget);
      expect(find.text('GJ05CC7788'), findsOneWidget);
    });

    testWidgets('X-CHAT-03: supplier sends message to trucker', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);
      _FakeChatSendNotifier.sentTexts.clear();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'supplier',
                'mobile': '+919999999999',
              },
            ),
            chatInboxProvider.overrideWith(
              (ref) async => [
                {
                  'id': 'conv-1',
                  'load_id': 'load-1',
                  'last_message_text': 'Interested truck available',
                  'last_message_at': DateTime.now().toIso8601String(),
                  'load': {
                    'material': 'Steel',
                    'origin_city': 'Jaipur',
                    'dest_city': 'Delhi',
                  },
                  'trucker': {
                    'profiles': {'full_name': 'Test Trucker'},
                  },
                },
              ],
            ),
            conversationDetailProvider('conv-1').overrideWith(
              (ref) async => {
                'id': 'conv-1',
                'load': {'origin_city': 'Jaipur', 'dest_city': 'Delhi'},
              },
            ),
            chatMessagesProvider('conv-1').overrideWith(
              (ref) => Stream.value([
                {
                  'id': 'msg-1',
                  'sender_id': 'supplier-2',
                  'message_type': 'text',
                  'text_content': 'Ready to dispatch',
                  'created_at': DateTime.now().toIso8601String(),
                  'is_read': true,
                },
              ]),
            ),
            chatSendProvider.overrideWith((ref) => _FakeChatSendNotifier(ref)),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/messages')),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('Messages'), findsAtLeastNWidgets(1));
      expect(find.text('Steel: Jaipur → Delhi'), findsOneWidget);

      await tester.tap(find.text('Steel: Jaipur → Delhi'));
      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.text('Jaipur → Delhi'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Please share ETA');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byIcon(Icons.send).last);
      await tester.pump(const Duration(milliseconds: 350));

      expect(_FakeChatSendNotifier.sentTexts, contains('Please share ETA'));
    });

    testWidgets('X-CHAT-02: open specific supplier conversation from load context', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'supplier',
                'mobile': '+919999999999',
              },
            ),
            chatInboxProvider.overrideWith(
              (ref) async => [
                {
                  'id': 'conv-load-1a',
                  'load_id': 'load-g1',
                  'last_message_text': 'Trucker A latest update',
                  'last_message_at': DateTime.now().toIso8601String(),
                  'load': {
                    'material': 'Steel',
                    'origin_city': 'Jaipur',
                    'dest_city': 'Delhi',
                  },
                  'trucker': {
                    'profiles': {'full_name': 'Trucker A'},
                  },
                },
                {
                  'id': 'conv-load-1b',
                  'load_id': 'load-g1',
                  'last_message_text': 'Trucker B latest update',
                  'last_message_at': DateTime.now().toIso8601String(),
                  'load': {
                    'material': 'Steel',
                    'origin_city': 'Jaipur',
                    'dest_city': 'Delhi',
                  },
                  'trucker': {
                    'profiles': {'full_name': 'Trucker B'},
                  },
                },
              ],
            ),
            conversationDetailProvider('conv-load-1a').overrideWith(
              (ref) async => {
                'id': 'conv-load-1a',
                'load': {'origin_city': 'Jaipur', 'dest_city': 'Delhi'},
              },
            ),
            conversationDetailProvider('conv-load-1b').overrideWith(
              (ref) async => {
                'id': 'conv-load-1b',
                'load': {'origin_city': 'Jaipur', 'dest_city': 'Delhi'},
              },
            ),
            chatMessagesProvider('conv-load-1a').overrideWith(
              (ref) => Stream.value([
                {
                  'id': 'msg-a1',
                  'sender_id': 'trucker-a',
                  'message_type': 'text',
                  'text_content': 'Conversation A payload',
                  'created_at': DateTime.now().toIso8601String(),
                  'is_read': true,
                },
              ]),
            ),
            chatMessagesProvider('conv-load-1b').overrideWith(
              (ref) => Stream.value([
                {
                  'id': 'msg-b1',
                  'sender_id': 'trucker-b',
                  'message_type': 'text',
                  'text_content': 'Conversation B payload',
                  'created_at': DateTime.now().toIso8601String(),
                  'is_read': true,
                },
              ]),
            ),
            unreadCountsProvider.overrideWith(
              (ref) async => const {'conv-load-1a': 1, 'conv-load-1b': 2},
            ),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/messages')),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      expect(find.text('Steel: Jaipur → Delhi'), findsOneWidget);
      await tester.tap(find.text('Steel: Jaipur → Delhi'));
      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('Trucker A'), findsOneWidget);
      expect(find.text('Trucker B'), findsOneWidget);

      await tester.tap(find.text('Trucker B'));
      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('Jaipur → Delhi'), findsOneWidget);
      expect(find.text('Conversation B payload'), findsOneWidget);
    });

    testWidgets('X-CHAT-01: conversation list opens for trucker persona', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'trucker',
                'mobile': '+919999999999',
              },
            ),
            chatInboxProvider.overrideWith(
              (ref) async => [
                {
                  'id': 'conv-t1',
                  'load_id': 'load-t1',
                  'last_message_text': 'Can you pick up by 5 PM?',
                  'last_message_at': DateTime.now().toIso8601String(),
                  'load': {
                    'origin_city': 'Kota',
                    'dest_city': 'Noida',
                  },
                  'supplier': {
                    'profiles': {'full_name': 'Supplier Ops Team'},
                  },
                },
              ],
            ),
            unreadCountsProvider.overrideWith((ref) async => const {'conv-t1': 1}),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/messages')),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('Messages'), findsAtLeastNWidgets(1));
      expect(find.text('Supplier Ops Team'), findsOneWidget);
      expect(find.text('Kota → Noida'), findsOneWidget);
    });

    testWidgets('X-CHAT-01: conversation list opens for supplier persona', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'supplier',
                'mobile': '+919999999999',
              },
            ),
            chatInboxProvider.overrideWith(
              (ref) async => [
                {
                  'id': 'conv-s1',
                  'load_id': 'load-s1',
                  'last_message_text': 'Truck available for evening pickup',
                  'last_message_at': DateTime.now().toIso8601String(),
                  'load': {
                    'material': 'Cement',
                    'origin_city': 'Indore',
                    'dest_city': 'Bhopal',
                  },
                  'trucker': {
                    'profiles': {'full_name': 'Arjun Transport'},
                  },
                },
              ],
            ),
            unreadCountsProvider.overrideWith((ref) async => const {'conv-s1': 2}),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/messages')),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('Messages'), findsAtLeastNWidgets(1));
      expect(find.text('Cement: Indore → Bhopal'), findsOneWidget);
    });

    testWidgets('X-CHAT-04: trucker sends message to supplier', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);
      _FakeChatSendNotifier.sentTexts.clear();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'trucker',
                'mobile': '+919999999999',
              },
            ),
            chatInboxProvider.overrideWith(
              (ref) async => [
                {
                  'id': 'conv-trucker-send-1',
                  'load_id': 'load-trucker-send-1',
                  'last_message_text': 'Share your arrival slot',
                  'last_message_at': DateTime.now().toIso8601String(),
                  'load': {
                    'origin_city': 'Agra',
                    'dest_city': 'Lucknow',
                  },
                  'supplier': {
                    'profiles': {'full_name': 'North Hub Supplier'},
                  },
                },
              ],
            ),
            conversationDetailProvider('conv-trucker-send-1').overrideWith(
              (ref) async => {
                'id': 'conv-trucker-send-1',
                'load': {'origin_city': 'Agra', 'dest_city': 'Lucknow'},
              },
            ),
            chatMessagesProvider('conv-trucker-send-1').overrideWith(
              (ref) => Stream.value([
                {
                  'id': 'msg-tr1',
                  'sender_id': 'supplier-tr1',
                  'message_type': 'text',
                  'text_content': 'Confirming pickup window soon',
                  'created_at': DateTime.now().toIso8601String(),
                  'is_read': true,
                },
              ]),
            ),
            chatSendProvider.overrideWith((ref) => _FakeChatSendNotifier(ref)),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/messages')),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      expect(find.text('North Hub Supplier'), findsOneWidget);
      await tester.tap(find.text('North Hub Supplier'));
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      expect(find.text('Agra → Lucknow'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Truck reached Agra yard');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byIcon(Icons.send).last);
      await tester.pump(const Duration(milliseconds: 350));

      expect(_FakeChatSendNotifier.sentTexts, contains('Truck reached Agra yard'));
    });

    testWidgets('X-CHAT-05: unread count updates after read-state refresh', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);
      final unreadState = ValueNotifier<Map<String, int>>(const {'conv-read-1': 3});
      addTearDown(unreadState.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'trucker',
                'mobile': '+919999999999',
              },
            ),
            chatInboxProvider.overrideWith(
              (ref) async => [
                {
                  'id': 'conv-read-1',
                  'load_id': 'load-read-1',
                  'last_message_text': 'Unread indicator sample',
                  'last_message_at': DateTime.now().toIso8601String(),
                  'load': {
                    'origin_city': 'Nagpur',
                    'dest_city': 'Pune',
                  },
                  'supplier': {
                    'profiles': {'full_name': 'Unread Supplier'},
                  },
                },
              ],
            ),
            unreadCountsProvider.overrideWith((ref) async => unreadState.value),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/messages')),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      expect(find.text('Unread Supplier'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      unreadState.value = const {'conv-read-1': 0};
      final context = tester.element(find.byType(ChatListScreen));
      final container = ProviderScope.containerOf(context);
      container.invalidate(unreadCountsProvider);
      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('3'), findsNothing);
    });

    testWidgets('X-CHAT-06: message persists after reopening conversation', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);

      final overrides = [
        supabaseConfiguredProvider.overrideWithValue(false),
        authSessionProvider.overrideWith(
          (ref) => Stream.value(_signedInAuthState()),
        ),
        unreadNotificationsCountProvider.overrideWith((ref) async => 0),
        userProfileProvider.overrideWith(
          (ref) async => <String, dynamic>{
            'user_role_type': 'trucker',
            'mobile': '+919999999999',
          },
        ),
        chatInboxProvider.overrideWith(
          (ref) async => [
            {
              'id': 'conv-persist-1',
              'load_id': 'load-persist-1',
              'last_message_text': 'Persistent thread marker',
              'last_message_at': DateTime.now().toIso8601String(),
              'load': {
                'origin_city': 'Chennai',
                'dest_city': 'Bengaluru',
              },
              'supplier': {
                'profiles': {'full_name': 'Persist Supplier'},
              },
            },
          ],
        ),
        conversationDetailProvider('conv-persist-1').overrideWith(
          (ref) async => {
            'id': 'conv-persist-1',
            'load': {'origin_city': 'Chennai', 'dest_city': 'Bengaluru'},
          },
        ),
        chatMessagesProvider('conv-persist-1').overrideWith(
          (ref) => Stream.value([
            {
              'id': 'msg-persist-1',
              'sender_id': 'supplier-persist-1',
              'message_type': 'text',
              'text_content': 'Persistent thread marker',
              'created_at': DateTime.now().toIso8601String(),
              'is_read': true,
            },
          ]),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: _ShellRouterHost(router: _buildShellRouter('/messages')),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      await tester.tap(find.text('Persist Supplier'));
      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      expect(find.text('Persistent thread marker'), findsAtLeastNWidgets(1));

      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      await tester.tap(find.text('Persist Supplier'));
      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      expect(find.text('Persistent thread marker'), findsAtLeastNWidgets(1));
    });

    testWidgets('X-BOT-01: bot entry point visible and accessible', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'trucker',
                'mobile': '+919999999999',
              },
            ),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/bot-chat')),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('TranZfort Bot'), findsOneWidget);
      expect(find.text('Transport assistant'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('X-BOT-02: send basic text query to bot', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'trucker',
                'mobile': '+919999999999',
              },
            ),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/bot-chat')),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      await tester.enterText(find.byType(TextField).last, 'load dhundho');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byIcon(Icons.send).last);
      await tester.pumpAndSettle(const Duration(milliseconds: 1200));

      expect(find.text('load dhundho'), findsOneWidget);
      expect(find.text('Kahan se? (Origin city batayein)'), findsOneWidget);
    });

    testWidgets('X-BOT-02A: microphone allow path submits voice query', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);
      _FakeBotSttAllowNotifier.startCalls = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'trucker',
                'mobile': '+919999999999',
              },
            ),
            botSttProvider.overrideWith((ref) => _FakeBotSttAllowNotifier()),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/bot-chat')),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      await tester.tap(find.byIcon(Icons.mic).last);
      await tester.pumpAndSettle(const Duration(milliseconds: 1200));

      expect(_FakeBotSttAllowNotifier.startCalls, 1);
      expect(find.text('trip status'), findsAtLeastNWidgets(1));
    });

    testWidgets('X-BOT-02B: microphone denied path falls back to text input', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);
      _FakeBotSttDeniedNotifier.startCalls = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'trucker',
                'mobile': '+919999999999',
              },
            ),
            botSttProvider.overrideWith((ref) => _FakeBotSttDeniedNotifier()),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/bot-chat')),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      await tester.tap(find.byIcon(Icons.mic).last);
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      expect(_FakeBotSttDeniedNotifier.startCalls, 1);

      await tester.enterText(find.byType(TextField).last, 'help');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byIcon(Icons.send).last);
      await tester.pumpAndSettle(const Duration(milliseconds: 1200));

      expect(find.text('help'), findsOneWidget);
      expect(
        find.textContaining('Main aapki load dhundhne'),
        findsOneWidget,
      );
    });

    testWidgets('X-BOT-03/05: backend fallback is safe and leaks no raw exception text', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'supplier',
                'mobile': '+919999999999',
              },
            ),
            basicBotServiceProvider.overrideWith((ref) => _FakeFallbackBotService(ref)),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/bot-chat')),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      await tester.enterText(find.byType(TextField).last, 'status');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byIcon(Icons.send).last);
      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(
        find.text('Service temporarily unavailable. Please try again.'),
        findsAtLeastNWidgets(1),
      );
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('StackTrace'), findsNothing);
    });

    testWidgets('X-BOT-04: bot action suggestion deep-links to target route', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'trucker',
                'mobile': '+919999999999',
              },
            ),
            botChatProvider.overrideWith((ref) => _SeededBotActionNotifier()),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/bot-chat')),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      await tester.tap(find.text('Open Add Truck'));
      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('Add truck form'), findsOneWidget);
    });

    testWidgets('X-NOTIF-01: load/trip/chat events create visible notifications', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'supplier',
                'mobile': '+919999999999',
              },
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 3),
            notificationsProvider.overrideWith(
              (ref) async => [
                {
                  'id': 'notif-load-1',
                  'title': 'New booking request',
                  'body': 'Load event notification',
                  'is_read': false,
                  'created_at': DateTime.now().toIso8601String(),
                  'data': {'load_id': 'load-1'},
                },
                {
                  'id': 'notif-trip-1',
                  'title': 'Trip stage updated',
                  'body': 'Trip event notification',
                  'is_read': false,
                  'created_at': DateTime.now().toIso8601String(),
                  'data': {'trip_id': 'trip-1'},
                },
                {
                  'id': 'notif-chat-1',
                  'title': 'New chat message',
                  'body': 'Chat event notification',
                  'is_read': false,
                  'created_at': DateTime.now().toIso8601String(),
                  'data': {'conversation_id': 'conv-1'},
                },
              ],
            ),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/notifications')),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      expect(find.text('New booking request'), findsOneWidget);
      expect(find.text('Trip stage updated'), findsOneWidget);
      expect(find.text('New chat message'), findsOneWidget);
    });

    testWidgets('X-NOTIF-02: notification taps deep-link to correct routes', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'supplier',
                'mobile': '+919999999999',
              },
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 3),
            notificationsProvider.overrideWith(
              (ref) async => [
                {
                  'id': 'notif-load-2',
                  'title': 'Load deep-link',
                  'body': 'Open load detail',
                  'is_read': false,
                  'created_at': DateTime.now().toIso8601String(),
                  'data': {'load_id': 'load-1'},
                },
                {
                  'id': 'notif-trip-2',
                  'title': 'Trip deep-link',
                  'body': 'Open trip detail',
                  'is_read': false,
                  'created_at': DateTime.now().toIso8601String(),
                  'data': {'trip_id': 'trip-1'},
                },
                {
                  'id': 'notif-chat-2',
                  'title': 'Chat deep-link',
                  'body': 'Open conversation',
                  'is_read': false,
                  'created_at': DateTime.now().toIso8601String(),
                  'data': {'conversation_id': 'conv-1'},
                },
              ],
            ),
            loadDetailProvider('load-1').overrideWith(
              (ref) async => {
                'load': {
                  'id': 'load-1',
                  'origin_city': 'Mumbai',
                  'dest_city': 'Pune',
                  'material': 'Steel',
                  'weight_tonnes': 24,
                  'price': 64000,
                  'supplier_id': 'supplier-1',
                },
                'children': const <Map<String, dynamic>>[],
                'trip_cost': const <String, dynamic>{},
              },
            ),
            tripDetailProvider('trip-1').overrideWith(
              (ref) async => {
                'id': 'trip-1',
                'trucker_id': '11111111-1111-1111-1111-111111111111',
                'stage': 'at_pickup',
                'load': {
                  'id': 'load-1',
                  'supplier_id': 'supplier-1',
                  'origin_city': 'Jaipur',
                  'dest_city': 'Delhi',
                  'material': 'Cement',
                  'weight_tonnes': 16,
                  'distance_km': 280,
                  'price': 24000,
                },
                'truck': {'truck_number': 'RJ14AA1234'},
              },
            ),
            conversationDetailProvider('conv-1').overrideWith(
              (ref) async => {
                'id': 'conv-1',
                'load': {'origin_city': 'Jaipur', 'dest_city': 'Delhi'},
              },
            ),
            chatMessagesProvider('conv-1').overrideWith(
              (ref) => Stream.value([
                {
                  'id': 'msg-1',
                  'sender_id': 'supplier-2',
                  'message_type': 'text',
                  'text_content': 'Route deep-link chat payload',
                  'created_at': DateTime.now().toIso8601String(),
                  'is_read': true,
                },
              ]),
            ),
            notificationActionProvider.overrideWith(
              (ref) => _FakeNotificationActionNotifier(ref),
            ),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/notifications')),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 900));

      await tester.tap(find.text('Load deep-link'));
      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      expect(find.text('Load Detail'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      await tester.tap(find.text('Trip deep-link'));
      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      expect(find.text('Trip Detail'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      await tester.tap(find.text('Chat deep-link'));
      await tester.pumpAndSettle(const Duration(milliseconds: 900));
      expect(find.text('Route deep-link chat payload'), findsOneWidget);
    });

    testWidgets('X-NOTIF-03: mark-read and mark-all actions update notification state', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);
      _FakeNotificationActionNotifier.markAllCalled = false;
      _FakeNotificationActionNotifier.markedReadIds.clear();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 1),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'supplier',
                'mobile': '+919999999999',
              },
            ),
            notificationsProvider.overrideWith(
              (ref) async => [
                {
                  'id': 'notif-1',
                  'title': 'Booking pending approval',
                  'body': 'A trucker has requested booking.',
                  'is_read': false,
                  'created_at': DateTime.now().toIso8601String(),
                  'data': {'load_id': 'load-1'},
                },
              ],
            ),
            notificationActionProvider.overrideWith(
              (ref) => _FakeNotificationActionNotifier(ref),
            ),
            loadDetailProvider('load-1').overrideWith(
              (ref) async => {
                'load': {
                  'id': 'load-1',
                  'origin_city': 'Mumbai',
                  'dest_city': 'Pune',
                  'material': 'Steel',
                  'weight_tonnes': 24,
                  'price': 64000,
                  'supplier_id': 'supplier-1',
                },
                'children': const <Map<String, dynamic>>[],
                'trip_cost': const <String, dynamic>{},
              },
            ),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/notifications')),
        ),
      );

      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Booking pending approval'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pump(const Duration(milliseconds: 250));
      expect(_FakeNotificationActionNotifier.markAllCalled, isTrue);

      await tester.tap(find.text('Booking pending approval'));
      await tester.pump(const Duration(milliseconds: 900));
      expect(_FakeNotificationActionNotifier.markedReadIds, contains('notif-1'));
      expect(find.text('Load Detail'), findsOneWidget);
    });

    testWidgets('4.6: Settings flow baseline with toggles and payout navigation', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'supplier',
                'mobile': '+919999999999',
              },
            ),
            payoutProfileProvider.overrideWith(
              (ref) async => {
                'account_holder_name': 'Fixture Supplier',
                'account_number_last4': '4321',
                'ifsc_code': 'SBIN0001234',
                'status': 'verified',
              },
            ),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/settings')),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 1200));
      expect(find.text('Settings'), findsAtLeastNWidgets(1));
      expect(find.text('Voice & notifications'), findsOneWidget);

      await tester.ensureVisible(find.text('TTS mute').first);
      await tester.tap(find.text('TTS mute').first);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.ensureVisible(find.text('Push notifications').first);
      await tester.tap(find.text('Push notifications').first);
      await tester.pump(const Duration(milliseconds: 350));

      final payoutProfileFinder = find.textContaining('Payout profile');
      expect(payoutProfileFinder, findsAtLeastNWidgets(1));
      await tester.ensureVisible(payoutProfileFinder.first);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(payoutProfileFinder.first);
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('Payout Profile'), findsOneWidget);
    });

    testWidgets('4.7: Fleet flow baseline renders truck data and add action', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'trucker',
                'mobile': '+919999999999',
              },
            ),
            fleetProvider.overrideWith(
              (ref) async => [
                {
                  'id': 'truck-1',
                  'truck_number': 'MH12AB1234',
                  'body_type': 'open',
                  'tyres': 10,
                  'capacity_tonnes': 21,
                  'status': 'rejected',
                  'rejection_reason': 'RC image blurred',
                  'truck_model': {'make': 'Tata', 'model': 'LPT 1618'},
                },
              ],
            ),
            payoutProfileProvider.overrideWith(
              (ref) async => {
                'account_holder_name': 'Fixture Trucker',
                'account_number_last4': '1122',
                'ifsc_code': 'HDFC0001010',
                'status': 'verified',
              },
            ),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/my-fleet')),
        ),
      );

      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('My Fleet'), findsAtLeastNWidgets(1));
      expect(find.text('MH12AB1234'), findsOneWidget);
      expect(find.textContaining('Rejection reason: RC image blurred'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Add truck form'), findsOneWidget);
    });

    testWidgets('4.8: Payout profile flow baseline renders fixture payout data', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            payoutProfileProvider.overrideWith(
              (ref) async => {
                'account_holder_name': 'Fixture Trucker',
                'account_number_last4': '1122',
                'ifsc_code': 'HDFC0001010',
                'status': 'verified',
              },
            ),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/payout-profile')),
        ),
      );

      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('Payout Profile'), findsOneWidget);
      expect(find.text('Fixture Trucker'), findsOneWidget);
      expect(find.text('1122'), findsOneWidget);
      expect(find.text('HDFC0001010'), findsOneWidget);
      expect(find.text('verified'), findsOneWidget);
    });
  });
}
