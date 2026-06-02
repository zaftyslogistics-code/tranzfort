import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../providers/tts_state_provider.dart';

class TtsScreenSummaryEffect extends ConsumerStatefulWidget {
  final String summary;
  final String? screenKey;
  final bool autoPlay;

  const TtsScreenSummaryEffect({
    super.key,
    required this.summary,
    this.screenKey,
    this.autoPlay = false,
  });

  @override
  ConsumerState<TtsScreenSummaryEffect> createState() => _TtsScreenSummaryEffectState();
}

class _TtsScreenSummaryEffectState extends ConsumerState<TtsScreenSummaryEffect> {
  String? _lastSummary;
  String? _lastAnnouncedKey;
  late final StateController<TtsSummaryBuilder?> _summaryController;
  late final StateController<String?> _ownerKeyController;
  String? _instanceKey;

  @override
  void initState() {
    super.initState();
    _summaryController = ref.read(ttsScreenSummaryProvider.notifier);
    _ownerKeyController = ref.read(ttsScreenSummaryOwnerKeyProvider.notifier);
    _instanceKey = widget.screenKey ?? '';
    // Sync immediately to avoid stale summary being used on fast navigation.
    _syncSummary();
    WidgetsBinding.instance.addPostFrameCallback((_) => _announceIfNeeded());
  }

  @override
  void didUpdateWidget(covariant TtsScreenSummaryEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.summary != widget.summary || oldWidget.screenKey != widget.screenKey || oldWidget.autoPlay != widget.autoPlay) {
      _instanceKey = widget.screenKey ?? '';
      _syncSummary();
      WidgetsBinding.instance.addPostFrameCallback((_) => _announceIfNeeded());
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
    final ownerKey = (widget.screenKey ?? '').trim();
    _ownerKeyController.state = ownerKey.isEmpty ? null : ownerKey;
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
    // Avoid clearing a newer screen's summary (race on fast navigation).
    final capturedKey = _instanceKey;
    scheduleMicrotask(() {
      try {
        final currentOwnerKey = _ownerKeyController.state;
        if (capturedKey == null || capturedKey.isEmpty || currentOwnerKey == null) {
          return;
        }
        // Clear only if this instance still owns the current summary.
        if (currentOwnerKey == capturedKey) {
          _summaryController.state = null;
          _ownerKeyController.state = null;
        }
      } catch (_) {
        return;
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
