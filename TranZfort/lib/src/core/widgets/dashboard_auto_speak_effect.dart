import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dashboard_auto_speak_prompt_provider.dart';
import '../services/contextual_tts_service.dart';

class DashboardAutoSpeakEffect extends ConsumerStatefulWidget {
  final String? promptKey;
  final String languageCode;
  final String? message;

  const DashboardAutoSpeakEffect({
    super.key,
    required this.promptKey,
    required this.languageCode,
    required this.message,
  });

  @override
  ConsumerState<DashboardAutoSpeakEffect> createState() => _DashboardAutoSpeakEffectState();
}

class _DashboardAutoSpeakEffectState extends ConsumerState<DashboardAutoSpeakEffect> {
  bool _scheduled = false;
  String? _scheduledKey;

  @override
  Widget build(BuildContext context) {
    final promptKey = widget.promptKey?.trim() ?? '';
    final message = widget.message?.trim() ?? '';
    final consumedKeys = ref.watch(dashboardAutoSpeakPromptProvider);

    if (_scheduledKey != promptKey) {
      _scheduledKey = promptKey;
      _scheduled = false;
    }

    if (!_scheduled && promptKey.isNotEmpty && message.isNotEmpty && !consumedKeys.contains(promptKey)) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }
        final consumed = ref.read(dashboardAutoSpeakPromptProvider.notifier).consume(promptKey);
        if (!consumed) {
          return;
        }
        await ref.read(contextualTtsServiceProvider).speakSummary(
              languageCode: widget.languageCode,
              message: message,
            );
      });
    }

    return const SizedBox.shrink();
  }
}
