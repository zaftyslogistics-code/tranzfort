import 'package:flutter_test/flutter_test.dart';

import 'package:app/src/core/config/maps_config.dart';
import 'package:app/src/core/services/city_search_service.dart';

void main() {
  group('CitySearchService', () {
    test('returns fallback suggestions for offline query', () async {
      const config = MapsConfig(placesApiKey: '');
      const service = CitySearchService(config);

      final results = await service.search('mum');

      expect(results, isNotEmpty);
      expect(
        results.any((item) => item.city.toLowerCase() == 'mumbai'),
        isTrue,
      );
    });

    test('returns empty list for very short query', () async {
      const config = MapsConfig(placesApiKey: '');
      const service = CitySearchService(config);

      final results = await service.search('m');

      expect(results, isEmpty);
    });
  });
}
