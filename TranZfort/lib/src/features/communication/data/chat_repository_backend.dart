import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/app_state_providers.dart';
import 'chat_repository_models.dart';

abstract class ChatBackend {
  Future<List<Map<String, dynamic>>> fetchConversations({
    required String userId,
    required AppUserRole role,
  });

  Stream<List<Map<String, dynamic>>> watchConversations({
    required String userId,
    required AppUserRole role,
  });

  Future<List<Map<String, dynamic>>> fetchMessages({
    required String conversationId,
  });

  Stream<List<Map<String, dynamic>>> watchMessages({
    required String conversationId,
  });

  Future<Map<String, dynamic>?> fetchLatestMessage({
    required String conversationId,
  });

  Future<bool> fetchHasUnread({
    required String conversationId,
    required String currentUserId,
  });

  Future<Map<String, dynamic>?> fetchLoadContext(String loadId);

  Future<Map<String, dynamic>?> fetchProfile(String profileId);

  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId);

  Future<Map<String, dynamic>?> fetchBookingContext({
    required String loadId,
    required String truckerId,
  });

  Future<String> createOrGetConversation({
    required String supplierId,
    required String truckerId,
    required String loadId,
  });

  Future<String> sendMessage({
    required String conversationId,
    required ChatMessageType type,
    String? messageId,
    String? textBody,
    String? attachmentPath,
    Map<String, dynamic>? structuredPayload,
  });

  Future<void> markMessagesRead({
    required String conversationId,
    required String readerId,
  });

  Future<int> fetchUnreadConversationCount();
}

class SupabaseChatBackend implements ChatBackend {
  final SupabaseClient? _client;

  const SupabaseChatBackend(this._client);

  @override
  Future<List<Map<String, dynamic>>> fetchConversations({
    required String userId,
    required AppUserRole role,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc('get_current_user_conversation_summaries');
    return response.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchConversations({
    required String userId,
    required AppUserRole role,
  }) {
    if (_client == null) {
      return Stream<List<Map<String, dynamic>>>.value(const <Map<String, dynamic>>[]);
    }

    return _client
        .from('conversations')
        .stream(primaryKey: const ['id'])
        .eq(role == AppUserRole.supplier ? 'supplier_id' : 'trucker_id', userId)
        .map((rows) => rows.whereType<Map<String, dynamic>>().toList(growable: false));
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMessages({required String conversationId}) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client
        .from('messages')
        .select('id, conversation_id, sender_profile_id, message_type, text_body, attachment_path, structured_payload, is_read, read_at, created_at')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return response.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchMessages({required String conversationId}) {
    if (_client == null) {
      return Stream<List<Map<String, dynamic>>>.value(const <Map<String, dynamic>>[]);
    }

    return _client
        .from('messages')
        .stream(primaryKey: const ['id'])
        .eq('conversation_id', conversationId)
        .map((rows) {
      final maps = rows.whereType<Map<String, dynamic>>().toList(growable: false);
      maps.sort((a, b) => (a['created_at'] ?? '').toString().compareTo((b['created_at'] ?? '').toString()));
      return maps;
    });
  }

  @override
  Future<Map<String, dynamic>?> fetchLatestMessage({required String conversationId}) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    return _client
        .from('messages')
        .select('id, conversation_id, sender_profile_id, message_type, text_body, attachment_path, structured_payload, is_read, read_at, created_at')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  @override
  Future<bool> fetchHasUnread({
    required String conversationId,
    required String currentUserId,
  }) async {
    if (_client == null) {
      return false;
    }

    final row = await _client
        .from('messages')
        .select('id')
        .eq('conversation_id', conversationId)
        .neq('sender_profile_id', currentUserId)
        .eq('is_read', false)
        .limit(1)
        .maybeSingle();

    return row != null;
  }

  @override
  Future<Map<String, dynamic>?> fetchLoadContext(String loadId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    return _client
        .from('loads')
        .select('id, origin_label, destination_label, material, price_amount, status, pickup_date')
        .eq('id', loadId)
        .maybeSingle();
  }

  @override
  Future<Map<String, dynamic>?> fetchProfile(String profileId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    return _client
        .from('profiles')
        .select('id, full_name, mobile, verification_status')
        .eq('id', profileId)
        .maybeSingle();
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    return _client
        .from('suppliers')
        .select('id, company_name')
        .eq('id', supplierId)
        .maybeSingle();
  }

  @override
  Future<Map<String, dynamic>?> fetchBookingContext({
    required String loadId,
    required String truckerId,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    return _client
        .from('booking_requests')
        .select(
          'id, status, truck_id, trucks(truck_number, truck_models(make, model))',
        )
        .eq('load_id', loadId)
        .eq('trucker_id', truckerId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  @override
  Future<String> createOrGetConversation({
    required String supplierId,
    required String truckerId,
    required String loadId,
  }) async {
    if (_client == null) {
      return '';
    }

    final response = await _client.rpc(
      'create_or_get_conversation',
      params: <String, dynamic>{
        'p_supplier_id': supplierId,
        'p_trucker_id': truckerId,
        'p_load_id': loadId,
      },
    );
    return (response ?? '').toString();
  }

  @override
  Future<String> sendMessage({
    required String conversationId,
    required ChatMessageType type,
    String? messageId,
    String? textBody,
    String? attachmentPath,
    Map<String, dynamic>? structuredPayload,
  }) async {
    if (_client == null) {
      return '';
    }

    final response = await _client.rpc(
      'send_message',
      params: <String, dynamic>{
        'p_conversation_id': conversationId,
        'p_message_type': type.databaseValue,
        'p_message_id': messageId,
        'p_text_body': textBody,
        'p_attachment_path': attachmentPath,
        'p_structured_payload': structuredPayload,
      },
    );
    return (response ?? '').toString();
  }

  @override
  Future<int> fetchUnreadConversationCount() async {
    if (_client == null) {
      return 0;
    }

    final response = await _client.rpc('get_current_user_unread_conversation_count');
    return (response as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> markMessagesRead({
    required String conversationId,
    required String readerId,
  }) async {
    if (_client == null) {
      return;
    }

    await _client
        .from('messages')
        .update(<String, dynamic>{
          'is_read': true,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('conversation_id', conversationId)
        .neq('sender_profile_id', readerId)
        .eq('is_read', false);
  }
}
