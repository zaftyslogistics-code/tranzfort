import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/utils/sensitive_identifier_display.dart';

void main() {
  group('SensitiveIdentifierDisplay', () {
    test('maskedAadhaar formats 12-digit value', () {
      expect(
        SensitiveIdentifierDisplay.maskedAadhaar(fullDigits: '123456789012'),
        'XXXX XXXX 9012',
      );
    });

    test('maskedAadhaar uses last4 when full value absent', () {
      expect(
        SensitiveIdentifierDisplay.maskedAadhaar(last4: '9012'),
        'XXXX XXXX 9012',
      );
    });

    test('maskedPan formats full PAN', () {
      expect(
        SensitiveIdentifierDisplay.maskedPan(fullValue: 'ABCDE1234F'),
        'XXXXXX234F',
      );
    });

    test('maskedPan preserves server-masked value', () {
      expect(
        SensitiveIdentifierDisplay.maskedPan(fullValue: 'XXXXXX234F'),
        'XXXXXX234F',
      );
    });

    test('maskedGstin masks 15-character GSTIN', () {
      expect(
        SensitiveIdentifierDisplay.maskedGstin('22AAAAA0000A1Z5'),
        '22*********1Z5',
      );
    });

    test('maskedLast4 shows tail only', () {
      expect(
        SensitiveIdentifierDisplay.maskedLast4('LIC-998877'),
        '******8877',
      );
    });
  });
}
