/// TTS voice model representing a discovered voice from the device's TTS engine.
class TtsVoice {
  /// Unique identifier for the voice (e.g., "en-us-x-sfg#male_1-local")
  final String voiceId;

  /// Human-readable name of the voice (e.g., "English (United States) - Male")
  final String name;

  /// Locale code (e.g., "en-US", "hi-IN")
  final String locale;

  /// Language code (e.g., "en", "hi")
  final String language;

  /// Whether this voice is available offline (no network required)
  final bool isOffline;

  /// Whether this is the default voice for its locale
  final bool isDefault;

  const TtsVoice({
    required this.voiceId,
    required this.name,
    required this.locale,
    required this.language,
    required this.isOffline,
    this.isDefault = false,
  });

  /// Creates a TtsVoice from a map (for SharedPreferences persistence).
  factory TtsVoice.fromMap(Map<String, dynamic> map) {
    return TtsVoice(
      voiceId: map['voiceId'] as String,
      name: map['name'] as String,
      locale: map['locale'] as String,
      language: map['language'] as String,
      isOffline: map['isOffline'] as bool,
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  /// Converts to a map for SharedPreferences persistence.
  Map<String, dynamic> toMap() {
    return {
      'voiceId': voiceId,
      'name': name,
      'locale': locale,
      'language': language,
      'isOffline': isOffline,
      'isDefault': isDefault,
    };
  }

  /// Checks if this voice supports the given language code.
  bool supportsLanguage(String languageCode) {
    return language == languageCode.toLowerCase();
  }

  /// Checks if this voice is a Hindi voice.
  bool get isHindi => language == 'hi';

  /// Checks if this voice is an English voice.
  bool get isEnglish => language == 'en';

  @override
  String toString() {
    return 'TtsVoice(voiceId: $voiceId, name: $name, locale: $locale, language: $language, isOffline: $isOffline, isDefault: $isDefault)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TtsVoice && other.voiceId == voiceId;
  }

  @override
  int get hashCode => voiceId.hashCode;
}
