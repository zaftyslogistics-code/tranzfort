import 'package:app/src/core/error/app_failure.dart';
import 'package:app/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth state models', () {
    test('AuthEntryState.copyWith updates loading and error fields', () {
      const initial = AuthEntryState();
      final withError = initial.copyWith(lastError: AppFailureType.network);

      expect(withError.isLoading, isFalse);
      expect(withError.lastError, AppFailureType.network);

      final loading = withError.copyWith(isLoading: true);
      expect(loading.isLoading, isTrue);
      expect(loading.lastError, AppFailureType.network);

      final cleared = loading.copyWith(clearError: true);
      expect(cleared.lastError, isNull);
    });

    test('OtpVerificationState.copyWith updates verification and error fields', () {
      const initial = OtpVerificationState();
      final withError = initial.copyWith(lastError: AppFailureType.auth);

      expect(withError.isVerifying, isFalse);
      expect(withError.lastError, AppFailureType.auth);

      final verifying = withError.copyWith(isVerifying: true);
      expect(verifying.isVerifying, isTrue);
      expect(verifying.lastError, AppFailureType.auth);

      final cleared = verifying.copyWith(clearError: true);
      expect(cleared.lastError, isNull);
    });

    test('RoleSetupState.copyWith updates submit and error fields', () {
      const initial = RoleSetupState();
      final withError = initial.copyWith(lastError: AppFailureType.validation);

      expect(withError.isSubmitting, isFalse);
      expect(withError.lastError, AppFailureType.validation);

      final submitting = withError.copyWith(isSubmitting: true);
      expect(submitting.isSubmitting, isTrue);
      expect(submitting.lastError, AppFailureType.validation);

      final cleared = submitting.copyWith(clearError: true);
      expect(cleared.lastError, isNull);
    });
  });
}
