import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';

AppFailure mapAuthError(Object error, StackTrace stackTrace) {
  if (error is SocketException || error is TimeoutException) {
    return NetworkFailure(debugInfo: error.toString());
  }

  if (error is AuthException) {
    final message = error.message.trim();
    final normalized = message.toLowerCase();

    if (normalized.contains('session') ||
        normalized.contains('expired') ||
        normalized.contains('refresh token') ||
        normalized.contains('refresh_token_not_found')) {
      return UnauthorizedFailure(message: message, debugInfo: stackTrace.toString());
    }

    if (normalized.contains('email not confirmed') ||
        normalized.contains('email not verified') ||
        normalized.contains('confirm your email') ||
        normalized.contains('email confirmation')) {
      return const BusinessRuleFailure(
        message:
            'Confirm your email before signing in. Open the verification email from TranZfort, finish verification, and then try again.',
      );
    }

    if (normalized.contains('redirect') || normalized.contains('oauth')) {
      return const BusinessRuleFailure(
        message:
            'Google auth redirect failed. Please update Supabase Google provider settings and Android client configuration, then retry.',
      );
    }

    if (normalized.contains('invalid')) {
      return ValidationFailure(
        message: message,
        debugInfo: stackTrace.toString(),
      );
    }

    return UnknownFailure(message: message, debugInfo: stackTrace.toString());
  }

  if (error is PostgrestException) {
    final code = error.code?.trim();
    final message = error.message.trim().isEmpty
        ? 'Something went wrong. Please try again.'
        : error.message.trim();
    final details = error.details?.toString();

    if (code == '42501') {
      return PermissionFailure(message: message, debugInfo: details);
    }

    if (code == '23505') {
      return ConflictFailure(message: message, debugInfo: details);
    }

    if (code == 'PGRST116') {
      return NotFoundFailure(message: message, debugInfo: details);
    }

    return ServerFailure(message: message, debugInfo: details);
  }

  return UnknownFailure(
    debugInfo: '$error\n$stackTrace',
  );
}
