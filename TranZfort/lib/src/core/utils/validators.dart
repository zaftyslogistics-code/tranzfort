/// Shared validation utilities for the app.
///
/// All validation logic should be centralized here to avoid duplication
/// and ensure consistent validation rules across the app.
class Validators {
  Validators._();

  /// Email regex pattern - matches standard email format
  /// Pattern: local@domain.tld
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Validates an email address format.
  /// Returns the normalized (trimmed, lowercase) email if valid, null otherwise.
  static String? validateEmail(String raw) {
    final trimmed = raw.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return null;
    }

    if (!_emailPattern.hasMatch(trimmed)) {
      return null;
    }

    return trimmed;
  }

  /// Checks if an email format is valid without normalizing.
  static bool isValidEmail(String email) {
    return _emailPattern.hasMatch(email.trim());
  }

  /// Validates password strength.
  /// Currently checks minimum length of 8 characters.
  static bool isValidPassword(String password) {
    return password.trim().length >= 8;
  }

  /// Returns a password validation error message if invalid, null if valid.
  static String? validatePassword(String password) {
    if (password.trim().length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  /// Validates an Indian mobile number format.
  /// Accepts 10 digits, optionally with +91 prefix or 0 prefix.
  static final RegExp _mobilePattern = RegExp(r'^(\+91|0)?[6-9]\d{9}$');

  /// Checks if a mobile number format is valid.
  static bool isValidMobile(String mobile) {
    return _mobilePattern.hasMatch(mobile.trim());
  }

  /// Normalizes a mobile number to 10 digits (removes +91 or 0 prefix).
  /// Returns null if the format is invalid.
  static String? normalizeMobile(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (!_mobilePattern.hasMatch(trimmed)) {
      return null;
    }

    // Remove +91 or 0 prefix if present
    String normalized = trimmed;
    if (normalized.startsWith('+91')) {
      normalized = normalized.substring(3);
    } else if (normalized.startsWith('0')) {
      normalized = normalized.substring(1);
    }

    return normalized;
  }

  /// Validates Aadhaar number format (12 digits).
  static bool isValidAadhaar(String aadhaar) {
    return RegExp(r'^\d{12}$').hasMatch(aadhaar.trim());
  }

  /// Returns Aadhaar validation error message if invalid, null if valid.
  static String? validateAadhaar(String aadhaar) {
    if (!isValidAadhaar(aadhaar)) {
      return 'Aadhaar must be exactly 12 digits';
    }
    return null;
  }

  /// Validates PAN number format (AAAAA9999A).
  static bool isValidPan(String pan) {
    return RegExp(r'^[A-Z]{5}\d{4}[A-Z]$').hasMatch(pan.trim().toUpperCase());
  }

  /// Returns PAN validation error message if invalid, null if valid.
  static String? validatePan(String pan) {
    if (!isValidPan(pan)) {
      return 'PAN must follow the format: AAAAA9999A';
    }
    return null;
  }

  /// Validates that a string is not empty/blank.
  static bool isNotEmpty(String value) {
    return value.trim().isNotEmpty;
  }

  /// Validates minimum length of a string.
  static bool hasMinLength(String value, int minLength) {
    return value.trim().length >= minLength;
  }
}
