import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/contextual_tts_service.dart';
import 'tts_audio_language_provider.dart';

/// Global TTS speaking state - true when TTS is currently speaking
/// This is managed by the service and consumed by UI components
final ttsSpeakingProvider = StateProvider<bool>((ref) => false);

/// Last manually spoken utterance (card/section/read-all).
final ttsLastUtteranceProvider = StateProvider<String?>((ref) => null);

/// Stable key for the currently active utterance (preferred over raw message matching).
final ttsActivePlaybackKeyProvider = StateProvider<String?>((ref) => null);

/// Global TTS muted state - persists across sessions via SharedPreferences
/// Key: 'tts_muted'
final ttsMutedProvider = StateNotifierProvider<TtsMutedNotifier, bool>((ref) {
  return TtsMutedNotifier();
});

/// Provider for screen-specific TTS summary builder
/// Screens can override this to provide rich TTS summaries
/// Usage: ref.read(ttsScreenSummaryProvider.notifier).state = (context) => "Your summary here";
final ttsScreenSummaryProvider = StateProvider<TtsSummaryBuilder?>((ref) => null);

/// Stable owner key for the current screen summary to avoid stale clears on
/// fast navigation.
final ttsScreenSummaryOwnerKeyProvider = StateProvider<String?>((ref) => null);

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
    String? playbackKey,
  }) async {
    final normalized = message.trim();
    if (normalized.isEmpty) {
      _ref.read(ttsSpeakingProvider.notifier).state = false;
      _ref.read(ttsActivePlaybackKeyProvider.notifier).state = null;
      return ContextualTtsOutcome.skipped;
    }

    _ref.read(ttsLastUtteranceProvider.notifier).state = normalized;
    _ref.read(ttsActivePlaybackKeyProvider.notifier).state =
        _normalizedPlaybackKey(playbackKey, fallbackMessage: normalized);
    _ref.read(ttsSpeakingProvider.notifier).state = true;
    try {
      return await _ref.read(contextualTtsServiceProvider).speakSummary(
            languageCode: resolveTtsLanguageCode(
              context: context,
              audioLanguageCode: _ref.read(ttsAudioLanguageProvider),
            ),
            message: normalized,
          );
    } finally {
      _ref.read(ttsSpeakingProvider.notifier).state = false;
      _ref.read(ttsActivePlaybackKeyProvider.notifier).state = null;
    }
  }

  Future<void> stop() async {
    _ref.read(ttsSpeakingProvider.notifier).state = false;
    _ref.read(ttsActivePlaybackKeyProvider.notifier).state = null;
    await _ref.read(contextualTtsServiceProvider).stop();
  }

  /// Whether this utterance is currently playing.
  ///
  /// Prefer passing [playbackKey] for stable matching across rebuilds; falls back
  /// to message text when no key is provided.
  bool isPlayingMessage(String message, {String? playbackKey}) {
    if (!_ref.read(ttsSpeakingProvider)) {
      return false;
    }
    final normalizedKey = _normalizedPlaybackKey(playbackKey);
    if (normalizedKey != null) {
      return _ref.read(ttsActivePlaybackKeyProvider) == normalizedKey;
    }
    final normalized = message.trim();
    if (normalized.isEmpty) {
      return false;
    }
    return _ref.read(ttsLastUtteranceProvider) == normalized;
  }

  /// Tap-to-listen: unmute if needed, stop if same message, otherwise play.
  ///
  /// Used by [TtsCardSpeakerButton], [TtsActionButton], and settings replay actions.
  Future<ContextualTtsOutcome> listenToggle({
    required BuildContext context,
    required String message,
    String? playbackKey,
  }) async {
    final normalized = message.trim();
    if (normalized.isEmpty) {
      return ContextualTtsOutcome.skipped;
    }

    if (isPlayingMessage(normalized, playbackKey: playbackKey)) {
      await stop();
      return ContextualTtsOutcome.skipped;
    }

    if (_ref.read(ttsMutedProvider)) {
      await _ref.read(ttsMutedProvider.notifier).setMuted(false);
    } else if (_ref.read(ttsSpeakingProvider)) {
      await stop();
    }

    if (!context.mounted) {
      return ContextualTtsOutcome.skipped;
    }
    return play(
      context: context,
      message: normalized,
      playbackKey: playbackKey,
    );
  }

  /// Screen summary from [ttsScreenSummaryProvider], if registered.
  String? screenSummaryFor(BuildContext context) {
    final builder = _ref.read(ttsScreenSummaryProvider);
    if (builder == null) {
      return null;
    }
    final summary = builder(context).trim();
    return summary.isEmpty ? null : summary;
  }

  String? _normalizedPlaybackKey(
    String? playbackKey, {
    String? fallbackMessage,
  }) {
    final normalized = (playbackKey ?? '').trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }
    final fallback = (fallbackMessage ?? '').trim();
    return fallback.isEmpty ? null : fallback;
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

