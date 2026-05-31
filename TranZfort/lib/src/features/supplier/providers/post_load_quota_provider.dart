import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/app_state_providers.dart';
import '../data/supplier_post_load_quota.dart';

final postLoadQuotaProvider = FutureProvider<SupplierPostLoadQuota>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return SupplierPostLoadQuota.fallback;
  }

  try {
    final response = await client.rpc('get_supplier_post_load_quota');
    Map<String, dynamic> row;
    if (response is Map<String, dynamic>) {
      row = response;
    } else if (response is Map) {
      row = Map<String, dynamic>.from(response);
    } else if (response is String) {
      final decoded = jsonDecode(response);
      if (decoded is! Map<String, dynamic>) {
        return SupplierPostLoadQuota.fallback;
      }
      row = decoded;
    } else {
      return SupplierPostLoadQuota.fallback;
    }
    return SupplierPostLoadQuota.fromMap(row);
  } catch (_) {
    return SupplierPostLoadQuota.fallback;
  }
});
