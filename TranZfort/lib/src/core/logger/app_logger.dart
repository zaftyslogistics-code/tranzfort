import 'package:flutter/foundation.dart';

/// Production-safe logger that only outputs in debug mode.
/// All logging is stripped in release builds to avoid performance impact.
class AppLogger {
  AppLogger._();

  static void info(String message, {String? scope}) {
    if (kDebugMode) {
      _log('INFO', message, scope: scope);
    }
  }

  static void warning(String message, {String? scope, Object? error}) {
    if (kDebugMode) {
      final buffer = StringBuffer(message);
      if (error != null) {
        buffer.write(' | error=$error');
      }
      _log('WARN', buffer.toString(), scope: scope);
    }
  }

  static void error(String message, {String? scope, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      final buffer = StringBuffer(message);

      if (error != null) {
        buffer.write(' | error=$error');
      }

      if (stackTrace != null) {
        buffer.write(' | stackTrace=$stackTrace');
      }

      _log('ERROR', buffer.toString(), scope: scope);
    }
  }

  static void _log(String level, String message, {String? scope}) {
    final prefix = scope == null || scope.isEmpty ? '[TranZfort][$level]' : '[TranZfort][$level][$scope]';
    debugPrint('$prefix $message');
  }
}
