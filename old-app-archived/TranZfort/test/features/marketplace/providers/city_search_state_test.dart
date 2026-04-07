import 'package:app/src/features/marketplace/providers/marketplace_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('citySearchProvider', () {
    test('returns empty list for short query without triggering search', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final suggestions = await container.read(citySearchProvider('m').future);
      expect(suggestions, isEmpty);
    });
  });
}
