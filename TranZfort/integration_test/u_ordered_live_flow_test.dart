import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/communication/data/chat_repository.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_models.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_repository.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_load_detail_repository.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_marketplace_repository.dart';

bool _supabaseReady = false;

Future<void> _ensureSupabaseInitialized() async {
  if (_supabaseReady) {
    return;
  }

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  final url = dotenv.env['SUPABASE_URL'] ?? const String.fromEnvironment('SUPABASE_URL');
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? const String.fromEnvironment('SUPABASE_ANON_KEY');

  if (url.isEmpty || anonKey.isEmpty) {
    throw Exception('Supabase config missing for TranZfort ordered live flow tests.');
  }

  await Supabase.initialize(url: url, anonKey: anonKey);
  _supabaseReady = true;
}

String _testPasscode() {
  final fromDefine = const String.fromEnvironment('TZ_TEST_PASSCODE');
  if (fromDefine.isNotEmpty) {
    return fromDefine;
  }
  return dotenv.env['TZ_TEST_PASSCODE'] ?? 'Tabish%%Khan721';
}

String _supplierEmail() {
  final fromDefine = const String.fromEnvironment('TZ_SUPPLIER_EMAIL');
  if (fromDefine.isNotEmpty) {
    return fromDefine;
  }
  return dotenv.env['TZ_SUPPLIER_EMAIL'] ?? 'supplier@example.com';
}

String _truckerEmail() {
  final fromDefine = const String.fromEnvironment('TZ_TRUCKER_EMAIL');
  if (fromDefine.isNotEmpty) {
    return fromDefine;
  }
  return dotenv.env['TZ_TRUCKER_EMAIL'] ?? 'trucker@example.com';
}

Future<void> _signIn(SupabaseClient client, String email) async {
  await client.auth.signOut(scope: SignOutScope.local);

  final auth = await client.auth.signInWithPassword(
    email: email,
    password: _testPasscode(),
  );

  expect(auth.session, isNotNull);
  expect(auth.user, isNotNull);
  expect(client.auth.currentSession, isNotNull);
  expect(client.auth.currentUser?.email, email);
}

ProviderContainer _buildContainer({required AppUserRole role}) {
  return ProviderContainer(
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
    ],
  );
}

Future<MarketplaceLoadItem?> _findMarketplaceLoadByOrigin(
  TruckerMarketplaceRepository repository,
  String originCity,
) async {
  for (var attempt = 0; attempt < 5; attempt += 1) {
    final result = await repository.searchLoads(MarketplaceSearchFilters(originCity: originCity));
    if (result.isSuccess) {
      for (final item in result.valueOrNull!) {
        if (item.originCity.trim().toLowerCase() == originCity.trim().toLowerCase()) {
          return item;
        }
      }
    }
    if (attempt < 4) {
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }
  return null;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('U-FLOW ordered live probes', () {
    testWidgets('U-FLOW-001 supplier loads and detail load through current repository contract', (tester) async {
      await _ensureSupabaseInitialized();
      final client = Supabase.instance.client;
      await _signIn(client, _supplierEmail());

      final container = _buildContainer(role: AppUserRole.supplier);
      addTearDown(container.dispose);

      final repository = container.read(supplierLoadRepositoryProvider);
      final loadsResult = await repository.getMyLoads(const LoadFilters(), page: 1);

      expect(loadsResult.isSuccess, isTrue);
      final loads = loadsResult.valueOrNull!;
      expect(loads, isA<List<Load>>());

      if (loads.isNotEmpty) {
        // Verify at least one load has successful detail read
        Result<LoadDetail>? usableDetailResult;
        Load? usableLoad;

        for (final load in loads) {
          final detailResult = await repository.getLoadDetail(load.id);
          if (detailResult.isSuccess) {
            usableLoad = load;
            usableDetailResult = detailResult;
            break;
          }
        }

        expect(usableLoad, isNotNull, reason: 'No supplier load produced successful detail read.');
        final firstLoad = usableLoad!;
        expect(firstLoad.id, isNotEmpty);
        expect(firstLoad.originLabel.trim(), isNotEmpty);
        expect(firstLoad.destinationLabel.trim(), isNotEmpty);
        expect(firstLoad.material.trim(), isNotEmpty);

        final detail = usableDetailResult!.valueOrNull!;
        expect(detail.summary.id, firstLoad.id);
        expect(detail.originCity.trim(), isNotEmpty);
        expect(detail.destinationCity.trim(), isNotEmpty);

        // Also verify bookings and trips methods work (they may return empty - that's OK)
        final bookingsResult = await repository.getBookingRequests(firstLoad.id);
        expect(bookingsResult.isSuccess, isTrue, reason: 'getBookingRequests should succeed even if empty');

        final tripsResult = await repository.getLinkedTrips(firstLoad.id);
        expect(tripsResult.isSuccess, isTrue, reason: 'getLinkedTrips should succeed even if empty');
      }

      await client.auth.signOut(scope: SignOutScope.local);
      expect(client.auth.currentSession, isNull);
    });

    testWidgets('U-FLOW-002 trucker marketplace and detail load through current repository contract', (tester) async {
      await _ensureSupabaseInitialized();
      final client = Supabase.instance.client;
      await _signIn(client, _truckerEmail());

      final container = _buildContainer(role: AppUserRole.trucker);
      addTearDown(container.dispose);

      final marketplaceRepository = container.read(truckerMarketplaceRepositoryProvider);
      final detailRepository = container.read(truckerLoadDetailRepositoryProvider);

      final searchResult = await marketplaceRepository.searchLoads(const MarketplaceSearchFilters());
      expect(searchResult.isSuccess, isTrue);
      final loads = searchResult.valueOrNull!;
      expect(loads, isA<List<MarketplaceLoadItem>>());

      final approvedTrucksResult = await detailRepository.fetchApprovedTrucks();
      expect(approvedTrucksResult.isSuccess, isTrue);

      if (loads.isNotEmpty) {
        final firstLoad = loads.first;
        expect(firstLoad.id, isNotEmpty);
        expect(firstLoad.originCity.trim(), isNotEmpty);
        expect(firstLoad.destinationCity.trim(), isNotEmpty);
        expect(firstLoad.status.trim(), isNotEmpty);

        final detailResult = await detailRepository.fetchLoadDetail(firstLoad.id);
        expect(detailResult.isSuccess, isTrue);
        final detail = detailResult.valueOrNull!;
        expect(detail.summary.id, firstLoad.id);
        expect(detail.supplierId.trim(), isNotEmpty);
        expect(detail.supplier.fullName.trim(), isNotEmpty);
        expect(detail.supplier.verificationStatus.trim(), isNotEmpty);
      }

      await client.auth.signOut(scope: SignOutScope.local);
      expect(client.auth.currentSession, isNull);
    });

    testWidgets('U-FLOW-003 trucker conversations load through current repository contract', (tester) async {
      await _ensureSupabaseInitialized();
      final client = Supabase.instance.client;
      await _signIn(client, _truckerEmail());

      final container = _buildContainer(role: AppUserRole.trucker);
      addTearDown(container.dispose);

      final repository = container.read(chatRepositoryProvider);
      final conversationsResult = await repository.getConversations();

      expect(conversationsResult.isSuccess, isTrue);
      final conversations = conversationsResult.valueOrNull!;
      expect(conversations, isA<List<ConversationPreview>>());

      if (conversations.isNotEmpty) {
        final firstConversation = conversations.first;
        expect(firstConversation.id.trim(), isNotEmpty);
        expect(firstConversation.routeLabel.trim(), isNotEmpty);

        final messagesResult = await repository.getMessages(firstConversation.id);
        expect(messagesResult.isSuccess, isTrue);
      }

      await client.auth.signOut(scope: SignOutScope.local);
      expect(client.auth.currentSession, isNull);
    });

    testWidgets('U-FLOW-004 trucker can create or get conversation for a visible marketplace load', (tester) async {
      await _ensureSupabaseInitialized();
      final client = Supabase.instance.client;
      await _signIn(client, _truckerEmail());

      final container = _buildContainer(role: AppUserRole.trucker);
      addTearDown(container.dispose);

      final marketplaceRepository = container.read(truckerMarketplaceRepositoryProvider);
      final detailRepository = container.read(truckerLoadDetailRepositoryProvider);
      final chatRepository = container.read(chatRepositoryProvider);

      final searchResult = await marketplaceRepository.searchLoads(const MarketplaceSearchFilters());
      expect(searchResult.isSuccess, isTrue);
      final loads = searchResult.valueOrNull!;
      if (loads.isEmpty) {
        await client.auth.signOut(scope: SignOutScope.local);
        expect(client.auth.currentSession, isNull);
        return;
      }

      final firstLoad = loads.first;
      final detailResult = await detailRepository.fetchLoadDetail(firstLoad.id);
      expect(detailResult.isSuccess, isTrue);
      final detail = detailResult.valueOrNull!;

      final conversationResult = await chatRepository.createOrGetConversation(
        supplierId: detail.supplierId,
        truckerId: client.auth.currentUser!.id,
        loadId: firstLoad.id,
      );

      expect(conversationResult.isSuccess, isTrue);
      expect(conversationResult.valueOrNull, isNotEmpty);

      await client.auth.signOut(scope: SignOutScope.local);
      expect(client.auth.currentSession, isNull);
    });

    testWidgets('U-FLOW-005 seeded cross-role load can be discovered by trucker and opened for conversation', (tester) async {
      await _ensureSupabaseInitialized();
      final client = Supabase.instance.client;
      final suffix = DateTime.now().millisecondsSinceEpoch.toString();
      final originCity = 'LiveOrigin$suffix';
      final destinationCity = 'LiveDest$suffix';
      String? createdLoadId;

      try {
        await _signIn(client, _supplierEmail());
        final supplierContainer = _buildContainer(role: AppUserRole.supplier);
        addTearDown(supplierContainer.dispose);

        final supplierRepository = supplierContainer.read(supplierLoadRepositoryProvider);
        final createResult = await supplierRepository.createLoad(
          CreateLoadDto(
            originLabel: '$originCity Yard',
            originCity: originCity,
            originState: 'Maharashtra',
            originLat: 19.95,
            originLng: 79.29,
            destinationLabel: '$destinationCity Hub',
            destinationCity: destinationCity,
            destinationState: 'Maharashtra',
            destinationLat: 19.07,
            destinationLng: 72.87,
            routeDistanceKm: 820,
            routeDurationMinutes: 840,
            routePolyline: null,
            routeSnapshotSource: 'live_probe',
            material: 'Coal',
            weightTonnes: 5,
            requiredBodyType: null,
            requiredTyres: null,
            trucksNeeded: 1,
            priceAmount: 12345,
            priceType: 'negotiable',
            advancePercentage: 80,
            pickupDate: DateTime.now().add(const Duration(days: 1)),
          ),
        );

        expect(
          createResult.isSuccess,
          isTrue,
          reason: 'Supplier createLoad failure: ${createResult.failureOrNull}',
        );
        createdLoadId = createResult.valueOrNull;
        expect(createdLoadId, isNotEmpty);

        final loadDetailResult = await supplierRepository.getLoadDetail(createdLoadId!);
        expect(loadDetailResult.isSuccess, isTrue);

        await client.auth.signOut(scope: SignOutScope.local);
        expect(client.auth.currentSession, isNull);

        await _signIn(client, _truckerEmail());
        final truckerContainer = _buildContainer(role: AppUserRole.trucker);
        addTearDown(truckerContainer.dispose);

        final marketplaceRepository = truckerContainer.read(truckerMarketplaceRepositoryProvider);
        final detailRepository = truckerContainer.read(truckerLoadDetailRepositoryProvider);
        final chatRepository = truckerContainer.read(chatRepositoryProvider);

        final discoveredLoad = await _findMarketplaceLoadByOrigin(marketplaceRepository, originCity);
        expect(discoveredLoad, isNotNull);
        expect(discoveredLoad!.id, createdLoadId);

        var truckerDetailResult = await detailRepository.fetchLoadDetail(discoveredLoad.id);
        for (var attempt = 0; attempt < 4 && truckerDetailResult.isFailure; attempt += 1) {
          await Future<void>.delayed(const Duration(seconds: 1));
          truckerDetailResult = await detailRepository.fetchLoadDetail(discoveredLoad.id);
        }
        expect(
          truckerDetailResult.isSuccess,
          isTrue,
          reason: 'Trucker seeded-load detail failure: ${truckerDetailResult.failureOrNull}',
        );
        final truckerDetail = truckerDetailResult.valueOrNull!;
        expect(truckerDetail.supplierId.trim(), isNotEmpty);

        final conversationResult = await chatRepository.createOrGetConversation(
          supplierId: truckerDetail.supplierId,
          truckerId: client.auth.currentUser!.id,
          loadId: discoveredLoad.id,
        );
        expect(conversationResult.isSuccess, isTrue);
        expect(conversationResult.valueOrNull, isNotEmpty);

        await client.auth.signOut(scope: SignOutScope.local);
        expect(client.auth.currentSession, isNull);
      } finally {
        if (createdLoadId != null && createdLoadId.trim().isNotEmpty) {
          await _signIn(client, _supplierEmail());
          final cleanupContainer = _buildContainer(role: AppUserRole.supplier);
          addTearDown(cleanupContainer.dispose);
          final cleanupRepository = cleanupContainer.read(supplierLoadRepositoryProvider);
          final cleanupResult = await cleanupRepository.cancelLoad(createdLoadId);
          expect(cleanupResult.isSuccess, isTrue);
          await client.auth.signOut(scope: SignOutScope.local);
        }
      }
    });
  });
}
