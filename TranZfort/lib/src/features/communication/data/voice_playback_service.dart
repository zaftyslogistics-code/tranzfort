import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/app_state_providers.dart';

class VoicePlaybackSnapshot {
  final bool isLoading;
  final bool isPlaying;
  final Duration position;
  final Duration? duration;

  const VoicePlaybackSnapshot({
    required this.isLoading,
    required this.isPlaying,
    required this.position,
    required this.duration,
  });

  const VoicePlaybackSnapshot.initial()
      : isLoading = false,
        isPlaying = false,
        position = Duration.zero,
        duration = null;

  VoicePlaybackSnapshot copyWith({
    bool? isLoading,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    bool? clearDuration,
  }) {
    return VoicePlaybackSnapshot(
      isLoading: isLoading ?? this.isLoading,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: clearDuration == true ? null : duration ?? this.duration,
    );
  }
}

abstract class VoicePlaybackController {
  ValueListenable<VoicePlaybackSnapshot> get snapshot;
  Future<void> togglePlayback(String signedUrl);
  Future<void> dispose();
}

class JustAudioVoicePlaybackController implements VoicePlaybackController {
  final AudioPlayer _player;
  final ValueNotifier<VoicePlaybackSnapshot> _snapshot =
      ValueNotifier<VoicePlaybackSnapshot>(const VoicePlaybackSnapshot.initial());
  final List<StreamSubscription<dynamic>> _subscriptions = <StreamSubscription<dynamic>>[];
  String? _loadedUrl;

  JustAudioVoicePlaybackController({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _subscriptions.add(
      _player.playerStateStream.listen((state) {
        _snapshot.value = _snapshot.value.copyWith(
          isPlaying: state.playing,
          isLoading: state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering,
          position: state.processingState == ProcessingState.completed ? Duration.zero : null,
        );
        if (state.processingState == ProcessingState.completed) {
          unawaited(_player.seek(Duration.zero));
          unawaited(_player.pause());
        }
      }),
    );
    _subscriptions.add(
      _player.positionStream.listen((position) {
        _snapshot.value = _snapshot.value.copyWith(position: position);
      }),
    );
    _subscriptions.add(
      _player.durationStream.listen((duration) {
        _snapshot.value = _snapshot.value.copyWith(duration: duration);
      }),
    );
  }

  @override
  ValueListenable<VoicePlaybackSnapshot> get snapshot => _snapshot;

  @override
  Future<void> togglePlayback(String signedUrl) async {
    if (_loadedUrl != signedUrl) {
      _snapshot.value = _snapshot.value.copyWith(isLoading: true, position: Duration.zero, clearDuration: true);
      await _player.setUrl(signedUrl);
      _loadedUrl = signedUrl;
      _snapshot.value = _snapshot.value.copyWith(isLoading: false);
    }

    if (_player.playing) {
      await _player.pause();
      return;
    }
    await _player.play();
  }

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
    _snapshot.dispose();
  }
}

class VoicePlaybackService {
  final SupabaseClient? _client;

  const VoicePlaybackService(this._client);

  Future<String?> createSignedUrl(String path) async {
    final normalizedPath = path.trim();
    if (_client == null || normalizedPath.isEmpty) {
      return null;
    }
    return _client.storage.from('communication-media').createSignedUrl(normalizedPath, 3600);
  }
}

typedef VoicePlaybackControllerFactory = VoicePlaybackController Function();

final voicePlaybackServiceProvider = Provider<VoicePlaybackService>((ref) {
  return VoicePlaybackService(ref.watch(supabaseClientProvider));
});

final voicePlaybackControllerFactoryProvider = Provider<VoicePlaybackControllerFactory>((ref) {
  return () => JustAudioVoicePlaybackController();
});
