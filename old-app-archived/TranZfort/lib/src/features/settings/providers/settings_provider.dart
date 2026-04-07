import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/providers/auth_providers.dart';

class SettingsState {
  final bool ttsMuted;
  final double ttsSpeed;
  final String ttsLanguageMode;
  final bool pushEnabled;
  final String language;

  const SettingsState({
    this.ttsMuted = false,
    this.ttsSpeed = 0.5,
    this.ttsLanguageMode = 'auto',
    this.pushEnabled = true,
    this.language = 'hi',
  });

  SettingsState copyWith({
    bool? ttsMuted,
    double? ttsSpeed,
    String? ttsLanguageMode,
    bool? pushEnabled,
    String? language,
  }) {
    return SettingsState(
      ttsMuted: ttsMuted ?? this.ttsMuted,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      ttsLanguageMode: ttsLanguageMode ?? this.ttsLanguageMode,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      language: language ?? this.language,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;
  static const _languageKey = 'app_language';
  static const _ttsSpeedKey = 'tts_speed';
  static const _ttsLanguageModeKey = 'tts_language_mode';

  SettingsNotifier(this._ref) : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      ttsMuted: prefs.getBool('tts_muted') ?? false,
      ttsSpeed:
          ((prefs.getDouble(_ttsSpeedKey) ?? 0.5).clamp(0.3, 0.8) as num)
              .toDouble(),
      ttsLanguageMode: prefs.getString(_ttsLanguageModeKey) ?? 'auto',
      pushEnabled: prefs.getBool('push_enabled') ?? true,
      language: prefs.getString(_languageKey) ?? 'hi',
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

  Future<void> setTtsSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = (speed.clamp(0.3, 0.8) as num).toDouble();
    await prefs.setDouble(_ttsSpeedKey, normalized);
    state = state.copyWith(ttsSpeed: normalized);
  }

  Future<void> setTtsLanguageMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = switch (mode) {
      'hi' => 'hi',
      'en' => 'en',
      _ => 'auto',
    };
    await prefs.setString(_ttsLanguageModeKey, normalized);
    state = state.copyWith(ttsLanguageMode: normalized);
  }

  Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, lang);
    state = state.copyWith(language: lang);
  }

  Future<bool> deleteAccount() async {
    try {
      final user = _ref.read(authSessionProvider).value?.session?.user;
      if (user == null) return false;

      await _ref
          .read(supabaseClientProvider)
          .from('profiles')
          .update({
            'data_deletion_requested_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      await signOut();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _ref.read(authRepositoryProvider).signOut();
    _ref.invalidate(userProfileProvider);
    _ref.invalidate(userRoleProvider);
    _ref.invalidate(authSessionProvider);
    final prefs = await SharedPreferences.getInstance();

    // Clear all prefs except has_seen_splash
    final hasSeenSplash = prefs.getBool('has_seen_splash');
    await prefs.clear();
    if (hasSeenSplash != null) {
      await prefs.setBool('has_seen_splash', hasSeenSplash);
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier(ref);
  },
);
