import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../logger/app_logger.dart';

part 'crash_reporting_service.g.dart';

/// Crash reporting service for Firebase Crashlytics
///
/// Provides methods to:
/// - Set user identifier for crash grouping
/// - Record custom errors
/// - Set custom keys for crash context
/// - Enable/disable crash reporting
@Riverpod(keepAlive: true)
class CrashReportingService extends _$CrashReportingService {
  @override
  CrashReportingService build() {
    return CrashReportingService();
  }

  /// Set user identifier for better crash grouping
  /// Call this after user authentication
  Future<void> setUserIdentifier(String userId) async {
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    } catch (error) {
      // Silently fail - crash reporting should not break app
      AppLogger.warning('Failed to set user identifier', scope: 'crashlytics', error: error);
    }
  }

  /// Set custom key for crash context
  /// Useful for adding app state information to crash reports
  Future<void> setCustomKey(String key, String value) async {
    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (error) {
      AppLogger.warning('Failed to set custom key', scope: 'crashlytics', error: error);
    }
  }

  /// Record a non-fatal error
  /// Use this for caught errors that you still want to track
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, dynamic>? context,
  }) async {
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace ?? StackTrace.current,
        fatal: fatal,
      );
      
      // Set custom keys if context provided
      if (context != null) {
        for (final entry in context.entries) {
          await setCustomKey(entry.key, entry.value.toString());
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to record error', scope: 'crashlytics', error: e);
    }
  }

  /// Enable/disable crash reporting
  /// Useful for debugging or privacy concerns
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
    } catch (error) {
      AppLogger.warning('Failed to set crashlytics collection', scope: 'crashlytics', error: error);
    }
  }

  /// Log a message to Crashlytics
  /// Useful for debugging without throwing an error
  Future<void> log(String message) async {
    try {
      await FirebaseCrashlytics.instance.log(message);
    } catch (error) {
      AppLogger.warning('Failed to log message', scope: 'crashlytics', error: error);
    }
  }
}
