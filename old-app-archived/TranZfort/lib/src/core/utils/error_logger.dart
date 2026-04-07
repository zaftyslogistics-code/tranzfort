import 'package:flutter/foundation.dart';

/// Centralized error logging utility for the application.
/// Provides structured logging with context and severity levels.
class ErrorLogger {
  /// Log levels for categorizing errors
  static const String levelError = 'ERROR';
  static const String levelWarning = 'WARNING';
  static const String levelInfo = 'INFO';
  static const String levelDebug = 'DEBUG';

  /// Log an error with context
  static void logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(
      level: levelError,
      message: message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Log a warning
  static void logWarning(
    String message, {
    Map<String, dynamic>? context,
  }) {
    _log(
      level: levelWarning,
      message: message,
      context: context,
    );
  }

  /// Log informational message
  static void logInfo(
    String message, {
    Map<String, dynamic>? context,
  }) {
    _log(
      level: levelInfo,
      message: message,
      context: context,
    );
  }

  /// Log debug message (only in debug mode)
  static void logDebug(
    String message, {
    Map<String, dynamic>? context,
  }) {
    if (kDebugMode) {
      _log(
        level: levelDebug,
        message: message,
        context: context,
      );
    }
  }

  /// Internal logging method
  static void _log({
    required String level,
    required String message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final buffer = StringBuffer();

    buffer.write('[$timestamp] [$level] $message');

    if (context != null && context.isNotEmpty) {
      buffer.write(' | Context: ${_formatContext(context)}');
    }

    if (error != null) {
      buffer.write(' | Error: $error');
    }

    debugPrint(buffer.toString());

    if (stackTrace != null && kDebugMode) {
      debugPrint('StackTrace: $stackTrace');
    }

    // TODO: In production, send to crash reporting service (e.g., Sentry, Firebase Crashlytics)
  }

  /// Format context map for logging
  static String _formatContext(Map<String, dynamic> context) {
    return context.entries
        .map((e) => '${e.key}=${e.value}')
        .join(', ');
  }

  /// Log authentication-related errors
  static void logAuthError(
    String message, {
    String? userId,
    Object? error,
    StackTrace? stackTrace,
  }) {
    logError(
      message,
      error: error,
      stackTrace: stackTrace,
      context: {
        'module': 'auth',
        ...?userId != null ? {'userId': userId} : null,
      },
    );
  }

  /// Log repository-related errors
  static void logRepositoryError(
    String repository,
    String operation,
    Object error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalContext,
  }) {
    logError(
      'Repository operation failed',
      error: error,
      stackTrace: stackTrace,
      context: {
        'module': 'repository',
        'repository': repository,
        'operation': operation,
        ...?additionalContext,
      },
    );
  }

  /// Log network-related errors
  static void logNetworkError(
    String endpoint,
    Object error, {
    int? statusCode,
    StackTrace? stackTrace,
  }) {
    logError(
      'Network request failed',
      error: error,
      stackTrace: stackTrace,
      context: {
        'module': 'network',
        'endpoint': endpoint,
        ...?statusCode != null ? {'statusCode': statusCode} : null,
      },
    );
  }

  /// Log UI-related errors
  static void logUIError(
    String screen,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    logError(
      message,
      error: error,
      stackTrace: stackTrace,
      context: {
        'module': 'ui',
        'screen': screen,
      },
    );
  }
}
