import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/utils/rpc_response_parser.dart';

void main() {
  test('parseRpcJsonbRowList accepts decoded list rows', () {
    final rows = parseRpcJsonbRowList([
      {'id': 'trip-1', 'stage': 'in_transit'},
    ]);

    expect(rows, hasLength(1));
    expect(rows.first['id'], 'trip-1');
  });

  test('parseRpcJsonbRowList accepts JSON string payloads', () {
    final rows = parseRpcJsonbRowList(
      '[{"id":"trip-2","stage":"assigned"}]',
    );

    expect(rows, hasLength(1));
    expect(rows.first['stage'], 'assigned');
  });

  test('parseRpcJsonbRowList returns empty list for unknown shapes', () {
    expect(parseRpcJsonbRowList(null), isEmpty);
    expect(parseRpcJsonbRowList(42), isEmpty);
  });
}
