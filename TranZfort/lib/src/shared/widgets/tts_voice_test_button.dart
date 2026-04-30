import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/contextual_tts_service.dart';
import '../../core/services/tts_voice_model.dart';
import '../../l10n/app_localizations.dart';

/// Widget for testing a TTS voice by speaking sample text.
class TtsVoiceTestButton extends ConsumerStatefulWidget {
  final TtsVoice voice;
  final String languageCode;

  const TtsVoiceTestButton({
    super.key,
    required this.voice,
    required this.languageCode,
  });

  @override
  ConsumerState<TtsVoiceTestButton> createState() => _TtsVoiceTestButtonState();
}

class _TtsVoiceTestButtonState extends ConsumerState<TtsVoiceTestButton> {
  bool _isSpeaking = false;

  Future<void> _testVoice() async {
    if (_isSpeaking) return;

    setState(() => _isSpeaking = true);

    final ttsService = ref.read(contextualTtsServiceProvider);
    final l10n = AppLocalizations.of(context);

    // Get sample text based on language
    final sampleText = _getSampleText(l10n, widget.languageCode);

    try {
      // Set the language for the voice
      await ttsService.setLanguage(widget.languageCode);
      
      // Speak the sample text
      await ttsService.speakSummary(
        languageCode: widget.languageCode,
        message: sampleText,
      );
    } catch (e) {
      // Silently fail on test errors
    } finally {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  String _getSampleText(AppLocalizations l10n, String languageCode) {
    if (languageCode == 'hi') {
      return 'नमस्ते, यह एक आवाज़ परीक्षण है।'; // Hindi: "Hello, this is a voice test."
    } else {
      return 'Hello, this is a voice test.'; // English
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton.icon(
      onPressed: _isSpeaking ? null : _testVoice,
      icon: _isSpeaking
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
          : const Icon(Icons.volume_up_outlined, size: 18),
      label: Text(
        _isSpeaking ? 'Speaking...' : 'Test',
        style: theme.textTheme.labelSmall,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        side: BorderSide(color: theme.colorScheme.outline),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(80, 36),
      ),
    );
  }
}
