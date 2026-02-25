class MapsConfig {
  final String placesApiKey;

  const MapsConfig({required this.placesApiKey});

  factory MapsConfig.fromEnvironment() {
    return MapsConfig(
      placesApiKey: const String.fromEnvironment('GOOGLE_PLACES_API_KEY'),
    );
  }

  bool get hasPlacesApiKey => placesApiKey.trim().isNotEmpty;
}
