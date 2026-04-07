import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tts_state_provider.dart';

class TtsScreenSummaryEffect extends ConsumerStatefulWidget {
  final String summary;
  final String? screenKey;
  final bool autoPlay;

  const TtsScreenSummaryEffect({
    super.key,
    required this.summary,
    this.screenKey,
    this.autoPlay = true,
  });

  @override
  ConsumerState<TtsScreenSummaryEffect> createState() => _TtsScreenSummaryEffectState();
}

class _TtsScreenSummaryEffectState extends ConsumerState<TtsScreenSummaryEffect> {
  String? _lastSummary;
  String? _lastAnnouncedKey;
  late final StateController<TtsSummaryBuilder?> _summaryController;

  @override
  void initState() {
    super.initState();
    _summaryController = ref.read(ttsScreenSummaryProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncSummary();
      _announceIfNeeded();
    });
  }

  @override
  void didUpdateWidget(covariant TtsScreenSummaryEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.summary != widget.summary || oldWidget.screenKey != widget.screenKey || oldWidget.autoPlay != widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncSummary();
        _announceIfNeeded();
      });
    }
  }

  void _syncSummary() {
    if (!mounted) {
      return;
    }
    final normalized = widget.summary.trim();
    if (_lastSummary == normalized) {
      return;
    }
    _lastSummary = normalized;
    _summaryController.state = normalized.isEmpty ? null : (_) => normalized;
  }

  Future<void> _announceIfNeeded() async {
    if (!mounted || !widget.autoPlay) {
      return;
    }

    final normalized = widget.summary.trim();
    final announcementKey = widget.screenKey ?? normalized;
    if (normalized.isEmpty || _lastAnnouncedKey == announcementKey) {
      return;
    }

    _lastAnnouncedKey = announcementKey;
    await ref.read(ttsPlaybackControllerProvider).play(
          context: context,
          message: normalized,
        );
  }

  @override
  void dispose() {
    _summaryController.state = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
