import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/providers/auth_providers.dart';

class SettingsState {
  final bool ttsMuted;
  final bool pushEnabled;
  final String language;

  const SettingsState({
    this.ttsMuted = false,
    this.pushEnabled = true,
    this.language = 'en',
  });

  SettingsState copyWith({
    bool? ttsMuted,
    bool? pushEnabled,
    String? language,
  }) {
    return SettingsState(
      ttsMuted: ttsMuted ?? this.ttsMuted,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      language: language ?? this.language,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;

  SettingsNotifier(this._ref) : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      ttsMuted: prefs.getBool('tts_muted') ?? false,
      pushEnabled: prefs.getBool('push_enabled') ?? true,
    );
  }

  Future<void> toggleTts(bool muted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tts_muted', muted);
    // Also update tts_enabled which was used by TtsService internally
    await prefs.setBool('tts_enabled', !muted);
    state = state.copyWith(ttsMuted: muted);
  }

  Future<void> togglePush(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_enabled', enabled);
    state = state.copyWith(pushEnabled: enabled);
  }

  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
    // V1 only supports English UI, so we don't persist this yet
  }

  Future<bool> deleteAccount() async {
    try {
      final user = _ref.read(authSessionProvider).value?.session?.user;
      if (user == null) return false;

      await _ref.read(supabaseClientProvider)
          .from('profiles')
          .update({'data_deletion_requested_at': DateTime.now().toIso8601String()})
          .eq('id', user.id);

      await signOut();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _ref.read(authRepositoryProvider).signOut();
    final prefs = await SharedPreferences.getInstance();
    
    // Clear all prefs except has_seen_splash
    final hasSeenSplash = prefs.getBool('has_seen_splash');
    await prefs.clear();
    if (hasSeenSplash != null) {
      await prefs.setBool('has_seen_splash', hasSeenSplash);
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});
