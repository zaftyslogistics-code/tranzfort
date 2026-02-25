import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/app_failure.dart';
import '../error/result.dart';

class NotificationRepository {
  final SupabaseClient _supabase;

  NotificationRepository(this._supabase);

  Future<Result<List<Map<String, dynamic>>>> getNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return Success(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }
}
