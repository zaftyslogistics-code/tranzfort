/* Map reader helpers for safely extracting typed values from JSON maps.
   Used by repository layer to deserialize Supabase responses. */

/// Reads a nullable string from a map value.
String? nullableString(Object? value) {
  final raw = (value ?? '').toString().trim();
  return raw.isEmpty ? null : raw;
}

/// Reads a double from a map value.
double readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse((value ?? '0').toString()) ?? 0;
}

/// Reads an int from a map value.
int readInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse((value ?? '0').toString()) ?? 0;
}

/// Reads a DateTime from a map value.
DateTime? readDate(Object? value) {
  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw);
}

/// Reads a nullable double from a map value.
/// Returns null if value is null, otherwise parses to double.
/// Use this for coordinates to distinguish between null and 0.0.
double? readDoubleNullable(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}
