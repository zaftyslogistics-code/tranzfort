import 'package:admin/src/core/providers/admin_app_state_providers.dart';
import 'package:admin/src/core/repositories/admin_auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAdminAuthBackend implements AdminAuthBackend {
  String? signInUserId;
  Object? signInError;
  bool signOutCalled = false;
  bool resetCalled = false;
  Map<String, dynamic>? adminRow;
  String? lastSignInEmail;
  String? lastResetEmail;

  @override
  Future<Map<String, dynamic>?> fetchAdminAccessRow({required String authUserId}) async {
    return adminRow;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    resetCalled = true;
    lastResetEmail = email;
  }

  @override
  Future<String?> signInWithPassword({required String email, required String password}) async {
    if (signInError != null) {
      throw signInError!;
    }
    lastSignInEmail = email;
    return signInUserId;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

void main() {
  group('AdminAuthRepository', () {
    test('returns success for active authorized admin', () async {
      final backend = _FakeAdminAuthBackend()
        ..signInUserId = 'admin-auth-1'
        ..adminRow = {
          'role': 'ops_admin',
          'is_active': true,
        };

      final container = ProviderContainer(
        overrides: [
          adminAuthBackendProvider.overrideWithValue(backend),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(adminAuthRepositoryProvider);
      final result = await repository.signInWithPassword(
        email: 'ops@example.com',
        password: 'secret123',
      );

      expect(result.isSuccess, isTrue);
      expect(result.snapshot?.role, AdminRole.opsAdmin);
      expect(backend.signOutCalled, isFalse);
      expect(backend.lastSignInEmail, 'ops@example.com');
    });

    test('normalizes admin email before sign-in and password reset', () async {
      final backend = _FakeAdminAuthBackend()
        ..signInUserId = 'admin-auth-4'
        ..adminRow = {
          'role': 'ops_admin',
          'is_active': true,
        };

      final container = ProviderContainer(
        overrides: [
          adminAuthBackendProvider.overrideWithValue(backend),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(adminAuthRepositoryProvider);
      final signInResult = await repository.signInWithPassword(
        email: '  Ops@Example.COM  ',
        password: 'secret123',
      );
      final resetResult = await repository.requestPasswordReset(
        email: '  Ops@Example.COM  ',
      );

      expect(signInResult.isSuccess, isTrue);
      expect(resetResult, isTrue);
      expect(backend.lastSignInEmail, 'ops@example.com');
      expect(backend.lastResetEmail, 'ops@example.com');
    });

    test('signs out unauthorized admin with no row', () async {
      final backend = _FakeAdminAuthBackend()
        ..signInUserId = 'admin-auth-2';

      final container = ProviderContainer(
        overrides: [
          adminAuthBackendProvider.overrideWithValue(backend),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(adminAuthRepositoryProvider);
      final result = await repository.signInWithPassword(
        email: 'unknown@example.com',
        password: 'secret123',
      );

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, AdminSignInFailureReason.notAuthorized);
      expect(backend.signOutCalled, isTrue);
    });

    test('signs out deactivated admin', () async {
      final backend = _FakeAdminAuthBackend()
        ..signInUserId = 'admin-auth-3'
        ..adminRow = {
          'role': 'super_admin',
          'is_active': false,
        };

      final container = ProviderContainer(
        overrides: [
          adminAuthBackendProvider.overrideWithValue(backend),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(adminAuthRepositoryProvider);
      final result = await repository.signInWithPassword(
        email: 'inactive@example.com',
        password: 'secret123',
      );

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, AdminSignInFailureReason.deactivated);
      expect(backend.signOutCalled, isTrue);
    });

    test('maps auth exception to invalid credentials', () async {
      final backend = _FakeAdminAuthBackend()
        ..signInError = const AuthException('Invalid login credentials');

      final container = ProviderContainer(
        overrides: [
          adminAuthBackendProvider.overrideWithValue(backend),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(adminAuthRepositoryProvider);
      final result = await repository.signInWithPassword(
        email: 'ops@example.com',
        password: 'wrong-password',
      );

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, AdminSignInFailureReason.invalidCredentials);
    });
  });
}
