import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../services/bot_stt_service.dart';
import '../services/conversation_state.dart';
import '../services/basic_bot_service.dart';
import '../../../core/services/tts_service.dart';

final basicBotServiceProvider = Provider<BasicBotService>((ref) {
  final notifier = ref.watch(botChatProvider.notifier);
  final tts = ref.watch(ttsServiceProvider);
  return BasicBotService(notifier, tts);
});

class BotChatScreen extends ConsumerStatefulWidget {
  const BotChatScreen({super.key});

  @override
  ConsumerState<BotChatScreen> createState() => _BotChatScreenState();
}

class _BotChatScreenState extends ConsumerState<BotChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(botChatProvider);
      if (state.messages.isEmpty) {
        ref.read(basicBotServiceProvider).handleInput('namaste', state);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    ref.read(basicBotServiceProvider).handleInput(text, ref.read(botChatProvider));
  }

  void _toggleListening() async {
    final sttState = ref.read(botSttProvider);
    final notifier = ref.read(botSttProvider.notifier);

    if (sttState.isListening) {
      await notifier.stopListening();
    } else {
      await notifier.startListening((resultText) {
        if (resultText.isNotEmpty) {
          final state = ref.read(botChatProvider);
          ref.read(basicBotServiceProvider).handleInput(resultText, state);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(botChatProvider);
    final sttState = ref.watch(botSttProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: const Text('TranZfort Bot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(botChatProvider.notifier).clearChat();
              ref.read(basicBotServiceProvider).handleInput('namaste', ref.read(botChatProvider));
            },
            tooltip: 'New Conversation',
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatState.messages.length + (chatState.isProcessing ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == chatState.messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 16, top: 8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                final msg = chatState.messages[index];
                final isUser = msg['is_user'] == true;
                final text = msg['text'] as String;
                final actionRoute = msg['action_route'] as String?;
                final actionLabel = msg['action_label'] as String?;

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                      ),
                      border: isUser ? null : Border.all(color: AppColors.neutralLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.smart_toy, size: 16, color: AppColors.secondaryAmber),
                              const SizedBox(width: 6),
                              Text(
                                'Bot',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.neutral,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          text,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isUser ? Colors.white : AppColors.onSurface,
                          ),
                        ),
                        if (actionRoute != null && actionLabel != null) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondaryAmber,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => context.push(actionRoute),
                              child: Text(actionLabel),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (sttState.isListening && sttState.partialTranscript.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              color: AppColors.neutralLight.withValues(alpha: 0.3),
              child: Text(
                sttState.partialTranscript,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.neutralLight)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: sttState.isListening ? 'Listening...' : 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      enabled: !sttState.isListening,
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _textController,
                    builder: (context, value, _) {
                      final hasText = value.text.trim().isNotEmpty;
                      return CircleAvatar(
                        backgroundColor: sttState.isListening ? Colors.red : AppColors.primary,
                        child: IconButton(
                          icon: Icon(
                            hasText ? Icons.send : (sttState.isListening ? Icons.stop : Icons.mic),
                            color: Colors.white,
                          ),
                          onPressed: hasText ? _handleSend : _toggleListening,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
