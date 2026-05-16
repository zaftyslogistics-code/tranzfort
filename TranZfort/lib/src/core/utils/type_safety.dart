// Safe type casting helpers that return null on type mismatch instead of throwing.

/// Generic safe cast that returns null if value is not of type T.
T? safeCast<T>(dynamic value) {
  if (value == null) return null;
  if (value is T) return value;
  return null;
}

/// Safe Map cast that handles both typed and untyped Maps.
Map<String, dynamic>? safeMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

/// Safe List cast that handles both typed and untyped Lists.
List<T>? safeList<T>(dynamic value) {
  if (value == null) return null;
  if (value is List<T>) return value;
  if (value is List) {
    try {
      return List<T>.from(value.map((e) => e as T));
    } catch (e) {
      return null;
    }
  }
  return null;
}

/// Safe String conversion that returns empty string for null values.
String safeString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}
