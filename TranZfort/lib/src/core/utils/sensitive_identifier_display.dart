/// Display helpers for government IDs on verification review and profile surfaces.
/// Never log or persist values through these formatters — input is already in memory.
class SensitiveIdentifierDisplay {
  SensitiveIdentifierDisplay._();

  static const String _maskedPanPrefix = 'XXXXXX';

  /// Aadhaar review line: `XXXX XXXX 1234` (last 4 only).
  static String maskedAadhaar({String? fullDigits, String? last4}) {
    final digits = _digitsOnly(fullDigits);
    if (digits.length >= 12) {
      return 'XXXX XXXX ${digits.substring(8)}';
    }
    if (digits.length >= 4) {
      return 'XXXX XXXX ${digits.substring(digits.length - 4)}';
    }
    final tail = (last4 ?? '').trim();
    if (tail.length == 4 && RegExp(r'^\d{4}$').hasMatch(tail)) {
      return 'XXXX XXXX $tail';
    }
    return '-';
  }

  /// PAN review line aligned with [get_current_user_profile] masked PAN.
  static String maskedPan({String? fullValue, String? last4}) {
    final normalized = (fullValue ?? '').trim().toUpperCase();
    if (normalized.startsWith(_maskedPanPrefix) && normalized.length >= 10) {
      return normalized;
    }
    final digits = _digitsOnly(fullValue);
    final panBody = normalized.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final source = panBody.length >= 4
        ? panBody
        : (digits.length >= 4 ? digits : '');
    if (source.length >= 4) {
      return '$_maskedPanPrefix${source.substring(source.length - 4)}';
    }
    final tail = (last4 ?? '').trim().toUpperCase();
    if (tail.length == 4) {
      return '$_maskedPanPrefix$tail';
    }
    return '-';
  }

  /// GSTIN review line: first 2 + masked middle + last 3 (15-char GSTIN).
  static String maskedGstin(String? value) {
    final gst = (value ?? '').trim().toUpperCase();
    if (gst.isEmpty) return '-';
    if (gst.length <= 5) {
      return '*' * (gst.length - 1) + gst.substring(gst.length - 1);
    }
    if (gst.length < 15) {
      return '${gst.substring(0, 2)}${'*' * (gst.length - 5)}${gst.substring(gst.length - 3)}';
    }
    return '${gst.substring(0, 2)}*********${gst.substring(12)}';
  }

  /// Generic last-N masking for business licence and similar fields.
  static String maskedLast4(String? value, {int visibleChars = 4}) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return '-';
    if (trimmed.length <= visibleChars) return trimmed;
    return '${'*' * (trimmed.length - visibleChars)}${trimmed.substring(trimmed.length - visibleChars)}';
  }

  static String _digitsOnly(String? value) =>
      (value ?? '').replaceAll(RegExp(r'\D'), '');
}
