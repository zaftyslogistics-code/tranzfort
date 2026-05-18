/// Application configuration constants.
///
/// This file contains configuration for the TranZfort app.
library;

/// Google Maps API key configuration.
///
/// The API key is passed via --dart-define at build time:
/// flutter build apk --dart-define=GOOGLE_MAPS_API_KEY=your_key_here
class AppConfig {
  /// Returns the Google Maps API key from compile-time environment.
  /// Returns empty string if not provided - location services will fall back to offline mode.
  static String get googleMapsApiKey =>
      const String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');

  /// Returns true if the Google Maps API key is configured.
  static bool get isGoogleMapsConfigured => googleMapsApiKey.isNotEmpty;
}

