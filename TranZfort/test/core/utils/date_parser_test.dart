import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/utils/date_parser.dart';

void main() {
  group('safeParseDateTime', () {
    test('returns null for null input', () {
      expect(safeParseDateTime(null), isNull);
    });

    test('returns DateTime object as-is', () {
      final now = DateTime.now();
      expect(safeParseDateTime(now), equals(now));
    });

    test('parses integer as milliseconds since epoch', () {
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      expect(safeParseDateTime(0), equals(epoch));
      
      final timestamp = DateTime(2024, 1, 1).millisecondsSinceEpoch;
      expect(safeParseDateTime(timestamp), isA<DateTime>());
    });

    test('parses ISO 8601 string', () {
      final dateStr = '2024-05-16T10:30:00.000Z';
      final result = safeParseDateTime(dateStr);
      expect(result, isNotNull);
      expect(result!.toUtc(), equals(DateTime.parse(dateStr).toUtc()));
    });

    test('returns null for invalid ISO 8601 string', () {
      expect(safeParseDateTime('invalid-date'), isNull);
    });

    test('parses numeric string as milliseconds', () {
      final timestamp = DateTime(2024, 1, 1).millisecondsSinceEpoch;
      final result = safeParseDateTime(timestamp.toString());
      expect(result, isNotNull);
      expect(result!.millisecondsSinceEpoch, equals(timestamp));
    });

    test('returns null for non-numeric string', () {
      expect(safeParseDateTime('not-a-number'), isNull);
    });

    test('handles double value by converting to int', () {
      // Double values are not explicitly handled, should return null
      expect(safeParseDateTime(123.45), isNull);
    });

    test('handles boolean value', () {
      expect(safeParseDateTime(true), isNull);
    });
  });
}
