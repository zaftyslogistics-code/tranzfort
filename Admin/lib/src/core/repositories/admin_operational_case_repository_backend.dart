part of 'admin_operational_case_repository.dart';

class SupabaseAdminOperationalCaseBackend implements AdminOperationalCaseBackend {
  final SupabaseClient? client;

  const SupabaseAdminOperationalCaseBackend(this.client);

  @override
  Future<List<Map<String, dynamic>>> fetchOperationalCases() async {
    final activeClient = client;
    if (activeClient == null) {
      return const [];
    }
    final rows = await activeClient
        .from('operational_cases')
        .select('id, case_type, primary_object_type, primary_object_id, queue_classification, status, claimed_by_admin_user_id, claimed_at, waiting_reason, escalated_to_admin_user_id, resolution_summary, created_at, updated_at, resolved_at')
        .order('updated_at', ascending: false);
    return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>?> fetchOperationalCaseById(String caseId) async {
    final activeClient = client;
    if (activeClient == null) {
      return null;
    }
    final row = await activeClient
        .from('operational_cases')
        .select('id, case_type, primary_object_type, primary_object_id, queue_classification, status, claimed_by_admin_user_id, claimed_at, waiting_reason, escalated_to_admin_user_id, resolution_summary, created_at, updated_at, resolved_at')
        .eq('id', caseId)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchActiveSuperAdmins() async {
    final activeClient = client;
    if (activeClient == null) {
      return const [];
    }
    final rows = await activeClient
        .from('admin_users')
        .select('id, full_name, role')
        .eq('role', 'super_admin')
        .eq('is_active', true)
        .order('full_name');
    return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchOperationalCaseEvents(String caseId) async {
    final activeClient = client;
    if (activeClient == null) {
      return const [];
    }
    final rows = await activeClient
        .from('operational_case_events')
        .select('id, event_type, event_summary, internal_note, created_at')
        .eq('operational_case_id', caseId)
        .order('created_at', ascending: false);
    return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchProfilesByIds(List<String> ids) async {
    final activeClient = client;
    if (activeClient == null || ids.isEmpty) {
      return const [];
    }
    final rows = await activeClient
        .from('profiles')
        .select('id, full_name')
        .inFilter('id', ids);
    return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTripsByIds(List<String> ids) async {
    final activeClient = client;
    if (activeClient == null || ids.isEmpty) {
      return const [];
    }
    final rows = await activeClient
        .from('trips')
        .select('id, load_id, supplier_id, trucker_id, stage')
        .inFilter('id', ids);
    return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>?> fetchTripById(String id) async {
    final activeClient = client;
    if (activeClient == null) {
      return null;
    }
    final row = await activeClient
        .from('trips')
        .select('id, load_id, supplier_id, trucker_id, stage')
        .eq('id', id)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchLoadsByIds(List<String> ids) async {
    final activeClient = client;
    if (activeClient == null || ids.isEmpty) {
      return const [];
    }
    final rows = await activeClient
        .from('loads')
        .select('id, origin_city, destination_city, material')
        .inFilter('id', ids);
    return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>?> fetchLoadById(String id) async {
    final activeClient = client;
    if (activeClient == null) {
      return null;
    }
    final row = await activeClient
        .from('loads')
        .select('id, origin_city, destination_city, material, supplier_id, assigned_trucker_id, status')
        .eq('id', id)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAdminUsersByIds(List<String> ids) async {
    final activeClient = client;
    if (activeClient == null || ids.isEmpty) {
      return const [];
    }
    final rows = await activeClient
        .from('admin_users')
        .select('id, full_name, role')
        .inFilter('id', ids);
    return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>?> fetchAdminUserById(String id) async {
    final activeClient = client;
    if (activeClient == null) {
      return null;
    }
    final row = await activeClient
        .from('admin_users')
        .select('id, full_name, role')
        .eq('id', id)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<bool> claimOperationalCase(String caseId) async {
    final activeClient = client;
    if (activeClient == null) {
      return false;
    }
    await activeClient.rpc('claim_operational_case', params: {'p_case_id': caseId});
    return true;
  }

  @override
  Future<bool> releaseOperationalCase(String caseId) async {
    final activeClient = client;
    if (activeClient == null) {
      return false;
    }
    await activeClient.rpc('release_operational_case', params: {'p_case_id': caseId});
    return true;
  }

  @override
  Future<bool> transitionOperationalCase({
    required String caseId,
    required OperationalCaseTransitionTarget target,
    String? summary,
    String? internalNote,
  }) async {
    final activeClient = client;
    if (activeClient == null) {
      return false;
    }
    final nextStatus = switch (target) {
      OperationalCaseTransitionTarget.inReview => 'in_review',
      OperationalCaseTransitionTarget.waitingForUser => 'waiting_for_user',
      OperationalCaseTransitionTarget.waitingForExternal => 'waiting_for_external',
      OperationalCaseTransitionTarget.closed => 'closed',
    };
    await activeClient.rpc(
      'transition_operational_case',
      params: {
        'p_case_id': caseId,
        'p_next_status': nextStatus,
        'p_event_summary': (summary ?? '').trim().isEmpty ? null : summary!.trim(),
        'p_internal_note': (internalNote ?? '').trim().isEmpty ? null : internalNote!.trim(),
      },
    );
    return true;
  }

  @override
  Future<bool> resolveOperationalCase({
    required String caseId,
    required OperationalCaseResolutionTarget target,
    required String summary,
  }) async {
    final activeClient = client;
    if (activeClient == null) {
      return false;
    }
    await activeClient.rpc(
      'resolve_operational_case',
      params: {
        'p_case_id': caseId,
        'p_resolution_summary': summary.trim(),
        'p_resolution_status': target == OperationalCaseResolutionTarget.resolved ? 'resolved' : 'rejected',
      },
    );
    return true;
  }

  @override
  Future<bool> escalateOperationalCase({
    required String caseId,
    required String targetAdminUserId,
    String? reason,
  }) async {
    final activeClient = client;
    if (activeClient == null) {
      return false;
    }
    await activeClient.rpc(
      'escalate_operational_case',
      params: {
        'p_case_id': caseId,
        'p_target_admin_user_id': targetAdminUserId,
        'p_reason': (reason ?? '').trim().isEmpty ? null : reason!.trim(),
      },
    );
    return true;
  }
}
