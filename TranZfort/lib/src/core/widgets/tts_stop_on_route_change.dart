import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tts_state_provider.dart';

/// Stops in-flight TTS when the shell route changes or this subtree is disposed.
class TtsStopOnRouteChange extends ConsumerStatefulWidget {
  final String routeKey;
  final Widget child;

  const TtsStopOnRouteChange({
    super.key,
    required this.routeKey,
    required this.child,
  });

  @override
  ConsumerState<TtsStopOnRouteChange> createState() => _TtsStopOnRouteChangeState();
}

class _TtsStopOnRouteChangeState extends ConsumerState<TtsStopOnRouteChange> {
  @override
  void didUpdateWidget(covariant TtsStopOnRouteChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeKey != widget.routeKey) {
      _stopSpeech();
    }
  }

  @override
  void dispose() {
    _stopSpeech();
    super.dispose();
  }

  void _stopSpeech() {
    ref.read(ttsPlaybackControllerProvider).stop();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
