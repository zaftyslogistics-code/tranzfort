import 'dart:io';

import 'package:app/src/core/error/app_failure.dart';
import 'package:app/src/core/error/result.dart';
import 'package:app/src/core/services/database_service.dart';
import 'package:app/src/core/services/storage_service.dart';
import 'package:app/src/features/auth/providers/auth_providers.dart';
import 'package:app/src/features/fleet/presentation/add_truck_screen.dart';
import 'package:app/src/features/fleet/providers/fleet_providers.dart';
import 'package:app/src/features/verification/presentation/trucker_verification_screen.dart';
import 'package:app/src/features/verification/providers/verification_providers.dart';
import 'package:app/src/shared/widgets/primary_button.dart';
import 'package:app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

AuthState _signedInAuthState() {
  final session = Session.fromJson({
    'access_token': 'p1-trucker-access-token',
    'token_type': 'bearer',
    'refresh_token': 'p1-trucker-refresh-token',
    'expires_in': 3600,
    'user': {
      'id': '33333333-3333-3333-3333-333333333333',
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'trucker@example.com',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'created_at': '2026-03-01T00:00:00Z',
    },
  });

  return AuthState(AuthChangeEvent.signedIn, session);
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

class _FakeTruckerVerificationNotifier extends TruckerVerificationNotifier {
  _FakeTruckerVerificationNotifier({
    required this.hasCompleteTruckResult,
    this.existingProfile = const <String, dynamic>{},
    this.existingTrucker = const <String, dynamic>{},
  }) : super(_NoopStorageService(), _NoopDatabaseService(), null);

  final bool hasCompleteTruckResult;
  final Map<String, dynamic> existingProfile;
  final Map<String, dynamic> existingTrucker;

  int submitCalls = 0;

  @override
  Future<bool> hasAtLeastOneCompleteTruck() async => hasCompleteTruckResult;

  @override
  Future<Map<String, dynamic>> loadExistingData() async {
    return {
      'profile': existingProfile,
      'trucker': existingTrucker,
    };
  }

  @override
  Future<void> submitVerification({
    required String aadhaarNumber,
    File? profilePhoto,
    File? aadhaarFront,
    File? aadhaarBack,
    required String panNumber,
    File? panPhoto,
    required String dlNumber,
    DateTime? dlExpiryDate,
    File? dlFrontPhoto,
    File? dlBackPhoto,
  }) async {
    submitCalls += 1;
    state = const AsyncData(null);
  }
}

class _FakeAddTruckNotifier extends AddTruckNotifier {
  _FakeAddTruckNotifier() : super(_NoopDatabaseService(), _NoopStorageService(), 'fixture-user');

  int addCalls = 0;

  @override
  Future<void> addTruck({
    required String truckNumber,
    required String bodyType,
    required int tyres,
    required double capacityTonnes,
    DateTime? rcExpiryDate,
    String? truckModelId,
    File? rcPhotoFile,
  }) async {
    addCalls += 1;
    state = const AsyncData(null);
  }
}

class _VerificationRouterHost extends StatelessWidget {
  const _VerificationRouterHost();

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/verify',
      routes: [
        GoRoute(
          path: '/verify',
          builder: (context, state) => const TruckerVerificationScreen(),
        ),
        GoRoute(
          path: '/my-fleet/add',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Add truck route reached')),
          ),
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

Future<void> _fillTruckerFormBasics(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  expect(fields, findsAtLeastNWidgets(3));

  await tester.enterText(fields.at(0), '123412341234');
  await tester.enterText(fields.at(1), 'ABCDE1234F');
  await tester.enterText(fields.at(2), 'MH1420240001234');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('P1 trucker permission and upload baseline packs', () {
    testWidgets('T-VER-01: trucker verification screen render', (tester) async {
      final fakeNotifier = _FakeTruckerVerificationNotifier(
        hasCompleteTruckResult: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            truckerVerificationProvider.overrideWith((ref) => fakeNotifier),
          ],
          child: const _VerificationRouterHost(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TruckerVerificationScreen), findsOneWidget);
      expect(find.byType(PrimaryButton), findsOneWidget);
    });

    testWidgets('T-VER-02A/B: verification upload chooser shows camera and gallery', (
      tester,
    ) async {
      final fakeNotifier = _FakeTruckerVerificationNotifier(
        hasCompleteTruckResult: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            truckerVerificationProvider.overrideWith((ref) => fakeNotifier),
          ],
          child: const _VerificationRouterHost(),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.upload_file_outlined).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    });

    testWidgets('T-VER-02C: chooser dismiss shows recoverable guidance and keeps form active', (
      tester,
    ) async {
      final fakeNotifier = _FakeTruckerVerificationNotifier(
        hasCompleteTruckResult: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            truckerVerificationProvider.overrideWith((ref) => fakeNotifier),
          ],
          child: const _VerificationRouterHost(),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.upload_file_outlined).first);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(16, 16));
      await tester.pumpAndSettle();

      expect(find.byType(TruckerVerificationScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(fakeNotifier.submitCalls, 0);
    });

    testWidgets('T-VER-03: submit blocks when no complete truck and shows add-truck action', (
      tester,
    ) async {
      final fakeNotifier = _FakeTruckerVerificationNotifier(
        hasCompleteTruckResult: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            truckerVerificationProvider.overrideWith((ref) => fakeNotifier),
          ],
          child: const _VerificationRouterHost(),
        ),
      );

      await tester.pumpAndSettle();
      await _fillTruckerFormBasics(tester);

      await tester.ensureVisible(find.byType(PrimaryButton));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SnackBarAction), findsOneWidget);
      expect(fakeNotifier.submitCalls, 0);
    });

    testWidgets('T-VER-04: complete-truck path allows submit when required docs already exist', (
      tester,
    ) async {
      final fakeNotifier = _FakeTruckerVerificationNotifier(
        hasCompleteTruckResult: true,
        existingProfile: const {
          'aadhaar_number': '123412341234',
          'pan_number': 'ABCDE1234F',
          'aadhaar_front_photo_url': 'https://example.com/a_front.jpg',
          'aadhaar_back_photo_url': 'https://example.com/a_back.jpg',
          'pan_photo_url': 'https://example.com/pan.jpg',
          'avatar_url': 'https://example.com/avatar.jpg',
        },
        existingTrucker: const {
          'dl_number': 'MH1420240001234',
          'dl_front_photo_url': 'https://example.com/dl_front.jpg',
          'dl_back_photo_url': 'https://example.com/dl_back.jpg',
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            truckerVerificationProvider.overrideWith((ref) => fakeNotifier),
          ],
          child: const _VerificationRouterHost(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(PrimaryButton));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(fakeNotifier.submitCalls, 1);
    });

    testWidgets('T-VER-05/06: rejected profile shows reason, supports resubmit, and existing docs persist on relaunch', (
      tester,
    ) async {
      final fakeNotifier = _FakeTruckerVerificationNotifier(
        hasCompleteTruckResult: true,
        existingProfile: const {
          'verification_status': 'rejected',
          'verification_rejection_reason': 'Document mismatch',
          'aadhaar_number': '123412341234',
          'pan_number': 'ABCDE1234F',
          'aadhaar_front_photo_url': 'https://example.com/a_front.jpg',
          'aadhaar_back_photo_url': 'https://example.com/a_back.jpg',
          'pan_photo_url': 'https://example.com/pan.jpg',
          'avatar_url': 'https://example.com/avatar.jpg',
        },
        existingTrucker: const {
          'dl_number': 'MH1420240001234',
          'dl_front_photo_url': 'https://example.com/dl_front.jpg',
          'dl_back_photo_url': 'https://example.com/dl_back.jpg',
        },
      );

      Future<void> pumpSubject() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authSessionProvider.overrideWith(
                (ref) => Stream.value(_signedInAuthState()),
              ),
              truckerVerificationProvider.overrideWith((ref) => fakeNotifier),
            ],
            child: const _VerificationRouterHost(),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpSubject();

      final context = tester.element(find.byType(TruckerVerificationScreen));
      final l10n = AppLocalizations.of(context);

      expect(find.textContaining('Document mismatch'), findsOneWidget);
      expect(find.text(l10n.documentAttachedTapReplace), findsAtLeastNWidgets(1));

      await tester.ensureVisible(find.byType(PrimaryButton));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(fakeNotifier.submitCalls, 1);

      await pumpSubject();
      expect(find.text(l10n.documentAttachedTapReplace), findsAtLeastNWidgets(1));
    });

    testWidgets('T-VER mandatory-doc guard blocks submit when truck is complete but docs missing', (
      tester,
    ) async {
      final fakeNotifier = _FakeTruckerVerificationNotifier(
        hasCompleteTruckResult: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            truckerVerificationProvider.overrideWith((ref) => fakeNotifier),
          ],
          child: const _VerificationRouterHost(),
        ),
      );

      await tester.pumpAndSettle();
      await _fillTruckerFormBasics(tester);

      await tester.ensureVisible(find.byType(PrimaryButton));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));

      expect(fakeNotifier.submitCalls, 0);
    });

    testWidgets('T-FLEET-03A/B: add-truck RC chooser shows camera and gallery', (
      tester,
    ) async {
      final fakeAddTruckNotifier = _FakeAddTruckNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            addTruckProvider.overrideWith((ref) => fakeAddTruckNotifier),
            truckCatalogProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const AddTruckScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final uploadRcFinder = find.byIcon(Icons.upload_file_outlined).first;
      await tester.ensureVisible(uploadRcFinder);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(uploadRcFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    });

    testWidgets('T-FLEET submit without required selections does not call add notifier', (
      tester,
    ) async {
      final fakeAddTruckNotifier = _FakeAddTruckNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInAuthState()),
            ),
            addTruckProvider.overrideWith((ref) => fakeAddTruckNotifier),
            truckCatalogProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const AddTruckScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'MH12AB1234');

      await tester.ensureVisible(find.byType(PrimaryButton));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));

      expect(fakeAddTruckNotifier.addCalls, 0);
    });
  });
}
