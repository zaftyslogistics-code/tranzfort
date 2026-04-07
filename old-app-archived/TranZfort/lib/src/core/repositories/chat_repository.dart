import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/app_failure.dart';
import '../error/result.dart';

class ChatRepository {
  final SupabaseClient _supabase;

  ChatRepository(this._supabase);

  Future<Result<List<Map<String, dynamic>>>> getConversations() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return const Failure(
          AppFailureType.auth,
          debugMessage: 'Not logged in',
        );
      }
      final response = await _supabase
          .from('conversations')
          .select('''
            *,
            load:loads(origin_city, dest_city, material),
            supplier:suppliers(profiles(full_name)),
            trucker:truckers(profiles(full_name))
          ''')
          .or('supplier_id.eq.${user.id},trucker_id.eq.${user.id}')
          .order('last_message_at', ascending: false);

      return Success(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<Map<String, int>>> getUnreadCountsByConversation() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return const Failure(
          AppFailureType.auth,
          debugMessage: 'Not logged in',
        );
      }

      final rows = await _supabase
          .from('messages')
          .select('conversation_id')
          .eq('is_read', false)
          .neq('sender_id', user.id);

      final counts = <String, int>{};
      for (final row in rows) {
        final conversationId = (row['conversation_id'] ?? '').toString();
        if (conversationId.isEmpty) {
          continue;
        }
        counts.update(conversationId, (value) => value + 1, ifAbsent: () => 1);
      }

      return Success(counts);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<List<Map<String, dynamic>>>> getMessages(
    String conversationId,
  ) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      return Success(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<Map<String, dynamic>>> sendMessage({
    required String conversationId,
    required String senderId,
    required String messageType,
    String? textContent,
    Map<String, dynamic>? payload,
    String? voiceUrl,
    int? voiceDurationSeconds,
  }) async {
    try {
      final response = await _supabase
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': senderId,
            'message_type': messageType,
            'text_content': textContent,
            'payload': payload,
            'voice_url': voiceUrl,
            'voice_duration_seconds': voiceDurationSeconds,
          })
          .select()
          .single();

      return Success(response);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> markMessagesAsRead(
    String conversationId,
    String currentUserId,
  ) async {
    try {
      await _supabase
          .from('messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('conversation_id', conversationId)
          .neq('sender_id', currentUserId)
          .eq('is_read', false);

      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<Map<String, dynamic>>> getOrCreateConversation({
    required String loadId,
    required String supplierId,
    required String truckerId,
  }) async {
    try {
      final existing = await _supabase
          .from('conversations')
          .select()
          .eq('load_id', loadId)
          .eq('supplier_id', supplierId)
          .eq('trucker_id', truckerId)
          .maybeSingle();

      if (existing != null) {
        return Success(existing);
      }

      final created = await _supabase
          .from('conversations')
          .insert({
            'load_id': loadId,
            'supplier_id': supplierId,
            'trucker_id': truckerId,
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Success(created);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<Map<String, dynamic>>> getConversationById(
    String conversationId,
  ) async {
    try {
      final response = await _supabase
          .from('conversations')
          .select('''
            id,
            load_id,
            supplier_id,
            trucker_id,
            load:loads(id, origin_city, dest_city, material)
          ''')
          .eq('id', conversationId)
          .single();

      return Success(response);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function(List<Map<String, dynamic>>) onMessagesUpdate,
  ) {
    return _supabase
        .channel('public:messages:conversation_id=eq.$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            // We just trigger a re-fetch for simplicity in V1, or we could append the payload.new row.
            // A common Riverpod pattern is to just invalidate the provider and refetch,
            // but we can pass an empty list signal to let the provider know to refetch.
            onMessagesUpdate([]);
          },
        )
        .subscribe();
  }
}
