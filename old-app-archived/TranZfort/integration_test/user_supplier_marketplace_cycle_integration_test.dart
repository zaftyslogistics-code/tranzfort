import 'dart:async';

import 'package:app/src/core/config/supabase_config.dart';
import 'package:app/src/features/marketplace/presentation/load_detail_screen.dart';
import 'package:app/src/features/marketplace/presentation/my_loads_screen.dart';
import 'package:app/src/features/marketplace/providers/marketplace_providers.dart';
import 'package:app/src/features/notifications/providers/notifications_provider.dart';
import 'package:app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _SupplierMarketplaceRouterHost extends StatelessWidget {
  const _SupplierMarketplaceRouterHost({required this.router});

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

class _FakeLoadActionNotifier extends LoadDetailActionNotifier {
  _FakeLoadActionNotifier(super.ref);

  static final approvedChildLoadIds = <String>[];

  @override
  Future<bool> approveBooking(String childLoadId, String parentLoadId) async {
    approvedChildLoadIds.add(childLoadId);
    state = const AsyncData(null);
    return true;
  }
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/my-loads',
    routes: [
      GoRoute(
        path: '/my-loads',
        builder: (context, state) => const MyLoadsScreen(),
      ),
      GoRoute(
        path: '/load-detail/:loadId',
        builder: (context, state) {
          final loadId = state.pathParameters['loadId'] ?? '';
          return LoadDetailScreen(loadId: loadId);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(
        path: '/messages',
        builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(
        path: '/post-load',
        builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
      ),
    ],
  );
}

AuthState _signedInAuthState() {
  final session = Session.fromJson({
    'access_token': 'supplier-access-token',
    'token_type': 'bearer',
    'refresh_token': 'supplier-refresh-token',
    'expires_in': 3600,
    'user': {
      'id': 'supplier-1111-1111-1111-111111111111',
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'supplier.fixture@tranzfort.app',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'created_at': '2026-02-27T00:00:00Z',
    },
  });

  return AuthState(AuthChangeEvent.signedIn, session);
}

Map<String, dynamic> _fixtureParentLoad() {
  return {
    'id': 'load-1',
    'parent_load_id': null,
    'supplier_id': 'supplier-1111-1111-1111-111111111111',
    'origin_city': 'Mumbai',
    'origin_state': 'Maharashtra',
    'dest_city': 'Pune',
    'dest_state': 'Maharashtra',
    'material': 'Steel',
    'weight_tonnes': 24,
    'price': 64000,
    'distance_km': 150,
    'trucks_needed': 2,
    'trucks_booked': 1,
    'status': 'active',
  };
}

Map<String, dynamic> _fixtureLoadDetail() {
  return {
    'load': _fixtureParentLoad(),
    'children': [
      {
        'id': 'child-1',
        'status': 'pending_approval',
        'booking_truck_snapshot': {
          'truck_number': 'MH12AB1234',
          'body_type': 'open',
          'tyres': 10,
          'capacity_tonnes': 25,
        },
      },
    ],
    'trip_cost': {
      'diesel': 5200,
      'toll': 900,
      'total': 6100,
      'mileage': 3.8,
    },
  };
}

void _setLargeViewport(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 3.0;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('User supplier marketplace integration tests', () {
    testWidgets('X-BOOK-03/04: supplier sees booking request and approves it', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);
      _FakeLoadActionNotifier.approvedChildLoadIds.clear();

      final authController = StreamController<AuthState>.broadcast();
      authController.add(_signedInAuthState());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith((ref) => authController.stream),
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            myLoadsProvider(false).overrideWith(
              (ref) async => [_fixtureParentLoad()],
            ),
            myLoadsProvider(true).overrideWith((ref) async => const []),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'supplier',
                'mobile': '+919999999999',
              },
            ),
            loadDetailProvider('load-1').overrideWith(
              (ref) async => _fixtureLoadDetail(),
            ),
            loadDetailActionProvider.overrideWith((ref) => _FakeLoadActionNotifier(ref)),
          ],
          child: _SupplierMarketplaceRouterHost(router: _buildRouter()),
        ),
      );

      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('My Loads'), findsAtLeastNWidgets(1));
      expect(find.text('Mumbai → Pune'), findsOneWidget);
      expect(find.text('1/2 trucks booked'), findsOneWidget);

      await tester.tap(find.text('Mumbai → Pune'));
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('Load Detail'), findsOneWidget);
      expect(find.text('Pending Approval'), findsOneWidget);
      expect(find.text('1'), findsAtLeastNWidgets(1));
      expect(find.text('Approve'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Approve'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Approve'));
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.text('Booking approved'), findsOneWidget);
      expect(_FakeLoadActionNotifier.approvedChildLoadIds, contains('child-1'));

      await authController.close();
    });
  });
}
