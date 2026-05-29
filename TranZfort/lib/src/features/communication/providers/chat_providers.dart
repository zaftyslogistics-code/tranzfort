import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../data/chat_repository.dart';

// C-006: Error codes for localization (UI should map these to AppLocalizations)
class ChatErrorCodes {
  static const String messageAlreadyBeingSent = 'chat.message_already_being_sent';
}

class InboxState {
  final bool isLoading;
  final bool hasResolvedInitialLoad;
  final List<ConversationPreview> conversations;
  final AppFailure? failure;

  const InboxState({
    required this.isLoading,
    required this.hasResolvedInitialLoad,
    required this.conversations,
    required this.failure,
  });

  factory InboxState.initial() {
    return const InboxState(
      isLoading: true,
      hasResolvedInitialLoad: false,
      conversations: <ConversationPreview>[],
      failure: null,
    );
  }

  InboxState copyWith({
    bool? isLoading,
    bool? hasResolvedInitialLoad,
    List<ConversationPreview>? conversations,
    AppFailure? failure,
    bool? clearFailure,
  }) {
    return InboxState(
      isLoading: isLoading ?? this.isLoading,
      hasResolvedInitialLoad: hasResolvedInitialLoad ?? this.hasResolvedInitialLoad,
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

/// A date section in the chat message list: a [date] header followed by
/// the [messages] sent on that date (local time).
class ChatMessageGroup {
  final DateTime date;
  final List<ChatMessage> messages;

  const ChatMessageGroup({required this.date, required this.messages});
}

class ConversationMessagesState {
  final bool isLoading;
  final bool hasResolvedInitialLoad;
  final bool isLoadingOlder;
  final List<ChatMessage> messages;
  final bool hasMoreOlderMessages;
  final AppFailure? failure;

  const ConversationMessagesState({
    required this.isLoading,
    required this.hasResolvedInitialLoad,
    required this.isLoadingOlder,
    required this.messages,
    required this.hasMoreOlderMessages,
    required this.failure,
  });

  factory ConversationMessagesState.initial() {
    return const ConversationMessagesState(
      isLoading: true,
      hasResolvedInitialLoad: false,
      isLoadingOlder: false,
      messages: <ChatMessage>[],
      hasMoreOlderMessages: true,
      failure: null,
    );
  }

  ConversationMessagesState copyWith({
    bool? isLoading,
    bool? hasResolvedInitialLoad,
    bool? isLoadingOlder,
    List<ChatMessage>? messages,
    bool? hasMoreOlderMessages,
    AppFailure? failure,
    bool? clearFailure,
  }) {
    return ConversationMessagesState(
      isLoading: isLoading ?? this.isLoading,
      hasResolvedInitialLoad: hasResolvedInitialLoad ?? this.hasResolvedInitialLoad,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      messages: messages ?? this.messages,
      hasMoreOlderMessages: hasMoreOlderMessages ?? this.hasMoreOlderMessages,
      failure: clearFailure == true ? null : failure ?? this.failure,
    );
  }

  /// Messages grouped by calendar date (local time), oldest date first.
  List<ChatMessageGroup> get groupedMessages {
    if (messages.isEmpty) return const <ChatMessageGroup>[];

    final groups = <DateTime, List<ChatMessage>>{};
    for (final message in messages) {
      final local = message.createdAt.toLocal();
      final key = DateTime(local.year, local.month, local.day);
      groups.putIfAbsent(key, () => <ChatMessage>[]).add(message);
    }
    final sortedKeys = groups.keys.toList()..sort();
    return sortedKeys
        .map((date) => ChatMessageGroup(date: date, messages: groups[date]!))
        .toList(growable: false);
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
  static const Duration _minLoadingDuration = Duration(milliseconds: 300);
  static const Duration _errorDebounceDuration = Duration(milliseconds: 500);

  final ChatRepository _repository;
  Timer? _errorDebounceTimer;

  InboxController(this._repository) : super(InboxState.initial()) {
    load();
  }

  void _scheduleErrorDisplay(AppFailure failure) {
    _errorDebounceTimer?.cancel();
    _errorDebounceTimer = Timer(_errorDebounceDuration, () {
      if (!mounted) {
        return;
      }
      if (state.conversations.isEmpty) {
        state = state.copyWith(
          failure: failure,
          isLoading: false,
          hasResolvedInitialLoad: true,
        );
      }
    });
  }

  void _cancelErrorDisplay() {
    _errorDebounceTimer?.cancel();
    _errorDebounceTimer = null;
  }

  Future<void> _ensureMinLoadingDuration(DateTime startTime) async {
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < _minLoadingDuration) {
      await Future.delayed(_minLoadingDuration - elapsed);
    }
  }

  Future<void> load() async {
    final startTime = DateTime.now();
    state = state.copyWith(isLoading: true, hasResolvedInitialLoad: false, clearFailure: true);
    final result = await _repository.getConversations();
    await _ensureMinLoadingDuration(startTime);
    if (!mounted) {
      return;
    }
    result.when(
      success: (conversations) {
        _cancelErrorDisplay();
        state = state.copyWith(
          isLoading: false,
          hasResolvedInitialLoad: true,
          conversations: conversations,
          clearFailure: true,
        );
      },
      failure: (failure) {
        _scheduleErrorDisplay(failure);
        state = state.copyWith(
          isLoading: false,
          hasResolvedInitialLoad: true,
        );
      },
    );
  }

  @override
  void dispose() {
    _errorDebounceTimer?.cancel();
    super.dispose();
  }
}

class ConversationMessagesController extends StateNotifier<ConversationMessagesState> {
  static const Duration _minLoadingDuration = Duration(milliseconds: 300);
  static const Duration _errorDebounceDuration = Duration(seconds: 2);

  final ChatRepository _repository;
  final String _conversationId;
  StreamSubscription<Result<List<ChatMessage>>>? _subscription;
  Timer? _errorDebounceTimer;

  ConversationMessagesController(this._repository, this._conversationId)
      : super(ConversationMessagesState.initial()) {
    _start();
  }

  void _scheduleErrorDisplay(AppFailure failure) {
    _errorDebounceTimer?.cancel();
    _errorDebounceTimer = Timer(_errorDebounceDuration, () {
      if (!mounted) {
        return;
      }
      if (state.messages.isEmpty) {
        state = state.copyWith(
          failure: failure,
          isLoading: false,
          hasResolvedInitialLoad: true,
        );
      }
    });
  }

  void _cancelErrorDisplay() {
    _errorDebounceTimer?.cancel();
    _errorDebounceTimer = null;
  }

  Future<void> _ensureMinLoadingDuration(DateTime startTime) async {
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < _minLoadingDuration) {
      await Future.delayed(_minLoadingDuration - elapsed);
    }
  }

  /// Merges realtime messages with existing messages by ID
  /// - Preserves paginated older messages
  /// - Updates existing messages with new data (read-state changes)
  /// - Adds new messages from realtime stream
  /// - Handles optimistic message replacement
  List<ChatMessage> _mergeMessages(List<ChatMessage> existing, List<ChatMessage> realtime) {
    final existingMap = <String, ChatMessage>{};
    for (final msg in existing) {
      existingMap[msg.id] = msg;
    }

    final realtimeMap = <String, ChatMessage>{};
    for (final msg in realtime) {
      realtimeMap[msg.id] = msg;
    }

    // Start with realtime messages (they're the source of truth for recent messages)
    final merged = <ChatMessage>[];
    final mergedIds = <String>{};

    // Add realtime messages (newest first, as they come from stream)
    for (final msg in realtime) {
      merged.add(msg);
      mergedIds.add(msg.id);
    }

    // Add older paginated messages that aren't in realtime stream
    // These are messages loaded via loadOlderMessages()
    for (final msg in existing) {
      if (!mergedIds.contains(msg.id)) {
        merged.add(msg);
        mergedIds.add(msg.id);
      }
    }

    // Sort by created_at descending (newest first)
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return merged;
  }

  Future<void> _start() async {
    await load();
    _subscription = _repository.watchMessages(_conversationId).listen((result) {
      result.when(
        success: (messages) {
          _cancelErrorDisplay();
          // Merge realtime messages with existing paginated history
          final merged = _mergeMessages(state.messages, messages);
          state = state.copyWith(
            isLoading: false,
            hasResolvedInitialLoad: true,
            messages: merged,
            clearFailure: true,
          );
        },
        failure: (failure) {
          _scheduleErrorDisplay(failure);
          state = state.copyWith(
            isLoading: false,
            hasResolvedInitialLoad: true,
          );
        },
      );
    });
  }

  Future<void> load() async {
    final startTime = DateTime.now();
    state = state.copyWith(isLoading: true, hasResolvedInitialLoad: false, clearFailure: true);
    // P0.6: Use paginated query with limit to prevent loading all messages at once
    final result = await _repository.getMessagesPaginated(
      _conversationId,
      limit: 50,
    );
    await _ensureMinLoadingDuration(startTime);
    if (!mounted) {
      return;
    }
    result.when(
      success: (messages) {
        _cancelErrorDisplay();
        state = state.copyWith(
          isLoading: false,
          hasResolvedInitialLoad: true,
          messages: messages,
          hasMoreOlderMessages: messages.length >= 50,
          clearFailure: true,
        );
      },
      failure: (failure) {
        _scheduleErrorDisplay(failure);
        state = state.copyWith(
          isLoading: false,
          hasResolvedInitialLoad: true,
        );
      },
    );
  }

  Future<void> loadOlderMessages() async {
    if (state.isLoadingOlder || !state.hasMoreOlderMessages || state.messages.isEmpty) {
      return;
    }

    final oldestMessage = state.messages.first;
    state = state.copyWith(isLoadingOlder: true, clearFailure: true);

    final result = await _repository.getMessagesPaginated(
      _conversationId,
      limit: 50,
      beforeCreatedAt: oldestMessage.createdAt,
      beforeMessageId: oldestMessage.id,
    );

    result.when(
      success: (olderMessages) {
        final merged = <ChatMessage>[...olderMessages, ...state.messages];
        state = state.copyWith(
          isLoadingOlder: false,
          messages: merged,
          hasMoreOlderMessages: olderMessages.length == 50,
          clearFailure: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isLoadingOlder: false,
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
    _errorDebounceTimer?.cancel();
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
        BusinessRuleFailure(message: ChatErrorCodes.messageAlreadyBeingSent),
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
        BusinessRuleFailure(message: ChatErrorCodes.messageAlreadyBeingSent),
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
