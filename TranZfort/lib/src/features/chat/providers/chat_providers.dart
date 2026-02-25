import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../../../core/repositories/chat_repository.dart';
import '../../auth/providers/auth_providers.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(supabaseClientProvider));
});

final chatInboxProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final result = await ref.watch(chatRepositoryProvider).getConversations();
  return switch (result) {
    Success(data: final data) => data,
    Failure() => const <Map<String, dynamic>>[],
  };
});

final chatMessagesProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, conversationId) async* {
  final repo = ref.watch(chatRepositoryProvider);
  
  // Initial load
  final result = await repo.getMessages(conversationId);
  var currentMessages = switch (result) {
    Success(data: final data) => data,
    Failure() => const <Map<String, dynamic>>[],
  };
  
  yield currentMessages;

  // Mark as read
  final userId = ref.watch(authSessionProvider).value?.session?.user.id;
  if (userId != null) {
    repo.markMessagesAsRead(conversationId, userId);
  }

  // Subscribe to changes
  final channel = repo.subscribeToMessages(conversationId, (_) async {
    final newResult = await repo.getMessages(conversationId);
    if (newResult is Success) {
      currentMessages = (newResult as Success).data;
      // Also mark read if new messages arrive while stream is active
      if (userId != null) {
        repo.markMessagesAsRead(conversationId, userId);
      }
    }
  });

  ref.onDispose(() {
    channel.unsubscribe();
  });
});

class ChatSendNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ChatSendNotifier(this._ref) : super(const AsyncData(null));

  Future<bool> sendText(String conversationId, String text) async {
    if (text.trim().isEmpty) return false;
    
    final userId = _ref.read(authSessionProvider).value?.session?.user.id;
    if (userId == null) return false;

    state = const AsyncLoading();

    final result = await _ref.read(chatRepositoryProvider).sendMessage(
      conversationId: conversationId,
      senderId: userId,
      messageType: 'text',
      textContent: text.trim(),
    );

    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(chatInboxProvider);
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Failed to send message', StackTrace.current);
        return false;
    }
  }
}

final chatSendProvider = StateNotifierProvider<ChatSendNotifier, AsyncValue<void>>((ref) {
  return ChatSendNotifier(ref);
});
