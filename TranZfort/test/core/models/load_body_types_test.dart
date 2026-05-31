import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/models/load_body_types.dart';

void main() {
  test('any maps to null for database', () {
    expect(LoadBodyTypes.toDatabaseValue('any'), isNull);
    expect(LoadBodyTypes.toDatabaseValue('open'), 'open');
  });

  test('selectable matches post-load list', () {
    expect(LoadBodyTypes.selectable, contains('refrigerated'));
    expect(LoadBodyTypes.selectable.first, 'any');
  });

  test('filterChipTypes excludes any and uses lowercase', () {
    expect(LoadBodyTypes.filterChipTypes, isNot(contains(LoadBodyTypes.any)));
    expect(LoadBodyTypes.filterChipTypes.first, 'open');
  });
}
