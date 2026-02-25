import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/chat_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
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

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Optimistic UI updates are handled by the stream mostly, 
    // but clearing the input immediately feels responsive.
    _messageController.clear();
    
    final success = await ref
        .read(chatSendProvider.notifier)
        .sendText(widget.conversationId, text);

    if (success && mounted) {
      _scrollToBottom();
    } else if (mounted) {
      // Restore if failed (rudimentary retry UX)
      _messageController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.conversationId));
    final sendState = ref.watch(chatSendProvider);
    final userId = ref.watch(authSessionProvider).value?.session?.user.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  if (messages.isEmpty) {
                    return const Center(child: Text('No messages yet.'));
                  }

                  return ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg['sender_id'] == userId;
                      final type = msg['message_type'] ?? 'text';
                      final content = msg['text_content'] ?? '';
                      final createdAt = DateTime.tryParse((msg['created_at'] ?? '').toString());
                      final isRead = msg['is_read'] == true;

                      if (type == 'system') {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.neutralLight.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              content,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.neutral,
                              ),
                            ),
                          ),
                        );
                      }

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFFE3F2FD) : AppColors.surface,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                            border: isMe ? null : Border.all(color: AppColors.neutralLight),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                content,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (createdAt != null)
                                    Text(
                                      DateFormat.jm().format(createdAt),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.neutral,
                                        fontSize: 10,
                                      ),
                                    ),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      isRead ? Icons.done_all : Icons.check,
                                      size: 14,
                                      color: isRead ? AppColors.primaryLight : AppColors.neutral,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.neutralLight)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: AppColors.neutral),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Attachments coming soon')),
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
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
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendText(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _messageController,
                    builder: (context, value, _) {
                      final hasText = value.text.trim().isNotEmpty;
                      return CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: IconButton(
                          icon: sendState.isLoading 
                            ? const SizedBox(
                                width: 20, 
                                height: 20, 
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, 
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Icon(hasText ? Icons.send : Icons.mic, color: Colors.white),
                          onPressed: hasText ? _sendText : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Voice recording coming soon')),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
