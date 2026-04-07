import 'dart:io';

import 'package:app/src/core/error/result.dart';
import 'package:app/src/core/services/storage_service.dart';
import 'package:app/src/features/auth/providers/auth_providers.dart';
import 'package:app/src/features/verification/presentation/supplier_verification_screen.dart';
import 'package:app/src/features/verification/providers/verification_providers.dart';
import 'package:app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Supplier verification integration smoke', () {
    testWidgets('screen renders for signed-in supplier profile', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInSupplierAuthState()),
            ),
            userProfileProvider.overrideWith((ref) async => _supplierProfile),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const SupplierVerificationScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SupplierVerificationScreen), findsOneWidget);
    });

    testWidgets('supplierVerificationProvider is initially not loading', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) => Stream.value(_signedInSupplierAuthState()),
          ),
          userProfileProvider.overrideWith((ref) async => _supplierProfile),
          storageServiceProvider.overrideWithValue(FakeStorageService()),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(supplierVerificationProvider);
      expect(state.isLoading, isFalse);
    });
  });
}

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

const Map<String, dynamic> _supplierProfile = {
  'user_role_type': 'supplier',
  'verification_status': 'pending',
  'company_name': 'Test Supplier Pvt Ltd',
  'mobile': '+919999999999',
};

class FakeStorageService implements StorageService {
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
    return const Success('https://example.com/uploaded.pdf');
  }

  @override
  Future<Result<String>> uploadFileAtPath({
    required String bucketName,
    required String fullPath,
    required File file,
  }) async {
    return const Success('https://example.com/uploaded-at-path.pdf');
  }

  @override
  Future<Result<String>> uploadPrivateFileAtPath({
    required String bucketName,
    required String fullPath,
    required File file,
  }) async {
    return const Success('private/path/file.pdf');
  }

  @override
  Future<Result<String>> createSignedUrl({
    required String bucketName,
    required String filePath,
    int expiresInSeconds = 3600,
  }) async {
    return const Success('https://example.com/signed.pdf');
  }
}
