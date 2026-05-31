/// Parses trip list `routeLabel` strings into origin/destination for [MarketplaceRouteLine].
class TripRouteEndpoints {
  final String originCity;
  final String originState;
  final String destinationCity;
  final String destinationState;

  const TripRouteEndpoints({
    required this.originCity,
    required this.originState,
    required this.destinationCity,
    required this.destinationState,
  });
}

TripRouteEndpoints? parseTripRouteLabel(String routeLabel) {
  final trimmed = routeLabel.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  const separators = [' > ', ' → ', ' to ', ' - '];
  for (final separator in separators) {
    final index = trimmed.indexOf(separator);
    if (index > 0) {
      return _splitLocationPair(
        trimmed.substring(0, index).trim(),
        trimmed.substring(index + separator.length).trim(),
      );
    }
  }

  return null;
}

TripRouteEndpoints? tripRouteFromLabels({
  required String originLabel,
  required String destinationLabel,
}) {
  final origin = originLabel.trim();
  final destination = destinationLabel.trim();
  if (origin.isEmpty || destination.isEmpty) {
    return null;
  }
  return _splitLocationPair(origin, destination);
}

TripRouteEndpoints _splitLocationPair(String origin, String destination) {
  final (originCity, originState) = _splitCityState(origin);
  final (destinationCity, destinationState) = _splitCityState(destination);
  return TripRouteEndpoints(
    originCity: originCity,
    originState: originState,
    destinationCity: destinationCity,
    destinationState: destinationState,
  );
}

(String city, String state) _splitCityState(String value) {
  final parts = value.split(',').map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) {
    return ('', '');
  }
  if (parts.length == 1) {
    return (parts.first, '');
  }
  return (parts.first, parts.sublist(1).join(', '));
}
