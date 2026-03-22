import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void info(String message, {String? scope}) {
    _log('INFO', message, scope: scope);
  }

  static void warning(String message, {String? scope}) {
    _log('WARN', message, scope: scope);
  }

  static void error(String message, {String? scope, Object? error, StackTrace? stackTrace}) {
    final buffer = StringBuffer(message);

    if (error != null) {
      buffer.write(' | error=$error');
    }

    if (stackTrace != null) {
      buffer.write(' | stackTrace=$stackTrace');
    }

    _log('ERROR', buffer.toString(), scope: scope);
  }

  static void _log(String level, String message, {String? scope}) {
    final prefix = scope == null || scope.isEmpty ? '[TranZfort][$level]' : '[TranZfort][$level][$scope]';
    debugPrint('$prefix $message');
  }
}
