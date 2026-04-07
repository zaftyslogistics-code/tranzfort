import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/tts_service.dart';

class TtsAnnounce extends ConsumerStatefulWidget {
  final String text;
  final bool enabled;
  final Duration delay;

  const TtsAnnounce({
    super.key,
    required this.text,
    this.enabled = true,
    this.delay = const Duration(milliseconds: 250),
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
    if (oldWidget.text != widget.text || oldWidget.enabled != widget.enabled) {
      _announceIfNeeded();
    }
  }

  Future<void> _announceIfNeeded() async {
    if (!mounted || !widget.enabled) return;

    final normalized = widget.text.trim();
    if (normalized.isEmpty || normalized == _lastSpoken) return;

    await Future<void>.delayed(widget.delay);
    if (!mounted || !widget.enabled) return;

    await ref.read(ttsServiceProvider).speak(normalized);
    _lastSpoken = normalized;
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
