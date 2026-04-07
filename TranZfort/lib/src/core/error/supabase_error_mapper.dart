import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_failure.dart';

/// Shared Supabase error > AppFailure mapper used by all repositories.
///
/// Repositories that need additional domain-specific mapping can call this
/// as a fallback after their own checks.
AppFailure mapSupabaseError(Object error, StackTrace stackTrace) {
  if (error is AppFailure) {
    return error;
  }

  if (error is SocketException || error is TimeoutException) {
    return NetworkFailure(debugInfo: error.toString());
  }

  if (error is AuthException) {
    final message = error.message.trim();
    return UnauthorizedFailure(message: message, debugInfo: stackTrace.toString());
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

  if (error is Exception) {
    return ServerFailure(message: error.toString(), debugInfo: stackTrace.toString());
  }

  return UnknownFailure(debugInfo: '$error\n$stackTrace');
}
