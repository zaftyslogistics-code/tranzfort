/// Canonical truck body types for post-load, filters, and fleet (P1-10).
class LoadBodyTypes {
  LoadBodyTypes._();

  static const String any = 'any';
  static const String open = 'open';
  static const String container = 'container';
  static const String trailer = 'trailer';
  static const String tanker = 'tanker';
  static const String refrigerated = 'refrigerated';

  /// Shared across post-load, find-loads filters, and fleet (P1-10).
  static const List<String> selectable = [
    any,
    open,
    container,
    trailer,
    tanker,
    refrigerated,
  ];

  /// Find-loads filter chips (DB lowercase enum; excludes [any]).
  static const List<String> filterChipTypes = [
    open,
    container,
    trailer,
    tanker,
    refrigerated,
  ];

  @Deprecated('Use selectable')
  static List<String> get postLoadBodyTypes => selectable;

  /// Value stored in DB when user picks "any".
  static String? toDatabaseValue(String? uiValue) {
    final normalized = (uiValue ?? '').trim().toLowerCase();
    if (normalized.isEmpty || normalized == any) {
      return null;
    }
    return normalized;
  }

  /// UI/storage value for dropdowns; empty becomes [any].
  static String fromDatabaseValue(String? dbValue) {
    final normalized = (dbValue ?? '').trim().toLowerCase();
    return normalized.isEmpty ? any : normalized;
  }

  static bool isValid(String? value) {
    if (value == null || value.trim().isEmpty) {
      return true;
    }
    return selectable.contains(value.trim().toLowerCase());
  }
}
