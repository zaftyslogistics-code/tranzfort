import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/utils/type_safety.dart';

void main() {
  group('safeCast', () {
    test('returns null for null input', () {
      expect(safeCast<String>(null), isNull);
    });

    test('returns value if correct type', () {
      expect(safeCast<String>('hello'), equals('hello'));
      expect(safeCast<int>(42), equals(42));
      expect(safeCast<bool>(true), equals(true));
    });

    test('returns null for wrong type', () {
      expect(safeCast<int>('42'), isNull);
      expect(safeCast<String>(42), isNull);
      expect(safeCast<bool>('true'), isNull);
    });
  });

  group('safeMap', () {
    test('returns null for null input', () {
      expect(safeMap(null), isNull);
    });

    test('returns Map<String, dynamic> as-is', () {
      final map = <String, dynamic>{'key': 'value'};
      expect(safeMap(map), equals(map));
    });

    test('converts untyped Map to Map<String, dynamic>', () {
      final map = {'key': 'value'}; // Untyped Map
      final result = safeMap(map);
      expect(result, isNotNull);
      expect(result!['key'], equals('value'));
      expect(result, isA<Map<String, dynamic>>());
    });

    test('returns null for non-Map value', () {
      expect(safeMap('not a map'), isNull);
      expect(safeMap(42), isNull);
    });
  });

  group('safeList', () {
    test('returns null for null input', () {
      expect(safeList<String>(null), isNull);
    });

    test('returns List<T> as-is', () {
      final list = <String>['a', 'b', 'c'];
      expect(safeList<String>(list), equals(list));
    });

    test('casts untyped List to List<T>', () {
      final list = ['a', 'b', 'c']; // Untyped List
      final result = safeList<String>(list);
      expect(result, isNotNull);
      expect(result!.length, equals(3));
      expect(result, isA<List<String>>());
    });

    test('returns null if cast fails', () {
      final list = [1, 2, 3]; // List of ints
      expect(safeList<String>(list), isNull);
    });

    test('returns null for non-List value', () {
      expect(safeList<String>('not a list'), isNull);
      expect(safeList<int>(42), isNull);
    });
  });

  group('safeString', () {
    test('returns empty string for null input', () {
      expect(safeString(null), equals(''));
    });

    test('returns toString() for non-null values', () {
      expect(safeString('hello'), equals('hello'));
      expect(safeString(42), equals('42'));
      expect(safeString(true), equals('true'));
      expect(safeString(3.14), equals('3.14'));
    });

    test('handles objects with custom toString', () {
      final obj = DateTime(2024, 5, 16);
      expect(safeString(obj), contains('2024'));
    });
  });
}
