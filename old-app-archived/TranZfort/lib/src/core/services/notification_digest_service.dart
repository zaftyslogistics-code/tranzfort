import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/app_failure.dart';
import '../error/result.dart';

/// Service to dispatch notification digests at cadence.
/// Intended to be called by a background job or edge function.
class NotificationDigestService {
  final SupabaseClient _supabase;

  const NotificationDigestService(this._supabase);

  /// Fetch ready digests and dispatch a batched notification per route.
  /// Returns the number of digests dispatched.
  Future<Result<int>> dispatchReadyDigests() async {
    try {
      final ready = await _supabase.rpc(
        'get_ready_notification_digests',
        params: {'p_now': DateTime.now().toIso8601String()},
      );

      final digests = (ready as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (digests.isEmpty) {
        return const Success(0);
      }

      int dispatched = 0;
      for (final digest in digests) {
        final success = await _sendBatchNotification(digest);
        if (success) {
          await _supabase.rpc(
            'mark_notification_digest_dispatched',
            params: {'p_digest_id': digest['id']},
          );
          dispatched++;
        }
      }

      return Success(dispatched);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  /// Build and send a single batched notification for a digest.
  Future<bool> _sendBatchNotification(Map<String, dynamic> digest) async {
    final userId = digest['user_id'] as String?;
    final routeKey = (digest['route_key'] ?? '').toString();
    final routeLabel = (digest['route_label'] ?? routeKey).toString();
    final count = (digest['digest_count'] as int?) ?? 0;
    final sampleBody = (digest['sample_body'] ?? '').toString();

    if (userId == null || userId.isEmpty) return false;

    final title = count == 1
        ? 'New update on $routeLabel'
        : '$count updates on $routeLabel';

    final body = count == 1
        ? sampleBody
        : 'You have $count new updates. Tap to view.';

    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': 'digest',
        'data': {
          'route_key': routeKey,
          'route_label': routeLabel,
          'digest_count': count,
        },
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Minimal error classifier for service layer.
AppFailureType classifyError(dynamic e) {
  if (e is PostgrestException) {
    return AppFailureType.network;
  }
  if (e is FormatException) {
    return AppFailureType.validation;
  }
  return AppFailureType.unknown;
}
