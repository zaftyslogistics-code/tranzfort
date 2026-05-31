import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/utils/listing_expiry.dart';

void main() {
  test('isListingExpiringSoon is true inside 48h window', () {
    final until = DateTime.now().add(const Duration(hours: 12));
    expect(isListingExpiringSoon(until), isTrue);
  });

  test('isListingExpiringSoon is false when already ended', () {
    final until = DateTime.now().subtract(const Duration(hours: 1));
    expect(isListingExpiringSoon(until), isFalse);
  });
}
