import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../data/chat_repository.dart';

class InboxState {
  final bool isLoading;
  final List<ConversationPreview> conversations;
  final AppFailure? failure;

  const InboxState({
    required this.isLoading,
    required this.conversations,
    required this.failure,
  });

  factory InboxState.initial() {
    return const InboxState(
      isLoading: true,
      conversations: <ConversationPreview>[],
      failure: null,
    );
  }

  InboxState copyWith({
    bool? isLoading,
    List<ConversationPreview>? conversations,
    AppFailure? failure,
    bool? clearFailure,
  }) {
    return InboxState(
      isLoading: isLoading ?? this.isLoading,
      conversations: conversations ?? this.conversations,
      failure: clearFailure == true ? null : failure ?? this.failure,
    );
  }
}

final unreadConversationCountProvider = StreamProvider.autoDispose<int>((ref) async* {
  final repository = ref.watch(chatRepositoryProvider);
  final initial = await repository.getUnreadConversationCount();
  yield initial.valueOrNull ?? 0;

  await for (final result in repository.watchUnreadConversationCount()) {
    yield result.valueOrNull ?? 0;
  }
});

class ConversationMessagesState {
  final bool isLoading;
  final List<ChatMessage> messages;
  final AppFailure? failure;

  const ConversationMessagesState({
    required this.isLoading,
    required this.messages,
    required this.failure,
  });

  factory ConversationMessagesState.initial() {
    return const ConversationMessagesState(
      isLoading: true,
      messages: <ChatMessage>[],
      failure: null,
    );
  }

  ConversationMessagesState copyWith({
    bool? isLoading,
    List<ChatMessage>? messages,
    AppFailure? failure,
    bool? clearFailure,
  }) {
    return ConversationMessagesState(
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      failure: clearFailure == true ? null : failure ?? this.failure,
    );
  }
}

class SendMessageState {
  final bool isSending;
  final AppFailure? failure;
  final String? lastSentMessageId;

  const SendMessageState({
    required this.isSending,
    required this.failure,
    required this.lastSentMessageId,
  });

  factory SendMessageState.initial() {
    return const SendMessageState(
      isSending: false,
      failure: null,
      lastSentMessageId: null,
    );
  }

  SendMessageState copyWith({
    bool? isSending,
    AppFailure? failure,
    bool? clearFailure,
    String? lastSentMessageId,
    bool? clearLastSentMessageId,
  }) {
    return SendMessageState(
      isSending: isSending ?? this.isSending,
      failure: clearFailure == true ? null : failure ?? this.failure,
      lastSentMessageId: clearLastSentMessageId == true ? null : lastSentMessageId ?? this.lastSentMessageId,
    );
  }
}

class InboxController extends StateNotifier<InboxState> {
  final ChatRepository _repository;

  InboxController(this._repository) : super(InboxState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await _repository.getConversations();
    result.when(
      success: (conversations) {
        state = state.copyWith(
          isLoading: false,
          conversations: conversations,
          clearFailure: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isLoading: false,
          failure: failure,
        );
      },
    );
  }
}

class ConversationMessagesController extends StateNotifier<ConversationMessagesState> {
  final ChatRepository _repository;
  final String _conversationId;
  StreamSubscription<Result<List<ChatMessage>>>? _subscription;

  ConversationMessagesController(this._repository, this._conversationId)
      : super(ConversationMessagesState.initial()) {
    _start();
  }

  Future<void> _start() async {
    await load();
    _subscription = _repository.watchMessages(_conversationId).listen((result) {
      result.when(
        success: (messages) {
          state = state.copyWith(
            isLoading: false,
            messages: messages,
            clearFailure: true,
          );
        },
        failure: (failure) {
          state = state.copyWith(
            isLoading: false,
            failure: failure,
          );
        },
      );
    });
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await _repository.getMessages(_conversationId);
    result.when(
      success: (messages) {
        state = state.copyWith(
          isLoading: false,
          messages: messages,
          clearFailure: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isLoading: false,
          failure: failure,
        );
      },
    );
  }

  Future<Result<void>> markConversationRead() async {
    final result = await _repository.markConversationRead(_conversationId);
    if (result.isFailure) {
      state = state.copyWith(failure: result.failureOrNull);
    } else {
      state = state.copyWith(clearFailure: true);
    }
    return result;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class SendMessageController extends StateNotifier<SendMessageState> {
  final ChatRepository _repository;

  SendMessageController(this._repository) : super(SendMessageState.initial());

  Future<Result<String>> sendTextMessage({
    required String conversationId,
    required String text,
  }) async {
    if (state.isSending) {
      return const Failure<String>(
        BusinessRuleFailure(message: 'Another message is already being sent.'),
      );
    }

    state = state.copyWith(
      isSending: true,
      clearFailure: true,
      clearLastSentMessageId: true,
    );
    final result = await _repository.sendTextMessage(
      conversationId: conversationId,
      text: text,
    );
    if (result.isFailure) {
      state = state.copyWith(
        isSending: false,
        failure: result.failureOrNull,
      );
      return result;
    }

    state = state.copyWith(
      isSending: false,
      lastSentMessageId: result.valueOrNull,
      clearFailure: true,
    );
    return result;
  }

  Future<Result<String>> sendVoiceMessage({
    required String conversationId,
    String? messageId,
    required String attachmentPath,
    Map<String, dynamic>? structuredPayload,
  }) async {
    if (state.isSending) {
      return const Failure<String>(
        BusinessRuleFailure(message: 'Another message is already being sent.'),
      );
    }

    state = state.copyWith(
      isSending: true,
      clearFailure: true,
      clearLastSentMessageId: true,
    );
    final result = await _repository.sendVoiceMessage(
      conversationId: conversationId,
      messageId: messageId,
      attachmentPath: attachmentPath,
      structuredPayload: structuredPayload,
    );
    if (result.isFailure) {
      state = state.copyWith(
        isSending: false,
        failure: result.failureOrNull,
      );
      return result;
    }

    state = state.copyWith(
      isSending: false,
      lastSentMessageId: result.valueOrNull,
      clearFailure: true,
    );
    return result;
  }
}

final inboxProvider = StateNotifierProvider.autoDispose<InboxController, InboxState>((ref) {
  return InboxController(ref.watch(chatRepositoryProvider));
});

final conversationMessagesProvider = StateNotifierProvider.autoDispose
    .family<ConversationMessagesController, ConversationMessagesState, String>((ref, conversationId) {
  return ConversationMessagesController(ref.watch(chatRepositoryProvider), conversationId);
});

final sendMessageProvider = StateNotifierProvider.autoDispose<SendMessageController, SendMessageState>((ref) {
  return SendMessageController(ref.watch(chatRepositoryProvider));
});
