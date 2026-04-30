import 'package:flutter/foundation.dart';

import 'pii_redaction.dart';

/// Production-safe logger that outputs in debug mode with full details,
/// and in release mode with PII redacted for production debugging.
class AppLogger {
  AppLogger._();

  static void info(String message, {String? scope}) {
    final redactedMessage = PiiRedaction.redact(message);
    _log('INFO', redactedMessage, scope: scope);
  }

  static void warning(String message, {String? scope, Object? error}) {
    final redactedMessage = PiiRedaction.redact(message);
    final buffer = StringBuffer(redactedMessage);

    if (error != null) {
      // Redact error message as it may contain PII
      final redactedError = PiiRedaction.redact(error.toString());
      buffer.write(' | error=$redactedError');
    }

    _log('WARN', buffer.toString(), scope: scope);
  }

  static void error(String message, {String? scope, Object? error, StackTrace? stackTrace}) {
    final redactedMessage = PiiRedaction.redact(message);
    final buffer = StringBuffer(redactedMessage);

    if (error != null) {
      // Redact error message as it may contain PII
      final redactedError = PiiRedaction.redact(error.toString());
      buffer.write(' | error=$redactedError');
    }

    if (stackTrace != null) {
      // Stack traces may contain file paths with user data, redact in release
      final redactedStackTrace = kDebugMode ? stackTrace : '[STACK_TRACE_REDACTED]';
      buffer.write(' | stackTrace=$redactedStackTrace');
    }

    _log('ERROR', buffer.toString(), scope: scope);
  }

  static void _log(String level, String message, {String? scope}) {
    final prefix = scope == null || scope.isEmpty ? '[TranZfort][$level]' : '[TranZfort][$level][$scope]';
    debugPrint('$prefix $message');
  }
}
