import 'package:flutter/foundation.dart';

/// Utility for redacting PII (Personally Identifiable Information) from log messages.
/// Used in release builds to ensure sensitive data is never logged.
class PiiRedaction {
  PiiRedaction._();

  /// Redact PII from a log message.
  /// In debug mode, returns the original message unchanged.
  /// In release mode, redacts sensitive data.
  static String redact(String message) {
    if (kDebugMode) {
      return message;
    }

    String redacted = message;

    // Redact UUIDs/GUIDs (common pattern: 8-4-4-4-12 hex digits)
    redacted = redacted.replaceAllMapped(
      RegExp(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'),
      (match) => '[REDACTED_ID]',
    );

    // Redact Supabase IDs (typically UUID-like)
    redacted = redacted.replaceAllMapped(
      RegExp(r'[a-f0-9]{32}'),
      (match) => '[REDACTED_ID]',
    );

    // Redact email addresses
    redacted = redacted.replaceAllMapped(
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
      (match) => '[REDACTED_EMAIL]',
    );

    // Redact Indian phone numbers (10 digits, optionally with +91 or 0 prefix)
    redacted = redacted.replaceAllMapped(
      RegExp(r'(\+91|0)?[6-9]\d{9}'),
      (match) => '[REDACTED_PHONE]',
    );

    // Redact API keys (common patterns)
    redacted = redacted.replaceAllMapped(
      RegExp(r'AIza[A-Za-z0-9_-]{35}'), // Google API keys
      (match) => '[REDACTED_API_KEY]',
    );

    redacted = redacted.replaceAllMapped(
      RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'), // JWT tokens
      (match) => '[REDACTED_TOKEN]',
    );

    // Redact bearer tokens
    redacted = redacted.replaceAllMapped(
      RegExp(r'Bearer\s+[A-Za-z0-9_.-]+', caseSensitive: false),
      (match) => 'Bearer [REDACTED_TOKEN]',
    );

    // Redact numeric IDs (common for user IDs, load IDs, etc.)
    // Only redact if they look like database IDs (typically 10+ digits)
    redacted = redacted.replaceAllMapped(
      RegExp(r'\b\d{10,}\b'),
      (match) => '[REDACTED_ID]',
    );

    return redacted;
  }

  /// Redact a specific value (useful for structured logging)
  static String redactValue(String value) {
    if (kDebugMode) {
      return value;
    }

    // If value looks like an ID, email, or phone, redact it
    if (value.length >= 32 && value.contains('-')) {
      // Likely a UUID
      return '[REDACTED_ID]';
    }

    if (value.contains('@') && value.contains('.')) {
      // Likely an email
      return '[REDACTED_EMAIL]';
    }

    if (RegExp(r'^[6-9]\d{9}$').hasMatch(value) ||
        RegExp(r'^\+91[6-9]\d{9}$').hasMatch(value)) {
      // Indian phone number
      return '[REDACTED_PHONE]';
    }

    if (RegExp(r'^\d{10,}$').hasMatch(value)) {
      // Long numeric ID
      return '[REDACTED_ID]';
    }

    return value;
  }
}
