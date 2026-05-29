import 'dart:convert';

import 'type_safety.dart';

/// Normalizes Supabase RPC rows returned as JSONB (List, encoded String, or nested).
List<Map<String, dynamic>> parseRpcJsonbRowList(dynamic response) {
  if (response is List) {
    return response.map(safeMap).whereType<Map<String, dynamic>>().toList(growable: false);
  }

  if (response is String) {
    final trimmed = response.trim();
    if (trimmed.isEmpty) {
      return const <Map<String, dynamic>>[];
    }
    try {
      return parseRpcJsonbRowList(jsonDecode(trimmed));
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  if (response is Map) {
    final rows = safeMap(response)?['data'] ?? safeMap(response)?['rows'];
    if (rows != null) {
      return parseRpcJsonbRowList(rows);
    }
  }

  return const <Map<String, dynamic>>[];
}
