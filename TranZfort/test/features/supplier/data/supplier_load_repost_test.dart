import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/features/supplier/data/load_listing_duration.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_repost.dart';

void main() {
  test('RepostLoadRequest maps to clone_load_for_repost RPC params', () {
    final request = RepostLoadRequest(
      sourceLoadId: '11111111-1111-1111-1111-111111111111',
      pickupDate: DateTime(2026, 6, 20),
      listingDuration: LoadListingDuration.hours48,
    );

    final params = request.toRpcParams();
    expect(params['p_source_load_id'], request.sourceLoadId);
    expect(params['p_pickup_date'], '2026-06-20');
    expect(params['p_listing_duration'], '48_hours');
  });
}
