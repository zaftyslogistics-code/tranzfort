import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/utils/trip_route_label_parser.dart';

void main() {
  test('parseTripRouteLabel splits arrow separator', () {
    final endpoints = parseTripRouteLabel('Mumbai, MH > Delhi, DL');
    expect(endpoints, isNotNull);
    expect(endpoints!.originCity, 'Mumbai');
    expect(endpoints.originState, 'MH');
    expect(endpoints.destinationCity, 'Delhi');
    expect(endpoints.destinationState, 'DL');
  });

  test('tripRouteFromLabels splits comma-separated labels', () {
    final endpoints = tripRouteFromLabels(
      originLabel: 'Pune, Maharashtra',
      destinationLabel: 'Chennai, Tamil Nadu',
    );
    expect(endpoints, isNotNull);
    expect(endpoints!.originCity, 'Pune');
    expect(endpoints.destinationCity, 'Chennai');
  });
}
