import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/communication/data/chat_repository.dart';
import 'package:tranzfort/src/features/communication/providers/chat_providers.dart';

class _FakeChatRepository extends ChatRepository {
  final Result<List<ConversationPreview>> initialConversations;
  final Result<List<ChatMessage>> initialMessages;
  final StreamController<Result<List<ConversationPreview>>> conversationStreamController;
  final StreamController<Result<List<ChatMessage>>> messageStreamController;
  Result<String> sendTextResult;
  Result<String> sendVoiceResult;
  Result<void> markReadResult;
  String? lastSentConversationId;
  String? lastSentText;
  String? lastVoiceConversationId;
  String? lastVoiceMessageId;
  String? lastVoiceAttachmentPath;
  String? lastMarkedConversationId;

  _FakeChatRepository({
    required this.initialConversations,
    required this.initialMessages,
    required this.conversationStreamController,
    required this.messageStreamController,
    this.sendTextResult = const Success<String>('message-1'),
    this.sendVoiceResult = const Success<String>('message-voice-1'),
    this.markReadResult = const Success<void>(null),
  }) : super(const _UnusedChatBackend(), () => null, () => throw UnimplementedError());

  @override
  Future<Result<List<ConversationPreview>>> getConversations() async => initialConversations;

  @override
  Stream<Result<List<ConversationPreview>>> watchConversations() => conversationStreamController.stream;

  @override
  Future<Result<List<ChatMessage>>> getMessages(String conversationId) async => initialMessages;

  @override
  Stream<Result<List<ChatMessage>>> watchMessages(String conversationId) => messageStreamController.stream;

  @override
  Future<Result<String>> sendTextMessage({required String conversationId, required String text}) async {
    lastSentConversationId = conversationId;
    lastSentText = text;
    return sendTextResult;
  }

  @override
  Future<Result<String>> sendVoiceMessage({
    required String conversationId,
    String? messageId,
    required String attachmentPath,
    Map<String, dynamic>? structuredPayload,
  }) async {
    lastVoiceConversationId = conversationId;
    lastVoiceMessageId = messageId;
    lastVoiceAttachmentPath = attachmentPath;
    return sendVoiceResult;
  }

  @override
  Future<Result<void>> markConversationRead(String conversationId) async {
    lastMarkedConversationId = conversationId;
    return markReadResult;
  }
}

class _UnusedChatBackend implements ChatBackend {
  const _UnusedChatBackend();

  @override
  Future<List<Map<String, dynamic>>> fetchConversations({required String userId, required AppUserRole role}) async => throw UnimplementedError();

  @override
  Stream<List<Map<String, dynamic>>> watchConversations({required String userId, required AppUserRole role}) => throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> fetchMessages({required String conversationId}) async => throw UnimplementedError();

  @override
  Stream<List<Map<String, dynamic>>> watchMessages({required String conversationId}) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> fetchLatestMessage({required String conversationId}) async => throw UnimplementedError();

  @override
  Future<bool> fetchHasUnread({required String conversationId, required String currentUserId}) async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> fetchLoadContext(String loadId) async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> fetchProfile(String profileId) async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId) async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> fetchBookingContext({required String loadId, required String truckerId}) async =>
      throw UnimplementedError();

  @override
  Future<String> createOrGetConversation({required String supplierId, required String truckerId, required String loadId}) async => throw UnimplementedError();

  @override
  Future<String> sendMessage({required String conversationId, required ChatMessageType type, String? messageId, String? textBody, String? attachmentPath, Map<String, dynamic>? structuredPayload}) async => throw UnimplementedError();

  @override
  Future<void> markMessagesRead({required String conversationId, required String readerId}) async => throw UnimplementedError();
}

ConversationPreview _conversation(String id, {String latestMessagePreview = 'Latest update'}) {
  return ConversationPreview(
    id: id,
    supplierId: 'supplier-1',
    truckerId: 'trucker-1',
    loadId: 'load-1',
    tripId: 'trip-1',
    routeLabel: 'Chandrapur, Maharashtra → Mumbai, Maharashtra',
    loadMaterial: 'Coal',
    loadPriceAmount: 62500,
    loadStatusLabel: 'active',
    pickupDate: DateTime(2026, 3, 11),
    supplierName: 'Amit Supplier',
    supplierMobile: '+919876543210',
    supplierCompanyName: 'Amit Logistics',
    truckerName: 'Ravi Trucker',
    truckerMobile: '+919812345678',
    truckDisplayLabel: 'MH12AB1234 • Tata Ace Gold',
    bookingRequestId: 'booking-1',
    bookingStatusLabel: 'approved',
    latestMessagePreview: latestMessagePreview,
    lastMessageAt: DateTime(2026, 3, 10, 9),
    hasUnread: true,
    isArchived: false,
    createdAt: DateTime(2026, 3, 10, 8),
  );
}

ChatMessage _message(String id, {String textBody = 'Hello'}) {
  return ChatMessage(
    id: id,
    conversationId: 'conversation-1',
    senderProfileId: 'supplier-1',
    type: ChatMessageType.text,
    textBody: textBody,
    attachmentPath: null,
    structuredPayload: null,
    isRead: false,
    readAt: null,
    createdAt: DateTime(2026, 3, 10, 9),
    isFromCurrentUser: true,
  );
}

void main() {
  test('inbox provider loads initial conversations and merges realtime updates', () async {
    final conversationStreamController = StreamController<Result<List<ConversationPreview>>>.broadcast();
    final messageStreamController = StreamController<Result<List<ChatMessage>>>.broadcast();
    final repository = _FakeChatRepository(
      initialConversations: Success<List<ConversationPreview>>([_conversation('conversation-1')]),
      initialMessages: Success<List<ChatMessage>>([_message('message-1')]),
      conversationStreamController: conversationStreamController,
      messageStreamController: messageStreamController,
    );
    final container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repository),
      ],
    );
    final inboxSubscription = container.listen(inboxProvider, (_, _) {});
    addTearDown(() async {
      inboxSubscription.close();
      await conversationStreamController.close();
      await messageStreamController.close();
      container.dispose();
    });

    await container.read(inboxProvider.notifier).load();

    expect(container.read(inboxProvider).conversations, hasLength(1));
    conversationStreamController.add(
      Success<List<ConversationPreview>>([
        _conversation('conversation-1'),
        _conversation('conversation-2', latestMessagePreview: 'New route shared'),
      ]),
    );
    await Future<void>.delayed(Duration.zero);

    expect(container.read(inboxProvider).conversations, hasLength(2));
  });

  test('conversation messages provider loads initial messages and merges realtime updates', () async {
    final conversationStreamController = StreamController<Result<List<ConversationPreview>>>.broadcast();
    final messageStreamController = StreamController<Result<List<ChatMessage>>>.broadcast();
    final repository = _FakeChatRepository(
      initialConversations: Success<List<ConversationPreview>>([_conversation('conversation-1')]),
      initialMessages: Success<List<ChatMessage>>([_message('message-1')]),
      conversationStreamController: conversationStreamController,
      messageStreamController: messageStreamController,
    );
    final container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repository),
      ],
    );
    final messagesSubscription = container.listen(
      conversationMessagesProvider('conversation-1'),
      (_, _) {},
    );
    addTearDown(() async {
      messagesSubscription.close();
      await conversationStreamController.close();
      await messageStreamController.close();
      container.dispose();
    });

    await container.read(conversationMessagesProvider('conversation-1').notifier).load();

    expect(container.read(conversationMessagesProvider('conversation-1')).messages, hasLength(1));
    messageStreamController.add(
      Success<List<ChatMessage>>([
        _message('message-1'),
        _message('message-2', textBody: 'Rate confirmed'),
      ]),
    );
    await Future<void>.delayed(Duration.zero);

    expect(container.read(conversationMessagesProvider('conversation-1')).messages, hasLength(2));
  });

  test('inbox provider cancels realtime conversation subscription on dispose', () async {
    var conversationStreamCancelled = false;
    final conversationStreamController = StreamController<Result<List<ConversationPreview>>>.broadcast(
      onCancel: () {
        conversationStreamCancelled = true;
      },
    );
    final messageStreamController = StreamController<Result<List<ChatMessage>>>.broadcast();
    final repository = _FakeChatRepository(
      initialConversations: Success<List<ConversationPreview>>([_conversation('conversation-1')]),
      initialMessages: Success<List<ChatMessage>>([_message('message-1')]),
      conversationStreamController: conversationStreamController,
      messageStreamController: messageStreamController,
    );
    final container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repository),
      ],
    );
    final inboxSubscription = container.listen(inboxProvider, (_, _) {});

    await Future<void>.delayed(Duration.zero);
    inboxSubscription.close();
    container.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(conversationStreamCancelled, isTrue);

    await conversationStreamController.close();
    await messageStreamController.close();
  });

  test('conversation messages provider cancels realtime message subscription on dispose', () async {
    final conversationStreamController = StreamController<Result<List<ConversationPreview>>>.broadcast();
    var messageStreamCancelled = false;
    final messageStreamController = StreamController<Result<List<ChatMessage>>>.broadcast(
      onCancel: () {
        messageStreamCancelled = true;
      },
    );
    final repository = _FakeChatRepository(
      initialConversations: Success<List<ConversationPreview>>([_conversation('conversation-1')]),
      initialMessages: Success<List<ChatMessage>>([_message('message-1')]),
      conversationStreamController: conversationStreamController,
      messageStreamController: messageStreamController,
    );
    final container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repository),
      ],
    );
    final messagesSubscription = container.listen(
      conversationMessagesProvider('conversation-1'),
      (_, _) {},
    );

    await Future<void>.delayed(Duration.zero);
    messagesSubscription.close();
    container.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(messageStreamCancelled, isTrue);

    await conversationStreamController.close();
    await messageStreamController.close();
  });

  test('send message provider sends text and stores last sent id', () async {
    final conversationStreamController = StreamController<Result<List<ConversationPreview>>>.broadcast();
    final messageStreamController = StreamController<Result<List<ChatMessage>>>.broadcast();
    final repository = _FakeChatRepository(
      initialConversations: Success<List<ConversationPreview>>([_conversation('conversation-1')]),
      initialMessages: Success<List<ChatMessage>>([_message('message-1')]),
      conversationStreamController: conversationStreamController,
      messageStreamController: messageStreamController,
    );
    final container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      await conversationStreamController.close();
      await messageStreamController.close();
      container.dispose();
    });

    final result = await container.read(sendMessageProvider.notifier).sendTextMessage(
          conversationId: 'conversation-1',
          text: 'Hello',
        );

    expect(result.isSuccess, isTrue);
    expect(repository.lastSentConversationId, 'conversation-1');
    expect(container.read(sendMessageProvider).lastSentMessageId, 'message-1');
  });

  test('send message provider surfaces repository failures', () async {
    final conversationStreamController = StreamController<Result<List<ConversationPreview>>>.broadcast();
    final messageStreamController = StreamController<Result<List<ChatMessage>>>.broadcast();
    final repository = _FakeChatRepository(
      initialConversations: Success<List<ConversationPreview>>([_conversation('conversation-1')]),
      initialMessages: Success<List<ChatMessage>>([_message('message-1')]),
      conversationStreamController: conversationStreamController,
      messageStreamController: messageStreamController,
      sendTextResult: const Failure<String>(BusinessRuleFailure(message: 'Message blocked')),
    );
    final container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      await conversationStreamController.close();
      await messageStreamController.close();
      container.dispose();
    });

    final result = await container.read(sendMessageProvider.notifier).sendTextMessage(
          conversationId: 'conversation-1',
          text: 'Hello',
        );

    expect(result.failureOrNull, isA<BusinessRuleFailure>());
    expect(container.read(sendMessageProvider).isSending, isFalse);
  });

  test('send message provider sends voice message', () async {
    final conversationStreamController = StreamController<Result<List<ConversationPreview>>>.broadcast();
    final messageStreamController = StreamController<Result<List<ChatMessage>>>.broadcast();
    final repository = _FakeChatRepository(
      initialConversations: Success<List<ConversationPreview>>([_conversation('conversation-1')]),
      initialMessages: Success<List<ChatMessage>>([_message('message-1')]),
      conversationStreamController: conversationStreamController,
      messageStreamController: messageStreamController,
      sendVoiceResult: const Success<String>('message-voice-1'),
    );
    final container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      await conversationStreamController.close();
      await messageStreamController.close();
      container.dispose();
    });

    final result = await container.read(sendMessageProvider.notifier).sendVoiceMessage(
          conversationId: 'conversation-1',
          messageId: 'message-voice-1',
          attachmentPath: 'communication-media/conversation-1/message-voice-1.m4a',
        );

    expect(result.isSuccess, isTrue);
    expect(repository.lastVoiceConversationId, 'conversation-1');
    expect(repository.lastVoiceMessageId, 'message-voice-1');
    expect(repository.lastVoiceAttachmentPath, 'communication-media/conversation-1/message-voice-1.m4a');
    expect(container.read(sendMessageProvider).lastSentMessageId, 'message-voice-1');
  });

  test('conversation messages provider marks conversation read', () async {
    final conversationStreamController = StreamController<Result<List<ConversationPreview>>>.broadcast();
    final messageStreamController = StreamController<Result<List<ChatMessage>>>.broadcast();
    final repository = _FakeChatRepository(
      initialConversations: Success<List<ConversationPreview>>([_conversation('conversation-1')]),
      initialMessages: Success<List<ChatMessage>>([_message('message-1')]),
      conversationStreamController: conversationStreamController,
      messageStreamController: messageStreamController,
      markReadResult: const Success<void>(null),
    );
    final container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repository),
      ],
    );
    final messagesSubscription = container.listen(
      conversationMessagesProvider('conversation-1'),
      (_, _) {},
    );
    addTearDown(() async {
      messagesSubscription.close();
      await conversationStreamController.close();
      await messageStreamController.close();
      container.dispose();
    });

    final result = await container.read(conversationMessagesProvider('conversation-1').notifier).markConversationRead();

    expect(result.isSuccess, isTrue);
    expect(repository.lastMarkedConversationId, 'conversation-1');
  });
}
