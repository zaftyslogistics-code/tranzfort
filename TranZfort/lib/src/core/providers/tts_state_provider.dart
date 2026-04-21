import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/contextual_tts_service.dart';

/// Global TTS speaking state - true when TTS is currently speaking
/// This is managed by the service and consumed by UI components
final ttsSpeakingProvider = StateProvider<bool>((ref) => false);

/// Global TTS muted state - persists across sessions via SharedPreferences
/// Key: 'tts_muted'
final ttsMutedProvider = StateNotifierProvider<TtsMutedNotifier, bool>((ref) {
  return TtsMutedNotifier();
});

/// Provider for screen-specific TTS summary builder
/// Screens can override this to provide rich TTS summaries
/// Usage: ref.read(ttsScreenSummaryProvider.notifier).state = (context) => "Your summary here";
final ttsScreenSummaryProvider = StateProvider<TtsSummaryBuilder?>((ref) => null);

/// Type definition for TTS summary builder functions
typedef TtsSummaryBuilder = String Function(BuildContext context);

final ttsPlaybackControllerProvider = Provider<TtsPlaybackController>((ref) {
  return TtsPlaybackController(ref);
});

class TtsPlaybackController {
  TtsPlaybackController(this._ref);

  final Ref _ref;

  Future<ContextualTtsOutcome> play({
    required BuildContext context,
    required String message,
  }) async {
    final normalized = message.trim();
    if (normalized.isEmpty) {
      _ref.read(ttsSpeakingProvider.notifier).state = false;
      return ContextualTtsOutcome.skipped;
    }

    _ref.read(ttsSpeakingProvider.notifier).state = true;
    try {
      return await _ref.read(contextualTtsServiceProvider).speakSummary(
            languageCode: Localizations.localeOf(context).languageCode,
            message: normalized,
          );
    } finally {
      _ref.read(ttsSpeakingProvider.notifier).state = false;
    }
  }

  Future<void> stop() async {
    _ref.read(ttsSpeakingProvider.notifier).state = false;
    await _ref.read(contextualTtsServiceProvider).stop();
  }
}

/// Notifier for TTS muted state with SharedPreferences persistence
class TtsMutedNotifier extends StateNotifier<bool> {
  static const String _mutedKey = 'tts_muted';
  bool _initialized = false;

  TtsMutedNotifier() : super(false) {
    _loadMutedState();
  }

  /// Load muted state from SharedPreferences
  Future<void> _loadMutedState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_mutedKey) ?? false; // Default to unmuted
    _initialized = true;
  }

  /// Toggle muted state and persist to SharedPreferences
  Future<void> toggleMuted() async {
    final newState = !state;
    await _setMuted(newState);
  }

  /// Set muted state explicitly
  Future<void> setMuted(bool muted) async {
    await _setMuted(muted);
  }

  /// Reset to unmuted state (call on app startup to ensure default behavior)
  Future<void> resetToUnmuted() async {
    await _setMuted(false);
  }

  Future<void> _setMuted(bool muted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mutedKey, muted);
    state = muted;
  }

  /// Check if the notifier has finished loading initial state
  bool get isInitialized => _initialized;
}

/// Provider that exposes a global stop function for TTS
/// Usage: ref.read(ttsGlobalStopProvider)()
final ttsGlobalStopProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final service = ref.read(contextualTtsServiceProvider);
    await service.stop();
  };
});

