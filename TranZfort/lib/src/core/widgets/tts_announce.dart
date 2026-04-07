import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/contextual_tts_service.dart';

/// A widget that automatically announces text via TTS when mounted
/// or when the text changes.
///
/// This widget is invisible (returns SizedBox.shrink()) and is meant
/// to be placed anywhere in the widget tree where announcements are needed.
///
/// Features:
/// - Auto-speaks on mount
/// - Re-speaks when text changes
/// - Tracks last spoken text to prevent duplicates
/// - Configurable delay before speaking
/// - Can be enabled/disabled
///
/// Example:
/// ```dart
/// TtsAnnounce(
///   text: 'Found 5 loads',
///   enabled: ttsEnabled,
///   delay: Duration(milliseconds: 250),
/// )
/// ```
class TtsAnnounce extends ConsumerStatefulWidget {
  /// The text to announce via TTS
  final String text;

  /// Whether TTS is enabled. If false, no announcements will be made.
  final bool enabled;

  /// Delay before speaking to avoid rapid successive announcements
  final Duration delay;

  /// Language code for TTS (e.g., 'en', 'hi'). If null, uses app locale.
  final String? languageCode;

  const TtsAnnounce({
    super.key,
    required this.text,
    this.enabled = true,
    this.delay = const Duration(milliseconds: 250),
    this.languageCode,
  });

  @override
  ConsumerState<TtsAnnounce> createState() => _TtsAnnounceState();
}

class _TtsAnnounceState extends ConsumerState<TtsAnnounce> {
  String? _lastSpoken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _announceIfNeeded();
    });
  }

  @override
  void didUpdateWidget(covariant TtsAnnounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.enabled != widget.enabled ||
        oldWidget.languageCode != widget.languageCode) {
      _announceIfNeeded();
    }
  }

  Future<void> _announceIfNeeded() async {
    if (!mounted || !widget.enabled) return;

    final normalized = widget.text.trim();
    if (normalized.isEmpty || normalized == _lastSpoken) return;

    await Future<void>.delayed(widget.delay);
    if (!mounted || !widget.enabled) return;

    final resolvedLanguageCode = widget.languageCode ??
        Localizations.localeOf(context).languageCode;

    await ref.read(contextualTtsServiceProvider).speakSummary(
          languageCode: resolvedLanguageCode,
          message: normalized,
        );
    _lastSpoken = normalized;
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
