import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/utils/super_load_visibility.dart';

void main() {
  group('isPublicSuperLoad', () {
    test('returns false for pending request with stale is_super_load flag', () {
      expect(
        isPublicSuperLoad(isSuperLoad: true, superStatus: 'request_submitted'),
        isFalse,
      );
      expect(
        isPublicSuperLoad(isSuperLoad: true, superStatus: 'under_review'),
        isFalse,
      );
    });

    test('returns true only for approved marketplace states', () {
      expect(
        isPublicSuperLoad(isSuperLoad: true, superStatus: 'approved_payment_pending'),
        isTrue,
      );
      expect(
        isPublicSuperLoad(isSuperLoad: true, superStatus: 'active'),
        isTrue,
      );
    });

    test('returns false when rejected or not super', () {
      expect(
        isPublicSuperLoad(isSuperLoad: false, superStatus: 'rejected'),
        isFalse,
      );
      expect(
        isPublicSuperLoad(isSuperLoad: false, superStatus: 'none'),
        isFalse,
      );
    });
  });
}
