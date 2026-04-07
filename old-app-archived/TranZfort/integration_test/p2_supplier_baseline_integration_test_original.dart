import 'dart:io';

import 'package:app/src/core/error/app_failure.dart';
import 'package:app/src/core/error/result.dart';
import 'package:app/src/core/repositories/load_repository.dart';
import 'package:app/src/core/services/database_service.dart';
import 'package:app/src/core/services/storage_service.dart';
import 'package:app/src/features/auth/providers/auth_providers.dart';
import 'package:app/src/features/marketplace/providers/marketplace_providers.dart';
import 'package:app/src/features/marketplace/presentation/my_loads_screen.dart';
import 'package:app/src/features/marketplace/presentation/post_load_screen.dart';
import 'package:app/src/features/verification/presentation/supplier_verification_screen.dart';
import 'package:app/src/features/verification/providers/verification_providers.dart';
import 'package:app/src/core/services/city_search_service.dart';
import 'package:app/src/shared/widgets/outline_button.dart';
import 'package:app/src/shared/widgets/primary_button.dart';
import 'package:app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

AuthState _signedInSupplierAuthState() {
  final session = Session.fromJson({
    'access_token': 'p2-supplier-access-token',
    'token_type': 'bearer',
    'refresh_token': 'p2-supplier-refresh-token',
    'expires_in': 3600,
    'user': {
      'id': '44444444-4444-4444-4444-444444444444',
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'supplier@example.com',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'created_at': '2026-03-01T00:00:00Z',
    },
  });

  return AuthState(AuthChangeEvent.signedIn, session);
}

class _FakeLoadRepository extends LoadRepository {
  _FakeLoadRepository({List<Map<String, dynamic>> seedLoads = const []})
    : _seedLoads = List<Map<String, dynamic>>.from(seedLoads),
      super(SupabaseClient('https://example.com', 'anon-key'));

  int createLoadCalls = 0;
  int deactivateLoadCalls = 0;
  Map<String, dynamic>? lastPayload;
  final List<Map<String, dynamic>> _seedLoads;
  final List<Map<String, dynamic>> _createdLoads = <Map<String, dynamic>>[];

  static const _completedStatuses = <String>{'completed', 'cancelled', 'expired'};

  @override
  Future<Result<Map<String, dynamic>>> createLoad({
    required String supplierId,
    required Map<String, dynamic> payload,
  }) async {
    createLoadCalls += 1;
    lastPayload = payload;

    final id = 'fixture-load-$createLoadCalls';
    final row = <String, dynamic>{
      'id': id,
      'supplier_id': supplierId,
      'parent_load_id': null,
      'status': 'active',
      ...payload,
    };
    _createdLoads.insert(0, row);
    return Success(row);
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> myLoads({
    required String supplierId,
    required bool completed,
  }) async {
    final rows = [..._createdLoads, ..._seedLoads]
        .where((row) => row['supplier_id'] == supplierId)
        .where((row) {
          final status = (row['status'] ?? 'active').toString();
          final isCompleted = _completedStatuses.contains(status);
          return completed ? isCompleted : !isCompleted;
        })
        .toList(growable: false);
    return Success(rows);
  }

  @override
  Future<Result<Map<String, dynamic>>> getLoadDetail(String loadId) async {
    final allRows = [..._createdLoads, ..._seedLoads];
    final row = allRows.where((item) => item['id'] == loadId).firstOrNull;
    if (row == null) {
      return const Failure(AppFailureType.notFound);
    }
    return Success(row);
  }

  @override
  Future<Result<void>> deactivateLoad(String loadId) async {
    deactivateLoadCalls += 1;

    for (final row in [..._createdLoads, ..._seedLoads]) {
      if (row['id']?.toString() == loadId) {
        row['status'] = 'cancelled';
        row['updated_at'] = DateTime.now().toIso8601String();
        return const Success(null);
      }
    }

    return const Failure(AppFailureType.notFound);
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getChildLoads(
    String parentLoadId,
  ) async {
    return const Success(<Map<String, dynamic>>[]);
  }

  @override
  Future<Result<double>> getDieselPrice(String state) async {
    return const Success(90);
  }
}

class _MyLoadsRouterHost extends StatelessWidget {
  const _MyLoadsRouterHost();

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/my-loads',
      routes: [
        GoRoute(
          path: '/my-loads',
          builder: (context, state) => const MyLoadsScreen(),
        ),
        GoRoute(
          path: '/load-detail/:loadId',
          builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
        ),
        GoRoute(
          path: '/post-load',
          builder: (context, state) {
            final draft = state.extra is Map<String, dynamic>
                ? state.extra as Map<String, dynamic>
                : const <String, dynamic>{};
            final material = (draft['material'] ?? '').toString();
            final truckType = (draft['required_truck_type'] ?? '').toString();
            final tyres = (draft['required_tyres'] ?? const <dynamic>[]).toString();
            return Scaffold(
              body: Center(
                child: Text(
                  'draft-material:$material|draft-truck:$truckType|draft-tyres:$tyres',
                ),
              ),
            );
          },
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
    );
  }
}

class _NoopDatabaseService implements DatabaseService {
  @override
  Future<Result<void>> delete(String table, String id) async {
    return const Success(null);
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> get(
    String table, {
    String? filterColumn,
    filterValue,
  }) async {
    return const Success(<Map<String, dynamic>>[]);
  }

  @override
  Future<Result<Map<String, dynamic>>> getSingle(
    String table, {
    required String filterColumn,
    required filterValue,
  }) async {
    return const Success(<String, dynamic>{});
  }

  @override
  Future<Result<Map<String, dynamic>>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    return const Success(<String, dynamic>{'id': 'fixture-id'});
  }

  @override
  Future<Result<Map<String, dynamic>>> update(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    return Success(<String, dynamic>{'id': id, ...data});
  }
}

class _NoopStorageService implements StorageService {
  @override
  Future<Result<String>> createSignedUrl({
    required String bucketName,
    required String filePath,
    int expiresInSeconds = 3600,
  }) async {
    return const Failure(AppFailureType.unknown);
  }

  @override
  Future<Result<void>> deleteFile({
    required String bucketName,
    required String filePath,
  }) async {
    return const Success(null);
  }

  @override
  Future<Result<String>> uploadFile({
    required String bucketName,
    required String folderPath,
    required File file,
    required String fileNamePrefix,
  }) async {
    return const Success('https://example.com/uploaded.jpg');
  }

  @override
  Future<Result<String>> uploadFileAtPath({
    required String bucketName,
    required String fullPath,
    required File file,
  }) async {
    return const Success('https://example.com/uploaded-at-path.jpg');
  }

  @override
  Future<Result<String>> uploadPrivateFileAtPath({
    required String bucketName,
    required String fullPath,
    required File file,
  }) async {
    return const Success('private/uploaded/path.jpg');
  }
}

class _ConfigurableStorageService implements StorageService {
  _ConfigurableStorageService({this.failPrefixes = const <String>{}});

  final Set<String> failPrefixes;

  @override
  Future<Result<String>> createSignedUrl({
    required String bucketName,
    required String filePath,
    int expiresInSeconds = 3600,
  }) async {
    return const Success('https://example.com/signed-url.jpg');
  }

  @override
  Future<Result<void>> deleteFile({
    required String bucketName,
    required String filePath,
  }) async {
    return const Success(null);
  }

  @override
  Future<Result<String>> uploadFile({
    required String bucketName,
    required String folderPath,
    required File file,
    required String fileNamePrefix,
  }) async {
    if (failPrefixes.contains(fileNamePrefix)) {
      return const Failure(
        AppFailureType.validation,
        debugMessage: 'Rejected file upload',
      );
    }
    return Success('https://example.com/$fileNamePrefix.jpg');
  }

  @override
  Future<Result<String>> uploadFileAtPath({
    required String bucketName,
    required String fullPath,
    required File file,
  }) async {
    return const Success('https://example.com/uploaded-at-path.jpg');
  }

  @override
  Future<Result<String>> uploadPrivateFileAtPath({
    required String bucketName,
    required String fullPath,
    required File file,
  }) async {
    return const Success('private/uploaded/path.jpg');
  }
}

class _FakeSupplierVerificationNotifier extends SupplierVerificationNotifier {
  _FakeSupplierVerificationNotifier({this.seedProfile, this.seedSupplier})
    : super(_NoopStorageService(), _NoopDatabaseService(), null);

  final Map<String, dynamic>? seedProfile;
  final Map<String, dynamic>? seedSupplier;

  int submitCalls = 0;

  @override
  Future<Map<String, dynamic>> loadExistingData() async {
    return {
      'profile': seedProfile ?? <String, dynamic>{},
      'supplier': seedSupplier ?? <String, dynamic>{},
    };
  }

  @override
  Future<void> submitVerification({
    required String companyName,
    required String aadhaarNumber,
    File? profilePhoto,
    File? aadhaarFront,
    File? aadhaarBack,
    required String panNumber,
    File? panPhoto,
    required String tanNumber,
    File? tanPhoto,
    required String gstNumber,
    File? gstPhoto,
    required String businessLicenceNumber,
    File? businessLicenceDoc,
  }) async {
    submitCalls += 1;
    state = const AsyncData(null);
  }
}

class _SupplierVerificationHost extends StatelessWidget {
  const _SupplierVerificationHost();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const SupplierVerificationScreen(),
    );
  }
}

class _PostLoadRouterHost extends StatelessWidget {
  const _PostLoadRouterHost();

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/post-load',
      routes: [
        GoRoute(
          path: '/post-load',
          builder: (context, state) => const PostLoadScreen(),
        ),
        GoRoute(
          path: '/verification/supplier',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Supplier verification route reached'))),
        ),
        GoRoute(
          path: '/my-loads',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('My loads route reached'))),
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
    );
  }
}

Future<void> _fillSupplierVerificationBasics(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  expect(fields, findsAtLeastNWidgets(4));

  await tester.enterText(fields.at(0), 'Fixture Supplier Pvt Ltd');
  await tester.enterText(fields.at(1), '27ABCDE1234F1Z5');
  await tester.enterText(fields.at(2), 'ABCDE1234F');
  await tester.enterText(fields.at(3), '123412341234');
}

CitySuggestion _city({
  required String city,
  required String state,
  required double lat,
  required double lng,
}) {
  return CitySuggestion(city: city, state: state, lat: lat, lng: lng);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('P2 supplier verification and load-post baseline packs', () {
    test('S-LOAD-02 route step blocks advance until origin and destination are set', () {
      final container = ProviderContainer();

      final notifier = container.read(postLoadProvider.notifier);

      expect(container.read(postLoadProvider).currentStep, 0);
      notifier.nextStep();
      expect(container.read(postLoadProvider).currentStep, 0);

      notifier.setOrigin(
        _city(city: 'Mumbai', state: 'Maharashtra', lat: 19.076, lng: 72.8777),
      );
      notifier.nextStep();
      expect(container.read(postLoadProvider).currentStep, 0);

      notifier.setDestination(
        _city(city: 'Pune', state: 'Maharashtra', lat: 18.5204, lng: 73.8567),
      );
      notifier.nextStep();
      expect(container.read(postLoadProvider).currentStep, 1);
    });

    test('S-LOAD-03/05 baseline: submit guard enforces positive weight and price; trucks count clamps to minimum 1', () {
      final container = ProviderContainer();

      final notifier = container.read(postLoadProvider.notifier);
      notifier
        ..setOrigin(
          _city(
            city: 'Mumbai',
            state: 'Maharashtra',
            lat: 19.076,
            lng: 72.8777,
          ),
        )
        ..setDestination(
          _city(
            city: 'Pune',
            state: 'Maharashtra',
            lat: 18.5204,
            lng: 73.8567,
          ),
        )
        ..setTruckType('open')
        ..toggleTyre(10);

      expect(container.read(postLoadProvider).canSubmit, isTrue);

      notifier.setWeight(0);
      expect(container.read(postLoadProvider).canSubmit, isFalse);

      notifier.setWeight(18);
      notifier.setPrice(0);
      expect(container.read(postLoadProvider).canSubmit, isFalse);

      notifier.setPrice(52000);
      notifier.setTrucksNeeded(0);
      expect(container.read(postLoadProvider).trucksNeeded, 1);
      expect(container.read(postLoadProvider).canSubmit, isTrue);

      notifier.setTrucksNeeded(2);
      expect(container.read(postLoadProvider).canSubmit, isTrue);
    });

    test('S-LOAD-04 submit guard requires truck type and tyre selection', () {
      final container = ProviderContainer();

      final notifier = container.read(postLoadProvider.notifier);
      notifier
        ..setOrigin(
          _city(
            city: 'Mumbai',
            state: 'Maharashtra',
            lat: 19.076,
            lng: 72.8777,
          ),
        )
        ..setDestination(
          _city(
            city: 'Pune',
            state: 'Maharashtra',
            lat: 18.5204,
            lng: 73.8567,
          ),
        );

      expect(container.read(postLoadProvider).canSubmit, isFalse);

      notifier.setTruckType('open');
      expect(container.read(postLoadProvider).canSubmit, isFalse);

      notifier.toggleTyre(10);
      expect(container.read(postLoadProvider).canSubmit, isTrue);

      notifier.toggleTyre(10);
      expect(container.read(postLoadProvider).canSubmit, isFalse);
    });

    test('S-LOAD-06 submit load success resets form state', () async {
      final fakeRepo = _FakeLoadRepository();
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) => Stream.value(_signedInSupplierAuthState()),
          ),
          userProfileProvider.overrideWith(
            (ref) async => <String, dynamic>{
              'user_role_type': 'supplier',
              'verification_status': 'verified',
            },
          ),
          loadRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authSessionProvider.future);

      final notifier = container.read(postLoadProvider.notifier);
      notifier
        ..setOrigin(
          _city(
            city: 'Mumbai',
            state: 'Maharashtra',
            lat: 19.076,
            lng: 72.8777,
          ),
        )
        ..setDestination(
          _city(
            city: 'Pune',
            state: 'Maharashtra',
            lat: 18.5204,
            lng: 73.8567,
          ),
        )
        ..setTruckType('open')
        ..toggleTyre(10);

      final submitted = await notifier.submitLoad();

      expect(submitted, isTrue);
      expect(fakeRepo.createLoadCalls, 1);
      expect(fakeRepo.lastPayload?['origin_city'], 'Mumbai');
      expect(fakeRepo.lastPayload?['dest_city'], 'Pune');
      expect(container.read(postLoadProvider).originCity, isNull);
      expect(container.read(postLoadProvider).destinationCity, isNull);
    });

    test('S-LOAD-07 new load becomes visible in my-loads provider after submit', () async {
      final fakeRepo = _FakeLoadRepository();
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) => Stream.value(_signedInSupplierAuthState()),
          ),
          userProfileProvider.overrideWith(
            (ref) async => <String, dynamic>{
              'user_role_type': 'supplier',
              'verification_status': 'verified',
            },
          ),
          loadRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authSessionProvider.future);

      final before = await container.read(myLoadsProvider(false).future);
      expect(before, isEmpty);

      final notifier = container.read(postLoadProvider.notifier);
      notifier
        ..setOrigin(
          _city(
            city: 'Mumbai',
            state: 'Maharashtra',
            lat: 19.076,
            lng: 72.8777,
          ),
        )
        ..setDestination(
          _city(
            city: 'Pune',
            state: 'Maharashtra',
            lat: 18.5204,
            lng: 73.8567,
          ),
        )
        ..setTruckType('open')
        ..toggleTyre(10);

      final submitted = await notifier.submitLoad();
      expect(submitted, isTrue);

      final after = await container.read(myLoadsProvider(false).future);
      expect(after, hasLength(1));
      expect(after.first['origin_city'], 'Mumbai');
      expect(after.first['dest_city'], 'Pune');
    });

    test('S-LOAD-08 posted load resolves through load-detail linkage provider', () async {
      final fakeRepo = _FakeLoadRepository();
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) => Stream.value(_signedInSupplierAuthState()),
          ),
          userProfileProvider.overrideWith(
            (ref) async => <String, dynamic>{
              'user_role_type': 'supplier',
              'verification_status': 'verified',
            },
          ),
          loadRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authSessionProvider.future);

      final notifier = container.read(postLoadProvider.notifier);
      notifier
        ..setOrigin(
          _city(
            city: 'Mumbai',
            state: 'Maharashtra',
            lat: 19.076,
            lng: 72.8777,
          ),
        )
        ..setDestination(
          _city(
            city: 'Pune',
            state: 'Maharashtra',
            lat: 18.5204,
            lng: 73.8567,
          ),
        )
        ..setTruckType('open')
        ..toggleTyre(10);

      final submitted = await notifier.submitLoad();
      expect(submitted, isTrue);

      final myLoads = await container.read(myLoadsProvider(false).future);
      final loadId = myLoads.first['id'].toString();

      final detail = await container.read(loadDetailProvider(loadId).future);
      expect(detail['load'], isNotNull);
      expect((detail['load'] as Map<String, dynamic>)['id'], loadId);
      expect(detail['children'], isA<List<Map<String, dynamic>>>());
    });

    testWidgets('S-LOAD-09 completed-load repost action forwards draft payload to post-load route', (
      tester,
    ) async {
      final fakeRepo = _FakeLoadRepository(
        seedLoads: [
          {
            'id': 'completed-load-1',
            'supplier_id': '44444444-4444-4444-4444-444444444444',
            'status': 'completed',
            'origin_city': 'Mumbai',
            'origin_state': 'Maharashtra',
            'dest_city': 'Pune',
            'dest_state': 'Maharashtra',
            'material': 'Steel',
            'weight_tonnes': 22,
            'required_truck_type': 'container',
            'required_tyres': [12],
            'price': 70000,
            'advance_percentage': 75,
            'pickup_date': '2026-03-05',
            'trucks_needed': 2,
            'trucks_booked': 2,
          },
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInSupplierAuthState()),
            ),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'supplier',
                'verification_status': 'verified',
              },
            ),
            loadRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const _MyLoadsRouterHost(),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byType(Tab).at(1));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.refresh).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('draft-material:Steel'), findsOneWidget);
      expect(find.textContaining('draft-truck:container'), findsOneWidget);
      expect(find.textContaining('draft-tyres:[12]'), findsOneWidget);
    });

    testWidgets('S-LOAD-10 active-load deactivate action cancels load and clears active list item', (
      tester,
    ) async {
      final fakeRepo = _FakeLoadRepository(
        seedLoads: [
          {
            'id': 'active-load-1',
            'supplier_id': '44444444-4444-4444-4444-444444444444',
            'status': 'active',
            'origin_city': 'Nagpur',
            'origin_state': 'Maharashtra',
            'dest_city': 'Pune',
            'dest_state': 'Maharashtra',
            'material': 'Coal',
            'weight_tonnes': 18,
            'required_truck_type': 'open',
            'required_tyres': [10],
            'price': 52000,
            'advance_percentage': 70,
            'pickup_date': '2026-03-06',
            'trucks_needed': 1,
            'trucks_booked': 0,
          },
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInSupplierAuthState()),
            ),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'supplier',
                'verification_status': 'verified',
              },
            ),
            loadRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const _MyLoadsRouterHost(),
        ),
      );

      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MyLoadsScreen));
      final l10n = AppLocalizations.of(context);

      expect(find.text('Nagpur → Pune'), findsOneWidget);
      await tester.tap(find.widgetWithText(PrimaryButton, l10n.deactivateAction));
      await tester.pumpAndSettle();

      expect(fakeRepo.deactivateLoadCalls, 1);
      expect(find.text('Nagpur → Pune'), findsNothing);
    });

    testWidgets('S-LOAD-01 open post-load flow from supplier marketplace entrypoint', (
      tester,
    ) async {
      final fakeRepo = _FakeLoadRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInSupplierAuthState()),
            ),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'supplier',
                'verification_status': 'verified',
              },
            ),
            loadRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const _MyLoadsRouterHost(),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('draft-material:'), findsOneWidget);
    });

    testWidgets('S-VER-01 supplier verification screen renders core form sections', (
      tester,
    ) async {
      final fakeNotifier = _FakeSupplierVerificationNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInSupplierAuthState()),
            ),
            supplierVerificationProvider.overrideWith((ref) => fakeNotifier),
          ],
          child: const _SupplierVerificationHost(),
        ),
      );

      await tester.pumpAndSettle();

      final context = tester.element(find.byType(SupplierVerificationScreen));
      final l10n = AppLocalizations.of(context);

      expect(find.text(l10n.verificationSupplierTitle), findsOneWidget);
      expect(find.text(l10n.verificationCompanyDetailsSection), findsOneWidget);
      expect(find.text(l10n.verificationIdentityDetailsSection), findsOneWidget);
    });

    testWidgets('S-VER-02A/B: supplier verification upload chooser shows camera and gallery', (
      tester,
    ) async {
      final fakeNotifier = _FakeSupplierVerificationNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInSupplierAuthState()),
            ),
            supplierVerificationProvider.overrideWith((ref) => fakeNotifier),
          ],
          child: const _SupplierVerificationHost(),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.upload_file_outlined).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    });

    testWidgets('S-VER-02C denied/cancelled picker path keeps form active with recovery feedback', (
      tester,
    ) async {
      final fakeNotifier = _FakeSupplierVerificationNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInSupplierAuthState()),
            ),
            supplierVerificationProvider.overrideWith((ref) => fakeNotifier),
          ],
          child: const _SupplierVerificationHost(),
        ),
      );

      await tester.pumpAndSettle();
      final context = tester.element(find.byType(SupplierVerificationScreen));
      final l10n = AppLocalizations.of(context);

      await tester.tap(find.byIcon(Icons.upload_file_outlined).first);
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(16, 16));
      await tester.pumpAndSettle();

      expect(find.text(l10n.verificationUseGallery), findsOneWidget);
      expect(find.text(l10n.verificationSupplierTitle), findsOneWidget);
    });

    testWidgets('S-VER-03 submit verification succeeds with existing mandatory docs baseline', (
      tester,
    ) async {
      final fakeNotifier = _FakeSupplierVerificationNotifier(
        seedProfile: {
          'aadhaar_number': '123412341234',
          'pan_number': 'ABCDE1234F',
          'avatar_url': 'https://example.com/avatar.jpg',
          'aadhaar_front_photo_url': 'https://example.com/aadhaar-front.jpg',
          'aadhaar_back_photo_url': 'https://example.com/aadhaar-back.jpg',
          'pan_photo_url': 'https://example.com/pan.jpg',
          'verification_status': 'unverified',
        },
        seedSupplier: {
          'company_name': 'Fixture Supplier Pvt Ltd',
          'gst_number': '27ABCDE1234F1Z5',
          'gst_photo_url': 'https://example.com/gst.jpg',
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInSupplierAuthState()),
            ),
            supplierVerificationProvider.overrideWith((ref) => fakeNotifier),
          ],
          child: const _SupplierVerificationHost(),
        ),
      );

      await tester.pumpAndSettle();
      final context = tester.element(find.byType(SupplierVerificationScreen));
      final l10n = AppLocalizations.of(context);

      await tester.ensureVisible(find.byType(PrimaryButton));
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(fakeNotifier.submitCalls, 1);
      expect(find.text(l10n.verificationSubmitSuccess), findsOneWidget);
    });

    testWidgets('S-VER-04 rejection reason is visible in supplier verification banner', (
      tester,
    ) async {
      final fakeNotifier = _FakeSupplierVerificationNotifier(
        seedProfile: {
          'verification_status': 'rejected',
          'verification_rejection_reason': 'PAN photo is blurred',
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInSupplierAuthState()),
            ),
            supplierVerificationProvider.overrideWith((ref) => fakeNotifier),
          ],
          child: const _SupplierVerificationHost(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('PAN photo is blurred'), findsOneWidget);
    });

    testWidgets('S-VER-05 verified profile supports edit and resubmit path', (
      tester,
    ) async {
      final fakeNotifier = _FakeSupplierVerificationNotifier(
        seedProfile: {
          'aadhaar_number': '123412341234',
          'pan_number': 'ABCDE1234F',
          'avatar_url': 'https://example.com/avatar.jpg',
          'aadhaar_front_photo_url': 'https://example.com/aadhaar-front.jpg',
          'aadhaar_back_photo_url': 'https://example.com/aadhaar-back.jpg',
          'pan_photo_url': 'https://example.com/pan.jpg',
          'verification_status': 'verified',
        },
        seedSupplier: {
          'company_name': 'Fixture Supplier Pvt Ltd',
          'gst_number': '27ABCDE1234F1Z5',
          'gst_photo_url': 'https://example.com/gst.jpg',
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInSupplierAuthState()),
            ),
            supplierVerificationProvider.overrideWith((ref) => fakeNotifier),
          ],
          child: const _SupplierVerificationHost(),
        ),
      );

      await tester.pumpAndSettle();

      final context = tester.element(find.byType(SupplierVerificationScreen));
      final l10n = AppLocalizations.of(context);

      await tester.tap(find.widgetWithText(OutlineButton, l10n.verificationEditAndResubmitAction));
      await tester.pumpAndSettle();

      expect(find.text(l10n.verificationReverificationNotice), findsOneWidget);

      await tester.ensureVisible(find.byType(PrimaryButton));
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(fakeNotifier.submitCalls, 1);
    });

    testWidgets('S-VER-06 previously uploaded files remain visible after screen relaunch', (
      tester,
    ) async {
      final fakeNotifier = _FakeSupplierVerificationNotifier(
        seedProfile: {
          'aadhaar_number': '123412341234',
          'pan_number': 'ABCDE1234F',
          'avatar_url': 'https://example.com/avatar.jpg',
          'aadhaar_front_photo_url': 'https://example.com/aadhaar-front.jpg',
          'aadhaar_back_photo_url': 'https://example.com/aadhaar-back.jpg',
          'pan_photo_url': 'https://example.com/pan.jpg',
          'verification_status': 'pending',
        },
        seedSupplier: {
          'company_name': 'Fixture Supplier Pvt Ltd',
          'gst_number': '27ABCDE1234F1Z5',
          'gst_photo_url': 'https://example.com/gst.jpg',
          'business_licence_doc_url': 'https://example.com/licence.jpg',
        },
      );

      Future<void> pumpHost() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authSessionProvider.overrideWith(
                (ref) => Stream.value(_signedInSupplierAuthState()),
              ),
              supplierVerificationProvider.overrideWith((ref) => fakeNotifier),
            ],
            child: const _SupplierVerificationHost(),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpHost();
      final context = tester.element(find.byType(SupplierVerificationScreen));
      final l10n = AppLocalizations.of(context);

      expect(find.text(l10n.documentAttachedTapReplace), findsAtLeastNWidgets(5));

      await pumpHost();
      expect(find.text(l10n.documentAttachedTapReplace), findsAtLeastNWidgets(5));
    });

    testWidgets('S-UP-01/02 business proof upload chooser exposes camera and gallery options', (
      tester,
    ) async {
      final fakeNotifier = _FakeSupplierVerificationNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInSupplierAuthState()),
            ),
            supplierVerificationProvider.overrideWith((ref) => fakeNotifier),
          ],
          child: const _SupplierVerificationHost(),
        ),
      );

      await tester.pumpAndSettle();
      final context = tester.element(find.byType(SupplierVerificationScreen));
      final l10n = AppLocalizations.of(context);

      await tester.ensureVisible(find.text(l10n.verificationUploadBusinessLicence));
      await tester.tap(find.text(l10n.verificationUploadBusinessLicence));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    });

    test('S-UP-03 invalid upload payload is rejected by supplier verification notifier', () async {
      final notifier = SupplierVerificationNotifier(
        _ConfigurableStorageService(failPrefixes: const {'gst'}),
        _NoopDatabaseService(),
        _signedInSupplierAuthState().session?.user,
      );

      final fakeFile = File('fixture-upload.jpg');
      await notifier.submitVerification(
        companyName: 'Fixture Supplier Pvt Ltd',
        aadhaarNumber: '123412341234',
        profilePhoto: fakeFile,
        aadhaarFront: fakeFile,
        aadhaarBack: fakeFile,
        panNumber: 'ABCDE1234F',
        panPhoto: fakeFile,
        tanNumber: '',
        tanPhoto: null,
        gstNumber: '27ABCDE1234F1Z5',
        gstPhoto: fakeFile,
        businessLicenceNumber: 'BL123456',
        businessLicenceDoc: fakeFile,
      );

      expect(notifier.state.hasError, isTrue);
    });

    testWidgets('S-UP-04 uploaded docs remain attached after reopening verification form', (
      tester,
    ) async {
      final fakeNotifier = _FakeSupplierVerificationNotifier(
        seedProfile: {
          'avatar_url': 'https://example.com/avatar.jpg',
          'aadhaar_front_photo_url': 'https://example.com/aadhaar-front.jpg',
          'aadhaar_back_photo_url': 'https://example.com/aadhaar-back.jpg',
          'pan_photo_url': 'https://example.com/pan.jpg',
          'verification_status': 'pending',
        },
        seedSupplier: {
          'gst_photo_url': 'https://example.com/gst.jpg',
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInSupplierAuthState()),
            ),
            supplierVerificationProvider.overrideWith((ref) => fakeNotifier),
          ],
          child: const _SupplierVerificationHost(),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(SupplierVerificationScreen));
      final l10n = AppLocalizations.of(context);
      expect(find.text(l10n.documentAttachedTapReplace), findsAtLeastNWidgets(5));
    });

    testWidgets('S-VER mandatory-doc guard blocks submit when required docs are missing', (
      tester,
    ) async {
      final fakeNotifier = _FakeSupplierVerificationNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInSupplierAuthState()),
            ),
            supplierVerificationProvider.overrideWith((ref) => fakeNotifier),
          ],
          child: const _SupplierVerificationHost(),
        ),
      );

      await tester.pumpAndSettle();
      await _fillSupplierVerificationBasics(tester);

      await tester.ensureVisible(find.byType(PrimaryButton));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));

      expect(fakeNotifier.submitCalls, 0);
    });

    testWidgets('S-LOAD gate shows for unverified supplier and routes to supplier verification', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInSupplierAuthState()),
            ),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'supplier',
                'verification_status': 'unverified',
              },
            ),
          ],
          child: const _PostLoadRouterHost(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Stepper), findsNothing);
      expect(find.byType(OutlineButton), findsOneWidget);

      await tester.tap(find.byType(OutlineButton));
      await tester.pumpAndSettle();

      expect(find.text('Supplier verification route reached'), findsOneWidget);
    });

    testWidgets('S-LOAD verified supplier sees post-load stepper flow', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInSupplierAuthState()),
            ),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'supplier',
                'verification_status': 'verified',
              },
            ),
          ],
          child: const _PostLoadRouterHost(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Stepper), findsOneWidget);
      expect(find.byType(OutlineButton), findsNothing);
    });
  });
}
