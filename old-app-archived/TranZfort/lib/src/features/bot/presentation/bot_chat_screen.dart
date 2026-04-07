import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/solid_header.dart';
import '../services/bot_stt_service.dart';
import '../services/conversation_state.dart';
import '../services/basic_bot_service.dart';
import '../../../core/services/tts_service.dart';
import '../../../l10n/app_localizations.dart';

final basicBotServiceProvider = Provider<BasicBotService>((ref) {
  throw UnimplementedError('basicBotServiceProvider cannot be resolved without a BuildContext. Instantiate locally.');
});

class BotChatScreen extends ConsumerStatefulWidget {
  const BotChatScreen({super.key});

  @override
  ConsumerState<BotChatScreen> createState() => _BotChatScreenState();
}

class _BotChatScreenState extends ConsumerState<BotChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  String? _lastSpokenBotMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(botChatProvider);
      if (state.messages.isEmpty) {
        BasicBotService(ref.read(botChatProvider.notifier), ref.read(ttsServiceProvider))
            .handleInput('namaste', state, AppLocalizations.of(context));
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
    BasicBotService(ref.read(botChatProvider.notifier), ref.read(ttsServiceProvider))
        .handleInput(text, ref.read(botChatProvider), AppLocalizations.of(context));
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
          BasicBotService(ref.read(botChatProvider.notifier), ref.read(ttsServiceProvider))
              .handleInput(resultText, state, AppLocalizations.of(context));
        }
      });
    }
  }

  void _maybeSpeakLatestBotMessage(ConversationState chatState) {
    if (chatState.messages.isEmpty || chatState.isProcessing) {
      return;
    }

    final latest = chatState.messages.last;
    final isUser = latest['is_user'] == true;
    if (isUser) {
      return;
    }

    final text = (latest['text'] ?? '').toString().trim();
    if (text.isEmpty || text == _lastSpokenBotMessage) {
      return;
    }

    _lastSpokenBotMessage = text;
    ref.read(ttsServiceProvider).speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chatState = ref.watch(botChatProvider);
    final sttState = ref.watch(botSttProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      _maybeSpeakLatestBotMessage(chatState);
    });

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(l10n.appDrawerBotChat),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            constraints: const BoxConstraints(
              minWidth: AppSpacing.minTouchTarget,
              minHeight: AppSpacing.minTouchTarget,
            ),
            onPressed: () {
              ref.read(botChatProvider.notifier).clearChat();
              BasicBotService(ref.read(botChatProvider.notifier), ref.read(ttsServiceProvider))
                  .handleInput('namaste', ref.read(botChatProvider), AppLocalizations.of(context));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.screenPaddingH,
              AppSpacing.screenPaddingV,
              AppSpacing.screenPaddingH,
              AppSpacing.sm,
            ),
            child: SolidHeader(
              title: l10n.appDrawerBotChat,
              subtitle: l10n.botHelpResponse,
              icon: Icons.smart_toy_outlined,
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPaddingH,
                AppSpacing.xs,
                AppSpacing.screenPaddingH,
                AppSpacing.md,
              ),
              itemCount:
                  chatState.messages.length + (chatState.isProcessing ? 1 : 0),
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                if (index == chatState.messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.72,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius)
                            .copyWith(
                              bottomLeft: const Radius.circular(AppSpacing.xs),
                            ),
                        border: Border.all(color: AppColors.neutralLight),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            l10n.appDrawerBotChat,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
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
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius)
                          .copyWith(
                            bottomRight: isUser
                                ? const Radius.circular(AppSpacing.xs)
                                : const Radius.circular(AppSpacing.cardRadius),
                            bottomLeft: isUser
                                ? const Radius.circular(AppSpacing.cardRadius)
                                : const Radius.circular(AppSpacing.xs),
                          ),
                      border: isUser
                          ? null
                          : Border.all(color: AppColors.neutralLight),
                      boxShadow: isUser ? null : AppColors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipOval(
                                child: Image.asset(
                                  'assets/images/bot-avatar.webp',
                                  width: AppSpacing.iconSm,
                                  height: AppSpacing.iconSm,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.smart_toy,
                                    size: AppSpacing.iconSm,
                                    color: AppColors.secondaryAmber,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                l10n.appDrawerBotChat,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: AppColors.neutral),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                        Text(
                          text,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: isUser
                                    ? Colors.white
                                    : AppColors.onSurface,
                              ),
                        ),
                        if (actionRoute != null && actionLabel != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              label: actionLabel,
                              onPressed: () => context.push(actionRoute),
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
              margin: const EdgeInsets.fromLTRB(
                AppSpacing.screenPaddingH,
                0,
                AppSpacing.screenPaddingH,
                AppSpacing.xs,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryMuted,
                border: Border.all(color: AppColors.borderDefault),
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.mic,
                    size: AppSpacing.iconSm,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      sttState.partialTranscript,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPaddingH,
              AppSpacing.sm,
              AppSpacing.screenPaddingH,
              AppSpacing.sm,
            ),
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
                        hintText: l10n.chatTypeMessageHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.composerRadius,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      enabled: !sttState.isListening,
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _textController,
                    builder: (context, value, _) {
                      final hasText = value.text.trim().isNotEmpty;
                      return CircleAvatar(
                        radius: AppSpacing.minTouchTarget / 2,
                        backgroundColor: sttState.isListening
                            ? AppColors.error
                            : AppColors.primary,
                        child: IconButton(
                          constraints: const BoxConstraints(
                            minWidth: AppSpacing.minTouchTarget,
                            minHeight: AppSpacing.minTouchTarget,
                          ),
                          icon: Icon(
                            hasText
                                ? Icons.send
                                : (sttState.isListening
                                      ? Icons.stop
                                      : Icons.mic),
                            color: Colors.white,
                          ),
                          onPressed: hasText ? _handleSend : _toggleListening,
                          tooltip: hasText
                              ? l10n.chatSendMessageTooltip
                              : (sttState.isListening
                                    ? l10n.chatStopRecordingTooltip
                                    : l10n.chatStartRecordingTooltip),
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
