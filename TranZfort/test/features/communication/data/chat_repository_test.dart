import 'package:async/async.dart' hide Result;
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/communication/data/chat_repository.dart';

import '../../../core/mocks.dart';

void main() {
  test('chat repository maps conversation previews', () async {
    final backend = MockChatBackend()
      ..conversationRows = [
        {
          'id': 'conversation-1',
          'supplier_id': 'supplier-1',
          'trucker_id': 'trucker-1',
          'load_id': 'load-1',
          'trip_id': 'trip-1',
          'route_label': 'Chandrapur, Maharashtra > Mumbai, Maharashtra',
          'load_material': 'Coal',
          'load_price_amount': 62500,
          'load_status_label': 'active',
          'pickup_date': '2026-03-11T00:00:00.000Z',
          'supplier_name': 'Amit Supplier',
          'supplier_mobile': '+919876543210',
          'supplier_company_name': 'Amit Logistics',
          'trucker_name': 'Ravi Trucker',
          'trucker_mobile': '+919812345678',
          'truck_display_label': 'MH12AB1234 - Tata Ace Gold',
          'booking_request_id': 'booking-1',
          'booking_status_label': 'approved',
          'latest_message_type': 'text',
          'latest_message_text': 'Rate confirmed',
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
    final backend = MockChatBackend()
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
    final backend = MockChatBackend()
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

  test('chat repository incrementally refreshes only changed conversation summaries from realtime rows', () async {
    final backend = MockChatBackend()
      ..conversationRows = [
        {
          'id': 'conversation-1',
          'supplier_id': 'supplier-1',
          'trucker_id': 'trucker-1',
          'load_id': 'load-1',
          'trip_id': 'trip-1',
          'route_label': 'Chandrapur, Maharashtra > Mumbai, Maharashtra',
          'load_material': 'Coal',
          'load_price_amount': 62500,
          'load_status_label': 'active',
          'pickup_date': '2026-03-11T00:00:00.000Z',
          'supplier_name': 'Amit Supplier',
          'supplier_mobile': '+919876543210',
          'supplier_company_name': 'Amit Logistics',
          'trucker_name': 'Ravi Trucker',
          'trucker_mobile': '+919812345678',
          'truck_display_label': 'MH12AB1234 - Tata Ace Gold',
          'booking_request_id': 'booking-1',
          'booking_status_label': 'approved',
          'latest_message_type': 'text',
          'latest_message_text': 'Old preview',
          'last_message_at': '2026-03-10T09:00:00.000Z',
          'has_unread': true,
          'is_archived': false,
          'created_at': '2026-03-10T08:00:00.000Z',
        },
      ]
      ..conversationData['conversation-1'] = {
        'id': 'conversation-1',
        'supplier_id': 'supplier-1',
        'trucker_id': 'trucker-1',
        'load_id': 'load-1',
        'trip_id': 'trip-1',
        'route_label': 'Chandrapur, Maharashtra > Mumbai, Maharashtra',
        'load_material': 'Coal',
        'load_price_amount': 62500,
        'load_status_label': 'active',
        'pickup_date': '2026-03-11T00:00:00.000Z',
        'supplier_name': 'Amit Supplier',
        'supplier_mobile': '+919876543210',
        'supplier_company_name': 'Amit Logistics',
        'trucker_name': 'Ravi Trucker',
        'trucker_mobile': '+919812345678',
        'truck_display_label': 'MH12AB1234 - Tata Ace Gold',
        'booking_request_id': 'booking-1',
        'booking_status_label': 'approved',
        'latest_message_type': 'text',
        'latest_message_text': 'Updated preview',
        'last_message_at': '2026-03-10T10:30:00.000Z',
        'has_unread': false,
        'is_archived': false,
        'created_at': '2026-03-10T08:00:00.000Z',
      };
    addTearDown(() async {
      await backend.conversationWatchController.close();
    });
    final repository = ChatRepository(
      backend,
      () => 'supplier-1',
      () => AppUserRole.supplier,
    );

    final queue = StreamQueue<Result<List<ConversationPreview>>>(repository.watchConversations());
    addTearDown(() async {
      await queue.cancel();
    });

    final initial = await queue.next;
    backend.conversationWatchController.add([
      {
        'id': 'conversation-1',
        'supplier_id': 'supplier-1',
        'trucker_id': 'trucker-1',
        'load_id': 'load-1',
        'trip_id': 'trip-1',
        'latest_message_text': 'placeholder changed row',
      },
    ]);
    final updated = await queue.next;

    expect(initial.isSuccess, isTrue);
    expect(initial.valueOrNull!.single.latestMessagePreview, 'Old preview');
    expect(updated.isSuccess, isTrue);
    expect(updated.valueOrNull!.single.latestMessagePreview, 'Updated preview');
    expect(updated.valueOrNull!.single.hasUnread, isFalse);
  });

  test('chat repository removes conversations missing from realtime snapshot without refetching the full list', () async {
    final backend = MockChatBackend()
      ..conversationRows = [
        {
          'id': 'conversation-1',
          'supplier_id': 'supplier-1',
          'trucker_id': 'trucker-1',
          'load_id': 'load-1',
          'trip_id': 'trip-1',
          'route_label': 'Route 1',
          'load_material': 'Coal',
          'load_price_amount': 62500,
          'load_status_label': 'active',
          'pickup_date': '2026-03-11T00:00:00.000Z',
          'supplier_name': 'Amit Supplier',
          'supplier_mobile': '+919876543210',
          'supplier_company_name': 'Amit Logistics',
          'trucker_name': 'Ravi Trucker',
          'trucker_mobile': '+919812345678',
          'truck_display_label': 'MH12AB1234 - Tata Ace Gold',
          'booking_request_id': 'booking-1',
          'booking_status_label': 'approved',
          'latest_message_type': 'text',
          'latest_message_text': 'Message 1',
          'last_message_at': '2026-03-10T09:00:00.000Z',
          'has_unread': true,
          'is_archived': false,
          'created_at': '2026-03-10T08:00:00.000Z',
        },
        {
          'id': 'conversation-2',
          'supplier_id': 'supplier-1',
          'trucker_id': 'trucker-2',
          'load_id': 'load-2',
          'trip_id': null,
          'route_label': 'Route 2',
          'load_material': 'Steel',
          'load_price_amount': 70000,
          'load_status_label': 'active',
          'pickup_date': '2026-03-12T00:00:00.000Z',
          'supplier_name': 'Amit Supplier',
          'supplier_mobile': '+919876543210',
          'supplier_company_name': 'Amit Logistics',
          'trucker_name': 'Second Trucker',
          'trucker_mobile': '+919800000000',
          'truck_display_label': 'MH14CD5678 - Ashok Leyland',
          'booking_request_id': null,
          'booking_status_label': null,
          'latest_message_type': 'text',
          'latest_message_text': 'Message 2',
          'last_message_at': '2026-03-10T08:00:00.000Z',
          'has_unread': false,
          'is_archived': false,
          'created_at': '2026-03-10T07:00:00.000Z',
        },
      ];
    addTearDown(() async {
      await backend.conversationWatchController.close();
    });
    final repository = ChatRepository(
      backend,
      () => 'supplier-1',
      () => AppUserRole.supplier,
    );

    final emitted = <List<ConversationPreview>>[];
    final subscription = repository.watchConversations().listen((result) {
      if (result.isSuccess) {
        emitted.add(result.valueOrNull ?? const <ConversationPreview>[]);
      }
    });
    addTearDown(() async {
      await subscription.cancel();
    });

    await Future<void>.delayed(Duration.zero);
    backend.conversationWatchController.add([
      {
        'id': 'conversation-1',
        'supplier_id': 'supplier-1',
        'trucker_id': 'trucker-1',
        'load_id': 'load-1',
        'trip_id': 'trip-1',
        'route_label': 'Route 1',
        'load_material': 'Coal',
        'load_price_amount': 62500,
        'load_status_label': 'active',
        'pickup_date': '2026-03-11T00:00:00.000Z',
        'supplier_name': 'Amit Supplier',
        'supplier_mobile': '+919876543210',
        'supplier_company_name': 'Amit Logistics',
        'trucker_name': 'Ravi Trucker',
        'trucker_mobile': '+919812345678',
        'truck_display_label': 'MH12AB1234 - Tata Ace Gold',
        'booking_request_id': 'booking-1',
        'booking_status_label': 'approved',
        'latest_message_type': 'text',
        'latest_message_text': 'Message 1',
        'last_message_at': '2026-03-10T09:00:00.000Z',
        'has_unread': true,
        'is_archived': false,
        'created_at': '2026-03-10T08:00:00.000Z',
      },
    ]);

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(emitted, hasLength(2));
    expect(emitted.first, hasLength(2));
    expect(emitted.last, hasLength(1));
    expect(emitted.last.single.id, 'conversation-1');
  });

  test('chat repository maps messages with sender ownership', () async {
    final backend = MockChatBackend()
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
    final backend = MockChatBackend();
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
    expect(backend.sentMessageConversationId, 'conversation-1');
    expect(backend.sentMessageType, ChatMessageType.text);
    expect(backend.sentTextBody, 'Need unloading update');
  });

  test('chat repository sends voice message', () async {
    final backend = MockChatBackend();
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
    expect(backend.sentMessageConversationId, 'conversation-1');
    expect(backend.sentMessageType, ChatMessageType.voice);
    expect(backend.sentMessageId, 'message-voice-1');
    expect(backend.sentAttachmentPath, 'communication-media/conversation-1/message-voice-1.m4a');
    expect(backend.sentStructuredPayload, {'voice_duration_seconds': 12});
  });

  test('chat repository maps send failures', () async {
    final backend = MockChatBackend()
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
    final backend = MockChatBackend();
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
