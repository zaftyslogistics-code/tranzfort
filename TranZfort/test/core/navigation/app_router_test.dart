import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tranzfort/src/core/config/supabase_config.dart';
import 'package:tranzfort/src/core/navigation/app_router.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/auth/data/auth_repository.dart';
import 'package:tranzfort/src/features/communication/data/chat_repository.dart';
import 'package:tranzfort/src/features/communication/providers/chat_providers.dart';
import 'package:tranzfort/src/features/notifications/providers/notification_providers.dart';
import 'package:tranzfort/src/features/shell/presentation/supplier_shell_screens.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_trip_repository.dart';
import 'package:tranzfort/src/features/supplier/providers/supplier_trips_provider.dart';
import 'package:tranzfort/src/features/verification/data/verification_repository.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

class _NoopChatBackend implements ChatBackend {
  const _NoopChatBackend();

  @override
  Future<List<Map<String, dynamic>>> fetchConversations({required String userId, required AppUserRole role}) async =>
      const <Map<String, dynamic>>[];

  @override
  Stream<List<Map<String, dynamic>>> watchConversations({required String userId, required AppUserRole role}) =>
      const Stream<List<Map<String, dynamic>>>.empty();

  @override
  Future<List<Map<String, dynamic>>> fetchMessages({required String conversationId}) async => const <Map<String, dynamic>>[];

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
  Future<String> sendMessage({
    required String conversationId,
    required ChatMessageType type,
    String? messageId,
    String? textBody,
    String? attachmentPath,
    Map<String, dynamic>? structuredPayload,
  }) async => 'message-1';

  @override
  Future<void> markMessagesRead({required String conversationId, required String readerId}) async {}

  @override
  Future<int> fetchUnreadConversationCount() async => 0;
}

class _TestInboxController extends InboxController {
  _TestInboxController(InboxState initialState)
      : super(
          ChatRepository(
            const _NoopChatBackend(),
            () => 'supplier-1',
            () => AppUserRole.supplier,
          ),
        ) {
    state = initialState;
  }

  @override
  Future<void> load() async {}
}

class _FakeVerificationBackend implements VerificationBackend {
  @override
  Future<int> countApprovedTrucks(String userId) async => 0;

  @override
  Future<int> countVerificationReadyTrucks(String userId) async => 0;

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    return <String, dynamic>{
      'id': userId,
      'user_role_type': 'supplier',
      'verification_status': 'unverified',
    };
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String userId) async {
    return <String, dynamic>{
      'company_name': 'Amit Logistics',
      'business_licence_number': 'BL-42',
    };
  }

  @override
  Future<String> resubmitVerificationCase() async => 'case-2';

  @override
  Future<String> submitVerificationForReview() async => 'case-1';

  @override
  Future<void> updateProfileFields(String userId, Map<String, dynamic> values) async {}

  @override
  Future<void> updateSupplierFields(String userId, Map<String, dynamic> values) async {}
}

class _NoopSupplierTripsBackend implements SupplierTripsBackend {
  @override
  Future<List<Map<String, dynamic>>> fetchTrips({required String supplierId, required List<String> stages}) async =>
      const <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({required String supplierId, required String tripId}) async => null;

  @override
  Future<Map<String, dynamic>?> fetchTruckerProfile(String truckerId) async => null;

  @override
  Future<Map<String, dynamic>?> fetchOwnRating({required String reviewerId, required String loadId}) async => null;

  @override
  Future<void> submitRating({required String loadId, required int score, String? comment}) async {}

  @override
  Future<String?> createProofSignedUrl(String path) async => null;

  @override
  Future<void> cancelTrip(String tripId) async {}

  @override
  Future<Map<String, dynamic>?> fetchTripDisputeSummary({required String tripId}) async => null;

  @override
  Future<void> confirmTripDelivery(String tripId) async {}

  @override
  Future<String> raiseTripDispute({
    required String tripId,
    required String category,
    required String reason,
    String? attachmentPath,
  }) async => 'support-ticket-1';
}

class _TestSupplierTripsController extends SupplierTripsController {
  _TestSupplierTripsController(SupplierTripsState initialState)
      : super(
          SupplierTripsRepository(_NoopSupplierTripsBackend(), () => 'supplier-1'),
        ) {
    state = initialState;
  }

  @override
  Future<void> load() async {}

  @override
  Future<void> selectTab(SupplierTripsTab tab) async {
    state = state.copyWith(selectedTab: tab);
  }
}

const _supplierAuthState = AuthStateSnapshot(
  hasSession: true,
  role: AppUserRole.supplier,
  isBanned: false,
  isDeactivated: false,
  isProfileComplete: true,
  isResolved: true,
  profile: UserProfile(
    id: 'supplier-1',
    fullName: 'Amit Supplier',
    mobile: '+919999999999',
    email: 'amit@example.com',
    roleType: 'supplier',
    isBanned: false,
    accountDeletionStatus: 'active',
    trustSafetyStatus: 'normal',
  ),
);

const _restrictedTruckerAuthState = AuthStateSnapshot(
  hasSession: true,
  role: AppUserRole.trucker,
  isBanned: true,
  isDeactivated: false,
  isProfileComplete: true,
  isResolved: true,
  profile: UserProfile(
    id: 'trucker-1',
    fullName: 'Ravi Trucker',
    mobile: '+919999999999',
    email: 'ravi@example.com',
    roleType: 'trucker',
    isBanned: true,
    accountDeletionStatus: 'active',
    trustSafetyStatus: 'suspended',
  ),
);

const _deactivatedTruckerAuthState = AuthStateSnapshot(
  hasSession: true,
  role: AppUserRole.trucker,
  isBanned: false,
  isDeactivated: true,
  isProfileComplete: true,
  isResolved: true,
  profile: UserProfile(
    id: 'trucker-1',
    fullName: 'Ravi Trucker',
    mobile: '+919999999999',
    email: 'ravi@example.com',
    roleType: 'trucker',
    isBanned: false,
    accountDeletionStatus: 'requested',
    trustSafetyStatus: 'normal',
  ),
);

const _truckerAuthState = AuthStateSnapshot(
  hasSession: true,
  role: AppUserRole.trucker,
  isBanned: false,
  isDeactivated: false,
  isProfileComplete: true,
  isResolved: true,
  profile: UserProfile(
    id: 'trucker-1',
    fullName: 'Ravi Trucker',
    mobile: '+919999999999',
    email: 'ravi@example.com',
    roleType: 'trucker',
    isBanned: false,
    accountDeletionStatus: 'active',
    trustSafetyStatus: 'normal',
  ),
);

const _restrictedSupplierAuthState = AuthStateSnapshot(
  hasSession: true,
  role: AppUserRole.supplier,
  isBanned: true,
  isDeactivated: false,
  isProfileComplete: true,
  isResolved: true,
  profile: UserProfile(
    id: 'supplier-1',
    fullName: 'Amit Supplier',
    mobile: '+919999999999',
    email: 'amit@example.com',
    roleType: 'supplier',
    isBanned: true,
    accountDeletionStatus: 'active',
    trustSafetyStatus: 'suspended',
  ),
);

const _deactivatedSupplierAuthState = AuthStateSnapshot(
  hasSession: true,
  role: AppUserRole.supplier,
  isBanned: false,
  isDeactivated: true,
  isProfileComplete: true,
  isResolved: true,
  profile: UserProfile(
    id: 'supplier-1',
    fullName: 'Amit Supplier',
    mobile: '+919999999999',
    email: 'amit@example.com',
    roleType: 'supplier',
    isBanned: false,
    accountDeletionStatus: 'requested',
    trustSafetyStatus: 'normal',
  ),
);

ProviderContainer _buildSupplierRouterContainer({AuthStateSnapshot authState = _supplierAuthState}) {
  return ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(
        const AppConfigState(
          supabaseConfig: SupabaseConfig(
            url: 'https://example.supabase.co',
            anonKey: 'anon-key',
            googleWebClientId: 'google-web-client-id',
          ),
        ),
      ),
      authStateProvider.overrideWith((ref) async* {
        yield authState;
      }),
      currentAuthStateProvider.overrideWithValue(authState),
      currentProfileProvider.overrideWith((ref) => AsyncValue<UserProfile?>.data(authState.profile)),
      unreadNotificationCountProvider.overrideWith((ref) => 0),
      inboxProvider.overrideWith((ref) => _TestInboxController(InboxState.initial().copyWith(isLoading: false))),
      supplierTripsProvider.overrideWith(
        (ref) => _TestSupplierTripsController(
          SupplierTripsState.initial().copyWith(
            isLoading: false,
            trips: const <SupplierTrip>[],
          ),
        ),
      ),
      verificationRepositoryProvider.overrideWith(
        (ref) => VerificationRepository(_FakeVerificationBackend(), () => 'supplier-1'),
      ),
    ],
  );
}

ProviderContainer _buildTruckerRouterContainer({AuthStateSnapshot authState = _truckerAuthState}) {
  return ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(
        const AppConfigState(
          supabaseConfig: SupabaseConfig(
            url: 'https://example.supabase.co',
            anonKey: 'anon-key',
            googleWebClientId: 'google-web-client-id',
          ),
        ),
      ),
      authStateProvider.overrideWith((ref) async* {
        yield authState;
      }),
      currentAuthStateProvider.overrideWithValue(authState),
      currentProfileProvider.overrideWith((ref) => AsyncValue<UserProfile?>.data(authState.profile)),
      unreadNotificationCountProvider.overrideWith((ref) => 0),
      inboxProvider.overrideWith((ref) => _TestInboxController(InboxState.initial().copyWith(isLoading: false))),
      verificationRepositoryProvider.overrideWith(
        (ref) => VerificationRepository(_FakeVerificationBackend(), () => 'trucker-1'),
      ),
    ],
  );
}

Future<GoRouter> _pumpSupplierRouterApp(WidgetTester tester, ProviderContainer container) async {
  final router = container.read(appRouterProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));

  return router;
}

Future<void> _pumpUntilPath(WidgetTester tester, GoRouter router, String expectedPath) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    if (router.routeInformationProvider.value.uri.path == expectedPath) {
      return;
    }
  }
}

void main() {
  testWidgets('supplier generic verification route redirects to supplier verification path', (tester) async {
    final container = _buildSupplierRouterContainer();
    addTearDown(container.dispose);

    final router = await _pumpSupplierRouterApp(tester, container);

    router.go(AppRoutes.verificationPath);
    await _pumpUntilPath(tester, router, AppRoutes.supplierVerificationPath);

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.supplierVerificationPath);
  });

  testWidgets('trucker generic verification route redirects to trucker verification path', (tester) async {
    final container = _buildTruckerRouterContainer();
    addTearDown(container.dispose);

    final router = await _pumpSupplierRouterApp(tester, container);

    router.go(AppRoutes.verificationPath);
    await _pumpUntilPath(tester, router, AppRoutes.truckerVerificationPath);

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.truckerVerificationPath);
  });

  testWidgets('legacy phone auth route is not part of the active public auth surface', (tester) async {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfigState(
            supabaseConfig: SupabaseConfig(
              url: 'https://example.supabase.co',
              anonKey: 'anon-key',
              googleWebClientId: 'google-web-client-id',
            ),
          ),
        ),
        authStateProvider.overrideWith((ref) async* {
          yield const AuthStateSnapshot(
            hasSession: false,
            role: AppUserRole.unknown,
            isBanned: false,
            isDeactivated: false,
            isProfileComplete: false,
            isResolved: true,
            profile: null,
          );
        }),
        currentAuthStateProvider.overrideWithValue(
          const AuthStateSnapshot(
            hasSession: false,
            role: AppUserRole.unknown,
            isBanned: false,
            isDeactivated: false,
            isProfileComplete: false,
            isResolved: true,
            profile: null,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = await _pumpSupplierRouterApp(tester, container);

    router.go('/auth/phone');
    await _pumpUntilPath(tester, router, AppRoutes.authPath);

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.authPath);
  });

  testWidgets('deactivated authenticated supplier is redirected from auth to delete account path', (tester) async {
    final container = _buildSupplierRouterContainer(authState: _deactivatedSupplierAuthState);
    addTearDown(container.dispose);

    final router = await _pumpSupplierRouterApp(tester, container);

    router.go(AppRoutes.authPath);
    await _pumpUntilPath(tester, router, AppRoutes.deleteAccountPath);

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.deleteAccountPath);
  });

  testWidgets('deactivated authenticated supplier is redirected from protected routes to delete account path', (tester) async {
    final container = _buildSupplierRouterContainer(authState: _deactivatedSupplierAuthState);
    addTearDown(container.dispose);

    final router = await _pumpSupplierRouterApp(tester, container);

    router.go(AppRoutes.supplierDashboardPath);
    await _pumpUntilPath(tester, router, AppRoutes.deleteAccountPath);

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.deleteAccountPath);
  });

  testWidgets('deactivated authenticated trucker is redirected from auth to delete account path', (tester) async {
    final container = _buildTruckerRouterContainer(authState: _deactivatedTruckerAuthState);
    addTearDown(container.dispose);

    final router = await _pumpSupplierRouterApp(tester, container);

    router.go(AppRoutes.authPath);
    await _pumpUntilPath(tester, router, AppRoutes.deleteAccountPath);

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.deleteAccountPath);
  });

  testWidgets('deactivated authenticated trucker is redirected from protected routes to delete account path', (tester) async {
    final container = _buildTruckerRouterContainer(authState: _deactivatedTruckerAuthState);
    addTearDown(container.dispose);

    final router = await _pumpSupplierRouterApp(tester, container);

    router.go(AppRoutes.truckerDashboardPath);
    await _pumpUntilPath(tester, router, AppRoutes.deleteAccountPath);

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.deleteAccountPath);
  });

  testWidgets('restricted authenticated supplier is redirected from auth to banned path', (tester) async {
    final container = _buildSupplierRouterContainer(authState: _restrictedSupplierAuthState);
    addTearDown(container.dispose);

    final router = await _pumpSupplierRouterApp(tester, container);

    router.go(AppRoutes.authPath);
    await _pumpUntilPath(tester, router, AppRoutes.bannedPath);

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.bannedPath);
  });

  testWidgets('restricted authenticated supplier is redirected from protected routes to banned path', (tester) async {
    final container = _buildSupplierRouterContainer(authState: _restrictedSupplierAuthState);
    addTearDown(container.dispose);

    final router = await _pumpSupplierRouterApp(tester, container);

    router.go(AppRoutes.supplierDashboardPath);
    await _pumpUntilPath(tester, router, AppRoutes.bannedPath);

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.bannedPath);
  });

  testWidgets('restricted authenticated trucker is redirected from auth to banned path', (tester) async {
    final container = _buildTruckerRouterContainer(authState: _restrictedTruckerAuthState);
    addTearDown(container.dispose);

    final router = await _pumpSupplierRouterApp(tester, container);

    router.go(AppRoutes.authPath);
    await _pumpUntilPath(tester, router, AppRoutes.bannedPath);

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.bannedPath);
  });

  testWidgets('restricted authenticated trucker is redirected from protected routes to banned path', (tester) async {
    final container = _buildTruckerRouterContainer(authState: _restrictedTruckerAuthState);
    addTearDown(container.dispose);

    final router = await _pumpSupplierRouterApp(tester, container);

    router.go(AppRoutes.truckerDashboardPath);
    await _pumpUntilPath(tester, router, AppRoutes.bannedPath);

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.bannedPath);
  });

  testWidgets('non-restricted authenticated supplier is redirected away from banned path to supplier dashboard', (tester) async {
    final container = _buildSupplierRouterContainer();
    addTearDown(container.dispose);

    final router = await _pumpSupplierRouterApp(tester, container);

    router.go(AppRoutes.bannedPath);
    await _pumpUntilPath(tester, router, AppRoutes.supplierDashboardPath);

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.supplierDashboardPath);
  });

  testWidgets('non-restricted authenticated trucker is redirected away from banned path to trucker dashboard', (tester) async {
    final container = _buildTruckerRouterContainer();
    addTearDown(container.dispose);

    final router = await _pumpSupplierRouterApp(tester, container);

    router.go(AppRoutes.bannedPath);
    await _pumpUntilPath(tester, router, AppRoutes.truckerDashboardPath);

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.truckerDashboardPath);
  });

  testWidgets('supplier generic shell routes redirect to supplier destinations', (tester) async {
    final container = _buildSupplierRouterContainer();
    addTearDown(container.dispose);

    final router = await _pumpSupplierRouterApp(tester, container);
    final redirects = <String, String>{
      AppRoutes.dashboardPath: AppRoutes.supplierDashboardPath,
      AppRoutes.findLoadsPath: AppRoutes.myLoadsPath,
      AppRoutes.fleetPath: AppRoutes.supplierDashboardPath,
    };

    for (final entry in redirects.entries) {
      router.go(entry.key);
      await _pumpUntilPath(tester, router, entry.value);

      expect(router.routeInformationProvider.value.uri.path, entry.value);
    }
  });

  testWidgets('supplier generic trips route redirects to supplier trips screen', (tester) async {
    final container = _buildSupplierRouterContainer();
    addTearDown(container.dispose);

    final router = await _pumpSupplierRouterApp(tester, container);

    router.go(AppRoutes.tripsPath);
    for (var attempt = 0; attempt < 10; attempt++) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      if (find.byType(SupplierTripsScreen).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.byType(SupplierTripsScreen), findsOneWidget);
  });

  testWidgets('trucker generic shell routes redirect to trucker destinations', (tester) async {
    final container = _buildTruckerRouterContainer();
    addTearDown(container.dispose);

    final router = await _pumpSupplierRouterApp(tester, container);
    final redirects = <String, String>{
      AppRoutes.dashboardPath: AppRoutes.truckerDashboardPath,
      AppRoutes.supplierDashboardPath: AppRoutes.truckerDashboardPath,
      AppRoutes.myLoadsPath: AppRoutes.findLoadsPath,
      AppRoutes.supplierTripsPath: AppRoutes.tripsPath,
    };

    for (final entry in redirects.entries) {
      router.go(entry.key);
      await _pumpUntilPath(tester, router, entry.value);

      expect(router.routeInformationProvider.value.uri.path, entry.value);
    }
  });
}
