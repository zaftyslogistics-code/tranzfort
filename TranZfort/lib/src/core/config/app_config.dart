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

  // ─── Trip Costing Configuration ───
  // These can be overridden via --dart-define if needed for different regions/market conditions
  // Example: flutter build apk --dart-define=DEFAULT_DIESEL_PRICE=95

  /// Default diesel price per litre in INR (₹)
  static double get defaultDieselPricePerLitre =>
      double.tryParse(const String.fromEnvironment('DEFAULT_DIESEL_PRICE', defaultValue: '90')) ?? 90;

  /// Default vehicle mileage in km per litre
  static double get defaultMileageKmpl =>
      double.tryParse(const String.fromEnvironment('DEFAULT_MILEAGE_KMPL', defaultValue: '2.5')) ?? 2.5;

  /// Default number of axles for toll calculation
  static int get defaultAxles =>
      int.tryParse(const String.fromEnvironment('DEFAULT_AXLES', defaultValue: '4')) ?? 4;

  /// Toll cost per km in INR (₹)
  static double get tollPerKm =>
      double.tryParse(const String.fromEnvironment('TOLL_PER_KM', defaultValue: '11')) ?? 11;

  /// Driver cost per km in INR (₹) - allowance + batta + food
  static double get driverCostPerKm =>
      double.tryParse(const String.fromEnvironment('DRIVER_COST_PER_KM', defaultValue: '5')) ?? 5;

  /// Miscellaneous cost per km in INR (₹) - maintenance/misc/tyre wear
  static double get miscCostPerKm =>
      double.tryParse(const String.fromEnvironment('MISC_COST_PER_KM', defaultValue: '2')) ?? 2;
}
