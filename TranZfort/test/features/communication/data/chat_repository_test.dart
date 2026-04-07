import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/communication/data/chat_repository.dart';

class _FakeChatBackend implements ChatBackend {
  List<Map<String, dynamic>> conversationRows = const <Map<String, dynamic>>[];
  final Map<String, List<Map<String, dynamic>>> messagesByConversation = <String, List<Map<String, dynamic>>>{};
  final Map<String, Map<String, dynamic>?> latestMessageByConversation = <String, Map<String, dynamic>?>{};
  final Map<String, bool> unreadByConversation = <String, bool>{};
  final Map<String, Map<String, dynamic>?> loadContextById = <String, Map<String, dynamic>?>{};
  final Map<String, Map<String, dynamic>?> profileById = <String, Map<String, dynamic>?>{};
  final Map<String, Map<String, dynamic>?> supplierExtensionById = <String, Map<String, dynamic>?>{};
  final Map<String, Map<String, dynamic>?> bookingContextByLoadAndTrucker = <String, Map<String, dynamic>?>{};
  Object? error;
  String createConversationResult = 'conversation-1';
  String sendMessageResult = 'message-1';
  String? sentConversationId;
  ChatMessageType? sentType;
  String? sentMessageId;
  String? sentTextBody;
  String? sentAttachmentPath;
  Map<String, dynamic>? sentStructuredPayload;
  String? markedReadConversationId;
  String? markedReadReaderId;

  @override
  Future<List<Map<String, dynamic>>> fetchConversations({required String userId, required AppUserRole role}) async {
    if (error != null) {
      throw error!;
    }
    return conversationRows;
  }

  @override
  Stream<List<Map<String, dynamic>>> watchConversations({required String userId, required AppUserRole role}) {
    return const Stream<List<Map<String, dynamic>>>.empty();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMessages({required String conversationId}) async {
    if (error != null) {
      throw error!;
    }
    return messagesByConversation[conversationId] ?? const <Map<String, dynamic>>[];
  }

  @override
  Stream<List<Map<String, dynamic>>> watchMessages({required String conversationId}) {
    return const Stream<List<Map<String, dynamic>>>.empty();
  }

  @override
  Future<Map<String, dynamic>?> fetchLatestMessage({required String conversationId}) async {
    return latestMessageByConversation[conversationId];
  }

  @override
  Future<bool> fetchHasUnread({required String conversationId, required String currentUserId}) async {
    return unreadByConversation[conversationId] ?? false;
  }

  @override
  Future<Map<String, dynamic>?> fetchLoadContext(String loadId) async => loadContextById[loadId];

  @override
  Future<Map<String, dynamic>?> fetchProfile(String profileId) async => profileById[profileId];

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId) async => supplierExtensionById[supplierId];

  @override
  Future<Map<String, dynamic>?> fetchBookingContext({required String loadId, required String truckerId}) async {
    return bookingContextByLoadAndTrucker['$loadId|$truckerId'];
  }

  @override
  Future<String> createOrGetConversation({required String supplierId, required String truckerId, required String loadId}) async {
    if (error != null) {
      throw error!;
    }
    return createConversationResult;
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
    if (error != null) {
      throw error!;
    }
    sentConversationId = conversationId;
    sentType = type;
    sentMessageId = messageId;
    sentTextBody = textBody;
    sentAttachmentPath = attachmentPath;
    sentStructuredPayload = structuredPayload;
    return sendMessageResult;
  }

  @override
  Future<void> markMessagesRead({required String conversationId, required String readerId}) async {
    if (error != null) {
      throw error!;
    }
    markedReadConversationId = conversationId;
    markedReadReaderId = readerId;
  }

  @override
  Future<int> fetchUnreadConversationCount() async {
    if (error != null) {
      throw error!;
    }
    return conversationRows.where((row) => row['has_unread'] == true).length;
  }
}

void main() {
  test('chat repository maps conversation previews', () async {
    final backend = _FakeChatBackend()
      ..conversationRows = [
        {
          'id': 'conversation-1',
          'supplier_id': 'supplier-1',
          'trucker_id': 'trucker-1',
          'load_id': 'load-1',
          'trip_id': 'trip-1',
          'last_message_at': '2026-03-10T09:00:00.000Z',
          'is_archived': false,
          'created_at': '2026-03-10T08:00:00.000Z',
        },
      ]
      ..loadContextById['load-1'] = {
        'id': 'load-1',
        'origin_label': 'Chandrapur, Maharashtra',
        'destination_label': 'Mumbai, Maharashtra',
        'material': 'Coal',
        'price_amount': 62500,
        'status': 'active',
        'pickup_date': '2026-03-11T00:00:00.000Z',
      }
      ..profileById['supplier-1'] = {
        'id': 'supplier-1',
        'full_name': 'Amit Supplier',
        'mobile': '+919876543210',
      }
      ..profileById['trucker-1'] = {
        'id': 'trucker-1',
        'full_name': 'Ravi Trucker',
        'mobile': '+919812345678',
      }
      ..supplierExtensionById['supplier-1'] = {
        'id': 'supplier-1',
        'company_name': 'Amit Logistics',
      }
      ..bookingContextByLoadAndTrucker['load-1|trucker-1'] = {
        'id': 'booking-1',
        'status': 'approved',
        'truck_id': 'truck-1',
        'trucks': {
          'truck_number': 'MH12AB1234',
          'truck_models': {
            'make': 'Tata',
            'model': 'Ace Gold',
          },
        },
      }
      ..latestMessageByConversation['conversation-1'] = {
        'id': 'message-1',
        'conversation_id': 'conversation-1',
        'sender_profile_id': 'supplier-1',
        'message_type': 'text',
        'text_body': 'Rate confirmed',
        'attachment_path': null,
        'structured_payload': null,
        'is_read': false,
        'read_at': null,
        'created_at': '2026-03-10T09:00:00.000Z',
      }
      ..unreadByConversation['conversation-1'] = true;
    final repository = ChatRepository(
      backend,
      () => 'supplier-1',
      () => AppUserRole.supplier,
    );

    final result = await repository.getConversations();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, hasLength(1));
    expect(result.valueOrNull!.first.routeLabel, 'Chandrapur, Maharashtra > Mumbai, Maharashtra');
    expect(result.valueOrNull!.first.loadMaterial, 'Coal');
    expect(result.valueOrNull!.first.loadPriceAmount, 62500);
    expect(result.valueOrNull!.first.loadStatusLabel, 'active');
    expect(result.valueOrNull!.first.supplierMobile, '+919876543210');
    expect(result.valueOrNull!.first.truckerMobile, '+919812345678');
    expect(result.valueOrNull!.first.supplierCompanyName, 'Amit Logistics');
    expect(result.valueOrNull!.first.bookingRequestId, 'booking-1');
    expect(result.valueOrNull!.first.truckDisplayLabel, 'MH12AB1234 - Tata Ace Gold');
    expect(result.valueOrNull!.first.bookingStatusLabel, 'approved');
    expect(result.valueOrNull!.first.latestMessagePreview, 'Rate confirmed');
    expect(result.valueOrNull!.first.hasUnread, isTrue);
  });

  test('chat repository maps RPC-backed conversation summary rows without N+1 context fetches', () async {
    final backend = _FakeChatBackend()
      ..conversationRows = [
        {
          'id': 'conversation-1',
          'supplier_id': 'supplier-1',
          'trucker_id': 'trucker-1',
          'load_id': 'load-1',
          'trip_id': 'trip-1',
          'route_label': 'Chandrapur, Maharashtra → Mumbai, Maharashtra',
          'load_material': 'Coal',
          'load_price_amount': 62500,
          'load_status_label': 'active',
          'pickup_date': '2026-03-11T00:00:00.000Z',
          'supplier_name': 'Amit Supplier',
          'supplier_mobile': '+919876543210',
          'supplier_company_name': 'Amit Logistics',
          'trucker_name': 'Ravi Trucker',
          'trucker_mobile': '+919812345678',
          'truck_display_label': 'MH12AB1234 • Tata Ace Gold',
          'booking_request_id': 'booking-1',
          'booking_status_label': 'approved',
          'latest_message_type': 'voice',
          'latest_message_text': null,
          'last_message_at': '2026-03-10T09:00:00.000Z',
          'has_unread': true,
          'is_archived': false,
          'created_at': '2026-03-10T08:00:00.000Z',
        },
      ];
    final repository = ChatRepository(
      backend,
      () => 'supplier-1',
      () => AppUserRole.supplier,
    );

    final result = await repository.getConversations();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, hasLength(1));
    expect(result.valueOrNull!.first.routeLabel, 'Chandrapur, Maharashtra → Mumbai, Maharashtra');
    expect(result.valueOrNull!.first.latestMessagePreview, 'Voice message');
    expect(result.valueOrNull!.first.hasUnread, isTrue);
  });

  test('chat repository returns unread conversation count from summary rows', () async {
    final backend = _FakeChatBackend()
      ..conversationRows = [
        {'id': 'conversation-1', 'has_unread': true},
        {'id': 'conversation-2', 'has_unread': false},
        {'id': 'conversation-3', 'has_unread': true},
      ];
    final repository = ChatRepository(
      backend,
      () => 'supplier-1',
      () => AppUserRole.supplier,
    );

    final result = await repository.getUnreadConversationCount();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 2);
  });

  test('chat repository maps messages with sender ownership', () async {
    final backend = _FakeChatBackend()
      ..messagesByConversation['conversation-1'] = [
        {
          'id': 'message-1',
          'conversation_id': 'conversation-1',
          'sender_profile_id': 'supplier-1',
          'message_type': 'text',
          'text_body': 'Hello',
          'attachment_path': null,
          'structured_payload': null,
          'is_read': true,
          'read_at': '2026-03-10T09:01:00.000Z',
          'created_at': '2026-03-10T09:00:00.000Z',
        },
      ];
    final repository = ChatRepository(
      backend,
      () => 'supplier-1',
      () => AppUserRole.supplier,
    );

    final result = await repository.getMessages('conversation-1');

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.first.isFromCurrentUser, isTrue);
    expect(result.valueOrNull!.first.textBody, 'Hello');
  });

  test('chat repository sends text message', () async {
    final backend = _FakeChatBackend();
    final repository = ChatRepository(
      backend,
      () => 'supplier-1',
      () => AppUserRole.supplier,
    );

    final result = await repository.sendTextMessage(
      conversationId: 'conversation-1',
      text: 'Need unloading update',
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 'message-1');
    expect(backend.sentConversationId, 'conversation-1');
    expect(backend.sentType, ChatMessageType.text);
    expect(backend.sentTextBody, 'Need unloading update');
  });

  test('chat repository sends voice message', () async {
    final backend = _FakeChatBackend();
    final repository = ChatRepository(
      backend,
      () => 'supplier-1',
      () => AppUserRole.supplier,
    );

    final result = await repository.sendVoiceMessage(
      conversationId: 'conversation-1',
      messageId: 'message-voice-1',
      attachmentPath: 'communication-media/conversation-1/message-voice-1.m4a',
      structuredPayload: {'voice_duration_seconds': 12},
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 'message-1');
    expect(backend.sentConversationId, 'conversation-1');
    expect(backend.sentType, ChatMessageType.voice);
    expect(backend.sentMessageId, 'message-voice-1');
    expect(backend.sentAttachmentPath, 'communication-media/conversation-1/message-voice-1.m4a');
    expect(backend.sentStructuredPayload, {'voice_duration_seconds': 12});
  });

  test('chat repository maps send failures', () async {
    final backend = _FakeChatBackend()
      ..error = const PostgrestException(message: 'Not a participant in this conversation');
    final repository = ChatRepository(
      backend,
      () => 'supplier-1',
      () => AppUserRole.supplier,
    );

    final result = await repository.sendTextMessage(
      conversationId: 'conversation-1',
      text: 'Need unloading update',
    );

    expect(result.failureOrNull, isA<PermissionFailure>());
  });

  test('chat repository marks conversation read', () async {
    final backend = _FakeChatBackend();
    final repository = ChatRepository(
      backend,
      () => 'supplier-1',
      () => AppUserRole.supplier,
    );

    final result = await repository.markConversationRead('conversation-1');

    expect(result.isSuccess, isTrue);
    expect(backend.markedReadConversationId, 'conversation-1');
    expect(backend.markedReadReaderId, 'supplier-1');
  });
}
