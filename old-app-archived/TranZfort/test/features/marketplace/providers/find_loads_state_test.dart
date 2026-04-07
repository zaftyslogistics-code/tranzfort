import 'package:app/src/features/marketplace/providers/marketplace_providers.dart';
import 'package:app/src/features/marketplace/models/load_filters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoadFilters', () {
    test('copyWith updates selected fields and preserves others', () {
      const initial = LoadFilters(originCity: 'Mumbai', sortBy: 'newest');

      final updated = initial.copyWith(
        destinationCity: 'Pune',
        material: 'Steel',
      );

      expect(updated.originCity, 'Mumbai');
      expect(updated.destinationCity, 'Pune');
      expect(updated.material, 'Steel');
      expect(updated.sortBy, 'newest');
    });
  });

  group('FindLoadsState', () {
    test('copyWith updates search state while preserving existing values', () {
      const initial = FindLoadsState();

      final updated = initial.copyWith(
        isSearching: true,
        hasMore: false,
        error: 'network',
        isRefreshing: true,
        results: const [
          {'id': 'load-1'},
        ],
      );

      expect(updated.isSearching, isTrue);
      expect(updated.hasMore, isFalse);
      expect(updated.results.length, 1);
      expect(updated.error, 'network');
      expect(updated.isRefreshing, isTrue);

      final withFilters = updated.copyWith(
        filters: const LoadFilters(material: 'Steel'),
      );
      expect(withFilters.filters.material, 'Steel');
      expect(withFilters.results.length, 1);
    });
  });
}
