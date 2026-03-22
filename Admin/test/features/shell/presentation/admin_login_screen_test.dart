import 'package:admin/src/core/repositories/admin_auth_repository.dart';
import 'package:admin/src/features/shell/presentation/admin_shell_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminAuthRepository extends AdminAuthRepository {
  final AdminSignInResult signInResult;
  final bool passwordResetResult;
  int signInCalls = 0;
  int resetCalls = 0;

  _FakeAdminAuthRepository({
    required this.signInResult,
    this.passwordResetResult = true,
  }) : super(
          backend: const _UnusedAuthBackend(),
        );

  @override
  Future<AdminSignInResult> signInWithPassword({required String email, required String password}) async {
    signInCalls += 1;
    return signInResult;
  }

  @override
  Future<bool> requestPasswordReset({required String email}) async {
    resetCalls += 1;
    return passwordResetResult;
  }
}

class _UnusedAuthBackend implements AdminAuthBackend {
  const _UnusedAuthBackend();

  @override
  Future<Map<String, dynamic>?> fetchAdminAccessRow({required String authUserId}) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    throw UnimplementedError();
  }

  @override
  Future<String?> signInWithPassword({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('admin login screen validates and submits credentials', (tester) async {
    final repository = _FakeAdminAuthRepository(
      signInResult: AdminSignInResult.failure(AdminSignInFailureReason.invalidCredentials),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminAuthRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: AdminLoginScreen()),
      ),
    );

    expect(find.text('Admin Login'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'ops@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong-password');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(repository.signInCalls, 1);
    expect(find.text('We could not sign you in with those admin credentials. Check your email and password and try again.'), findsOneWidget);
  });

  testWidgets('admin login screen triggers password reset feedback', (tester) async {
    final repository = _FakeAdminAuthRepository(
      signInResult: AdminSignInResult.failure(AdminSignInFailureReason.invalidCredentials),
      passwordResetResult: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminAuthRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: AdminLoginScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'ops@example.com');
    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot password?'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(repository.resetCalls, 1);
    expect(find.text('Password reset instructions have been sent to your admin email.'), findsOneWidget);
  });
}
