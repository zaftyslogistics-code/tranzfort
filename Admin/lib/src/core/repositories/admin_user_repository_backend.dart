part of 'admin_user_repository.dart';

class SupabaseAdminUserBackend implements AdminUserBackend {
  final SupabaseClient? client;

  const SupabaseAdminUserBackend(this.client);

  @override
  Future<List<Map<String, dynamic>>> fetchProfiles() async {
    final activeClient = client;
    if (activeClient == null) {
      debugPrint('[AdminUserBackend] fetchProfiles: client is null');
      return const [];
    }

    try {
      debugPrint('[AdminUserBackend] fetchProfiles: querying profiles...');
      final rows = await activeClient
          .from('profiles')
          .select('id, full_name, mobile, email, user_role_type, verification_status, is_banned, ban_reason, created_at, last_login_at')
          .order('created_at', ascending: false);
      debugPrint('[AdminUserBackend] fetchProfiles: returned ${rows.length} rows');
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (error, stackTrace) {
      debugPrint('[AdminUserBackend] fetchProfiles ERROR: $error');
      debugPrint('[AdminUserBackend] fetchProfiles STACK: $stackTrace');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchLatestVerificationCase({
    required String userId,
    required String subjectType,
  }) async {
    final activeClient = client;
    if (activeClient == null) {
      return null;
    }

    try {
      final row = await activeClient
          .from('verification_cases')
          .select('id, case_status, current_decision_summary, current_review_feedback_json, last_reviewed_at')
          .eq('subject_id', userId)
          .eq('subject_type', subjectType)
          .order('submitted_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) {
        return null;
      }
      return Map<String, dynamic>.from(row);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<Map<String, Map<String, dynamic>>> fetchLatestTruckVerificationCases(List<String> truckIds) async {
    final activeClient = client;
    if (activeClient == null || truckIds.isEmpty) {
      return const {};
    }

    try {
      final rows = await activeClient
          .from('verification_cases')
          .select('id, subject_id, case_status, current_decision_summary, current_review_feedback_json, last_reviewed_at, submitted_at, created_at')
          .eq('subject_type', 'truck')
          .inFilter('subject_id', truckIds)
          .order('submitted_at', ascending: false);
      final latestByTruckId = <String, Map<String, dynamic>>{};
      for (final row in rows.whereType<Map<String, dynamic>>()) {
        final subjectId = (row['subject_id'] ?? '').toString();
        if (subjectId.isEmpty || latestByTruckId.containsKey(subjectId)) {
          continue;
        }
        latestByTruckId[subjectId] = Map<String, dynamic>.from(row);
      }
      return latestByTruckId;
    } catch (error, stackTrace) {
      debugPrint('fetchLatestTruckVerificationCases failed: $error\n$stackTrace');
      return const {};
    }
  }

  @override
  Future<String?> createVerificationDocumentSignedUrl(String path) async {
    final activeClient = client;
    final normalizedPath = path.trim();
    if (activeClient == null || normalizedPath.isEmpty) {
      return null;
    }

    try {
      final bucket = normalizedPath.contains('/rc/') ? 'truck-documents' : 'verification-documents';
      return await activeClient.storage.from(bucket).createSignedUrl(normalizedPath, 3600);
    } catch (error, stackTrace) {
      debugPrint('createVerificationDocumentSignedUrl failed for $normalizedPath: $error\n$stackTrace');
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTruckerFleet(String userId) async {
    final activeClient = client;
    if (activeClient == null) {
      return const [];
    }
    try {
      final rows = await activeClient
          .from('trucks')
          .select('id, truck_model_id, truck_number, body_type, tyres, capacity_tonnes, status, rejection_reason, verification_feedback_json, verified_at, truck_models(make, model)')
          .eq('owner_id', userId)
          .order('created_at', ascending: false);
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUserAuditEntries(String userId) async {
    final activeClient = client;
    if (activeClient == null) {
      return const [];
    }

    try {
      final rows = await activeClient
          .from('audit_logs')
          .select('id, action_type, summary_text, target_object_type, target_object_id, created_at')
          .eq('target_object_id', userId)
          .order('created_at', ascending: false)
          .limit(10);
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (_) {
      try {
        final legacyRows = await activeClient
            .from('audit_logs')
            .select('id, action, entity_type, entity_id, metadata, created_at')
            .eq('entity_id', userId)
            .order('created_at', ascending: false)
            .limit(10);
        return legacyRows.map<Map<String, dynamic>>((row) {
          final resolvedRow = Map<String, dynamic>.from(row);
          final metadata = resolvedRow['metadata'];
          final metadataMap = metadata is Map<String, dynamic> ? metadata : <String, dynamic>{};
          return <String, dynamic>{
            'id': resolvedRow['id'],
            'action_type': resolvedRow['action'],
            'summary_text': (metadataMap['summary_text'] ?? metadataMap['summary'] ?? resolvedRow['action'] ?? '').toString(),
            'target_object_type': (resolvedRow['entity_type'] ?? '').toString(),
            'target_object_id': (resolvedRow['entity_id'] ?? '').toString(),
            'created_at': resolvedRow['created_at'],
          };
        }).toList(growable: false);
      } catch (error, stackTrace) {
        Error.throwWithStackTrace(error, stackTrace);
      }
    }
  }

  @override
  Future<bool> updateBanStatus({
    required String userId,
    required bool isBanned,
    String? reason,
  }) async {
    final activeClient = client;
    if (activeClient == null) {
      return false;
    }

    try {
      final normalizedReason = reason?.trim() ?? '';
      await activeClient.rpc(
        'update_trust_safety_status',
        params: {
          'p_profile_id': userId,
          'p_next_status': isBanned ? 'banned' : 'normal',
          'p_reason_summary': normalizedReason.isEmpty
              ? (isBanned ? 'Account banned by admin' : 'Access restored by admin')
              : normalizedReason,
          'p_internal_note': normalizedReason.isEmpty ? null : normalizedReason,
        },
      );
      return true;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<int> countSupplierLoads(String userId) async {
    final activeClient = client;
    if (activeClient == null) {
      return 0;
    }
    return _safeCount(() => activeClient.from('loads').select('id').eq('supplier_id', userId));
  }

  @override
  Future<int> countActiveSupplierLoads(String userId) async {
    final activeClient = client;
    if (activeClient == null) {
      return 0;
    }
    return _safeCount(
      () => activeClient
          .from('loads')
          .select('id')
          .eq('supplier_id', userId)
          .not('status', 'in', '(completed,cancelled)'),
    );
  }

  @override
  Future<int> countTruckerTrips(String userId) async {
    final activeClient = client;
    if (activeClient == null) {
      return 0;
    }
    return _safeCount(() => activeClient.from('trips').select('id').eq('trucker_id', userId));
  }

  @override
  Future<Map<String, dynamic>?> fetchProfileById(String userId) async {
    final activeClient = client;
    if (activeClient == null) {
      return null;
    }

    try {
      final row = await activeClient
          .from('profiles')
          .select('id, full_name, mobile, email, user_role_type, verification_status, verification_rejection_reason, verification_feedback_json, is_banned, ban_reason, created_at, last_login_at, aadhaar_front_document_path, aadhaar_back_document_path, pan_document_path, profile_photo_document_path')
          .eq('id', userId)
          .maybeSingle();
      if (row == null) {
        return null;
      }
      return Map<String, dynamic>.from(row);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierById(String userId) async {
    final activeClient = client;
    if (activeClient == null) {
      return null;
    }
    try {
      final row = await activeClient
          .from('suppliers')
          .select('company_name, gst_number, gst_certificate_document_path, business_licence_number, business_licence_document_path, verification_location_city, verification_location_state, verification_location_lat, verification_location_lng')
          .eq('id', userId)
          .maybeSingle();
      if (row == null) {
        return null;
      }
      return Map<String, dynamic>.from(row);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchTruckerById(String userId) async {
    final activeClient = client;
    if (activeClient == null) {
      return null;
    }
    try {
      final row = await activeClient
          .from('truckers')
          .select('id, dl_number, rating, total_trips, completed_trips')
          .eq('id', userId)
          .maybeSingle();
      if (row == null) {
        return null;
      }
      return Map<String, dynamic>.from(row);
    } catch (error, stackTrace) {
      debugPrint('fetchTruckerById failed for $userId: $error\n$stackTrace');
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSupplierRecentLoads(String userId) async {
    final activeClient = client;
    if (activeClient == null) {
      return const [];
    }
    try {
      final rows = await activeClient
          .from('loads')
          .select('id, origin_city, destination_city, status, created_at')
          .eq('supplier_id', userId)
          .order('created_at', ascending: false)
          .limit(10);
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTruckerRecentTrips(String userId) async {
    final activeClient = client;
    if (activeClient == null) {
      return const [];
    }
    try {
      final rows = await activeClient
          .from('trips')
          .select('id, stage, created_at')
          .eq('trucker_id', userId)
          .order('created_at', ascending: false)
          .limit(10);
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<Map<String, int>> batchCountSupplierLoads(List<String> userIds) async {
    final activeClient = client;
    if (activeClient == null || userIds.isEmpty) {
      return const {};
    }
    try {
      final rows = await activeClient
          .from('loads')
          .select('supplier_id')
          .inFilter('supplier_id', userIds);
      final counts = <String, int>{};
      for (final row in rows) {
        final id = (row['supplier_id'] ?? '').toString();
        if (id.isNotEmpty) {
          counts[id] = (counts[id] ?? 0) + 1;
        }
      }
      return counts;
    } catch (_) {
      return const {};
    }
  }

  @override
  Future<Map<String, int>> batchCountTruckerTrips(List<String> userIds) async {
    final activeClient = client;
    if (activeClient == null || userIds.isEmpty) {
      return const {};
    }
    try {
      final rows = await activeClient
          .from('trips')
          .select('trucker_id')
          .inFilter('trucker_id', userIds);
      final counts = <String, int>{};
      for (final row in rows) {
        final id = (row['trucker_id'] ?? '').toString();
        if (id.isNotEmpty) {
          counts[id] = (counts[id] ?? 0) + 1;
        }
      }
      return counts;
    } catch (_) {
      return const {};
    }
  }

  Future<int> _safeCount(Future<List<dynamic>> Function() query) async {
    try {
      final rows = await query();
      return rows.length;
    } catch (_) {
      return 0;
    }
  }
}
