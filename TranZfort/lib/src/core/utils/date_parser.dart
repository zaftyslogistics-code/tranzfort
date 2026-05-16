import 'package:flutter/foundation.dart';

/// Safe DateTime parser that handles multiple input formats.
///
/// Supports:
/// - DateTime objects (returned as-is)
/// - Integers (milliseconds since epoch)
/// - ISO 8601 strings
/// - Millisecond strings (numeric string representation)
///
/// Returns null if parsing fails.
DateTime? safeParseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
    // Fallback: try parsing as milliseconds
    final ms = int.tryParse(value);
    if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  return null;
}
