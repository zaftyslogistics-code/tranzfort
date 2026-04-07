import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bot_intent.dart';

class ConversationState {
  final BotIntent currentIntent;
  final Map<String, dynamic> slots;
  final List<Map<String, dynamic>> messages;
  final bool isProcessing;
  final String? activeSlotKey;

  const ConversationState({
    this.currentIntent = BotIntent.unknown,
    this.slots = const {},
    this.messages = const [],
    this.isProcessing = false,
    this.activeSlotKey,
  });

  ConversationState copyWith({
    BotIntent? currentIntent,
    Map<String, dynamic>? slots,
    List<Map<String, dynamic>>? messages,
    bool? isProcessing,
    String? activeSlotKey,
    bool clearActiveSlot = false,
  }) {
    return ConversationState(
      currentIntent: currentIntent ?? this.currentIntent,
      slots: slots ?? this.slots,
      messages: messages ?? this.messages,
      isProcessing: isProcessing ?? this.isProcessing,
      activeSlotKey: clearActiveSlot
          ? null
          : (activeSlotKey ?? this.activeSlotKey),
    );
  }
}

class BotChatNotifier extends StateNotifier<ConversationState> {
  BotChatNotifier() : super(const ConversationState());

  ConversationState get currentState => state;

  void addMessage(String text, {bool isUser = false}) {
    state = state.copyWith(
      messages: [
        ...state.messages,
        {
          'text': text,
          'is_user': isUser,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ],
    );
  }

  void addActionMessage(String text, String route, String label) {
    state = state.copyWith(
      messages: [
        ...state.messages,
        {
          'text': text,
          'is_user': false,
          'action_route': route,
          'action_label': label,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ],
    );
  }

  void setProcessing(bool processing) {
    state = state.copyWith(isProcessing: processing);
  }

  void setIntent(BotIntent intent) {
    state = state.copyWith(currentIntent: intent);
  }

  void updateSlot(String key, dynamic value) {
    final updated = Map<String, dynamic>.from(state.slots);
    updated[key] = value;
    state = state.copyWith(slots: updated);
  }

  void setActiveSlot(String? key) {
    state = state.copyWith(
      activeSlotKey: key,
      clearActiveSlot: key == null || key.isEmpty,
    );
  }

  void clearSlots() {
    state = state.copyWith(
      slots: const {},
      currentIntent: BotIntent.unknown,
      clearActiveSlot: true,
    );
  }

  void clearChat() {
    state = const ConversationState();
  }
}

final botChatProvider =
    StateNotifierProvider<BotChatNotifier, ConversationState>((ref) {
      return BotChatNotifier();
    });
