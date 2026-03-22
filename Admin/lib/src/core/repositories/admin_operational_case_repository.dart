import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/admin_app_state_providers.dart';

part 'admin_operational_case_repository_models.dart';
part 'admin_operational_case_repository_backend.dart';

class AdminOperationalCaseRepository {
  final AdminOperationalCaseBackend backend;

  const AdminOperationalCaseRepository({required this.backend});

  Future<AdminOperationalCasePage> getOperationalCases(OperationalCaseQuery query) async {
    final rows = await backend.fetchOperationalCases();
    final counts = OperationalCaseCounts(
      queued: rows.where((row) => _asString(row['status']) == 'queued').length,
      claimed: rows.where((row) => _asString(row['status']) == 'claimed').length,
      inReview: rows.where((row) => _asString(row['status']) == 'in_review').length,
      waiting: rows.where((row) => const {'waiting_for_user', 'waiting_for_external'}.contains(_asString(row['status']))).length,
      escalated: rows.where((row) => _asString(row['status']) == 'escalated').length,
      closed: rows.where((row) => const {'resolved', 'rejected', 'closed'}.contains(_asString(row['status']))).length,
    );

    final tripIds = rows
        .where((row) => _asString(row['primary_object_type']) == 'trip')
        .map((row) => _asString(row['primary_object_id']))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final tripRows = await backend.fetchTripsByIds(tripIds);
    final tripById = {for (final row in tripRows) _asString(row['id']): row};
    final loadIds = tripRows.map((row) => _asString(row['load_id'])).where((id) => id.isNotEmpty).toSet().toList(growable: false);
    final loadRows = await backend.fetchLoadsByIds(loadIds);
    final loadById = {for (final row in loadRows) _asString(row['id']): row};
    final adminIds = rows
        .expand((row) => [_asString(row['claimed_by_admin_user_id']), _asString(row['escalated_to_admin_user_id'])])
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final adminRows = await backend.fetchAdminUsersByIds(adminIds);
    final adminById = {for (final row in adminRows) _asString(row['id']): row};

    final items = rows
        .map((row) => _mapItem(row, tripById: tripById, loadById: loadById, adminById: adminById))
        .where((item) => _matchesFilter(item, query.statusFilter))
        .where((item) => _matchesSearch(item, query.search))
        .toList(growable: false)
      ..sort((a, b) => (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));

    final total = items.length;
    final start = query.page * query.pageSize;
    if (start >= total) {
      return AdminOperationalCasePage(items: const [], hasMore: false, counts: counts);
    }
    final end = (start + query.pageSize) > total ? total : start + query.pageSize;
    return AdminOperationalCasePage(
      items: items.sublist(start, end),
      hasMore: end < total,
      counts: counts,
    );
  }

  Future<bool> claimCase(String caseId) => backend.claimOperationalCase(caseId);

  Future<bool> releaseCase(String caseId) => backend.releaseOperationalCase(caseId);

  Future<AdminOperationalCaseDetail?> getOperationalCaseDetail(String caseId) async {
    final row = await backend.fetchOperationalCaseById(caseId);
    if (row == null) {
      return null;
    }
    final item = await _mapDetailItem(row);
    final events = (await backend.fetchOperationalCaseEvents(caseId))
        .map(
          (event) => AdminOperationalCaseEvent(
            id: _asString(event['id']),
            eventType: _asString(event['event_type']),
            summary: _asString(event['event_summary']),
            internalNote: _asString(event['internal_note']),
            createdAt: DateTime.tryParse(_asString(event['created_at'])),
          ),
        )
        .toList(growable: false);
    return AdminOperationalCaseDetail(
      item: item,
      contextMetadata: {
        'Case type': _titleCaseWords(item.caseType),
        'Status': _titleCaseWords(item.status),
        'Queue': _titleCaseWords(item.queueClassification),
        'Claimed by': item.claimedByLabel.isEmpty ? '-' : item.claimedByLabel,
        'Escalated to': item.escalatedToLabel.isEmpty ? '-' : item.escalatedToLabel,
        'Waiting reason': item.waitingReason.isEmpty ? '-' : item.waitingReason,
        'Resolution': item.resolutionSummary.isEmpty ? '-' : item.resolutionSummary,
        'Business object': item.businessLabel,
      },
      linkedObjectMetadata: await _buildLinkedObjectMetadata(row),
      events: events,
    );
  }

  Future<bool> transitionCase({
    required String caseId,
    required OperationalCaseTransitionTarget target,
    String? summary,
    String? internalNote,
  }) {
    return backend.transitionOperationalCase(
      caseId: caseId,
      target: target,
      summary: summary,
      internalNote: internalNote,
    );
  }

  Future<bool> resolveCase({
    required String caseId,
    required OperationalCaseResolutionTarget target,
    required String summary,
  }) {
    return backend.resolveOperationalCase(
      caseId: caseId,
      target: target,
      summary: summary,
    );
  }

  Future<List<AdminOperationalEscalationTarget>> getEscalationTargets() async {
    final rows = await backend.fetchActiveSuperAdmins();
    return rows
        .map(
          (row) => AdminOperationalEscalationTarget(
            id: _asString(row['id']),
            name: _asString(row['full_name']).isEmpty ? 'Super Admin' : _asString(row['full_name']),
            role: _asString(row['role']),
          ),
        )
        .toList(growable: false);
  }

  Future<bool> escalateCase({
    required String caseId,
    required String targetAdminUserId,
    String? reason,
  }) {
    return backend.escalateOperationalCase(
      caseId: caseId,
      targetAdminUserId: targetAdminUserId,
      reason: reason,
    );
  }

  AdminOperationalCaseItem _mapItem(
    Map<String, dynamic> row, {
    required Map<String, Map<String, dynamic>> tripById,
    required Map<String, Map<String, dynamic>> loadById,
    required Map<String, Map<String, dynamic>> adminById,
  }) {
    final primaryObjectId = _asString(row['primary_object_id']);
    final trip = tripById[primaryObjectId];
    final load = loadById[_asString(trip?['load_id'])];
    final claimedAdmin = adminById[_asString(row['claimed_by_admin_user_id'])];
    final escalatedAdmin = adminById[_asString(row['escalated_to_admin_user_id'])];
    final businessLabel = trip == null
        ? '${_titleCaseWords(_asString(row['primary_object_type']))} $primaryObjectId'
        : [
            'Trip $primaryObjectId',
            if (_asString(load?['origin_city']).isNotEmpty || _asString(load?['destination_city']).isNotEmpty)
              '${_asString(load?['origin_city'])} → ${_asString(load?['destination_city'])}',
            if (_loadMaterial(load).isNotEmpty) _loadMaterial(load),
          ].join(' • ');

    return AdminOperationalCaseItem(
      id: _asString(row['id']),
      caseType: _asString(row['case_type']),
      primaryObjectType: _asString(row['primary_object_type']),
      primaryObjectId: primaryObjectId,
      queueClassification: _asString(row['queue_classification']),
      status: _asString(row['status']),
      claimedByAdminUserId: _asString(row['claimed_by_admin_user_id']),
      claimedByLabel: _asString(claimedAdmin?['full_name']),
      escalatedToAdminUserId: _asString(row['escalated_to_admin_user_id']),
      escalatedToLabel: _asString(escalatedAdmin?['full_name']),
      businessLabel: businessLabel,
      waitingReason: _asString(row['waiting_reason']),
      resolutionSummary: _asString(row['resolution_summary']),
      createdAt: DateTime.tryParse(_asString(row['created_at'])),
      updatedAt: DateTime.tryParse(_asString(row['updated_at'])),
      resolvedAt: DateTime.tryParse(_asString(row['resolved_at'])),
    );
  }

  Future<AdminOperationalCaseItem> _mapDetailItem(Map<String, dynamic> row) async {
    final primaryObjectId = _asString(row['primary_object_id']);
    final trip = _asString(row['primary_object_type']) == 'trip' ? await backend.fetchTripById(primaryObjectId) : null;
    final load = trip == null ? null : await backend.fetchLoadById(_asString(trip['load_id']));
    final claimedAdmin = _asString(row['claimed_by_admin_user_id']).isEmpty
        ? null
        : await backend.fetchAdminUserById(_asString(row['claimed_by_admin_user_id']));
    final escalatedAdmin = _asString(row['escalated_to_admin_user_id']).isEmpty
        ? null
        : await backend.fetchAdminUserById(_asString(row['escalated_to_admin_user_id']));
    final businessLabel = trip == null
        ? '${_titleCaseWords(_asString(row['primary_object_type']))} $primaryObjectId'
        : [
            'Trip $primaryObjectId',
            if (_asString(load?['origin_city']).isNotEmpty || _asString(load?['destination_city']).isNotEmpty)
              '${_asString(load?['origin_city'])} → ${_asString(load?['destination_city'])}',
            if (_loadMaterial(load).isNotEmpty) _loadMaterial(load),
            if (_asString(trip['stage']).isNotEmpty) 'Stage ${_titleCaseWords(_asString(trip['stage']))}',
          ].join(' • ');

    return AdminOperationalCaseItem(
      id: _asString(row['id']),
      caseType: _asString(row['case_type']),
      primaryObjectType: _asString(row['primary_object_type']),
      primaryObjectId: primaryObjectId,
      queueClassification: _asString(row['queue_classification']),
      status: _asString(row['status']),
      claimedByAdminUserId: _asString(row['claimed_by_admin_user_id']),
      claimedByLabel: _asString(claimedAdmin?['full_name']),
      escalatedToAdminUserId: _asString(row['escalated_to_admin_user_id']),
      escalatedToLabel: _asString(escalatedAdmin?['full_name']),
      businessLabel: businessLabel,
      waitingReason: _asString(row['waiting_reason']),
      resolutionSummary: _asString(row['resolution_summary']),
      createdAt: DateTime.tryParse(_asString(row['created_at'])),
      updatedAt: DateTime.tryParse(_asString(row['updated_at'])),
      resolvedAt: DateTime.tryParse(_asString(row['resolved_at'])),
    );
  }

  Future<Map<String, String>> _buildLinkedObjectMetadata(Map<String, dynamic> row) async {
    final primaryObjectType = _asString(row['primary_object_type']);
    final primaryObjectId = _asString(row['primary_object_id']);

    Map<String, dynamic>? trip;
    Map<String, dynamic>? load;

    if (primaryObjectType == 'trip' && primaryObjectId.isNotEmpty) {
      trip = await backend.fetchTripById(primaryObjectId);
      final loadId = _asString(trip?['load_id']);
      if (loadId.isNotEmpty) {
        load = await backend.fetchLoadById(loadId);
      }
    } else if (primaryObjectType == 'load' && primaryObjectId.isNotEmpty) {
      load = await backend.fetchLoadById(primaryObjectId);
    }

    final profileIds = [
      _asString(trip?['supplier_id']),
      _asString(trip?['trucker_id']),
      _asString(load?['supplier_id']),
      _asString(load?['assigned_trucker_id']),
    ].where((id) => id.isNotEmpty).toSet().toList(growable: false);
    final profileRows = await backend.fetchProfilesByIds(profileIds);
    final profileById = {for (final profile in profileRows) _asString(profile['id']): profile};
    final supplierId = _asString(trip?['supplier_id']).isNotEmpty ? _asString(trip?['supplier_id']) : _asString(load?['supplier_id']);
    final truckerId = _asString(trip?['trucker_id']);
    final assignedTruckerId = _asString(load?['assigned_trucker_id']);

    return {
      'Primary object': primaryObjectType.isEmpty ? '-' : '${_titleCaseWords(primaryObjectType)} $primaryObjectId',
      if (trip != null) 'Trip id': _asString(trip['id']),
      if (trip != null) 'Trip stage': _titleCaseWords(_asString(trip['stage'])),
      if (load != null) 'Load id': _asString(load['id']),
      if (load != null) 'Load status': _titleCaseWords(_asString(load['status'])),
      if (load != null) 'Route': '${_asString(load['origin_city'])} → ${_asString(load['destination_city'])}',
      if (load != null && _loadMaterial(load).isNotEmpty) 'Material': _loadMaterial(load),
      if (supplierId.isNotEmpty) 'Supplier id': supplierId,
      if (supplierId.isNotEmpty) 'Supplier': _profileLabel(supplierId, profileById),
      if (truckerId.isNotEmpty) 'Trucker id': truckerId,
      if (truckerId.isNotEmpty) 'Trucker': _profileLabel(truckerId, profileById),
      if (assignedTruckerId.isNotEmpty) 'Assigned trucker id': assignedTruckerId,
      if (assignedTruckerId.isNotEmpty) 'Assigned trucker': _profileLabel(assignedTruckerId, profileById),
    };
  }
}

bool _matchesFilter(AdminOperationalCaseItem item, OperationalCaseStatusFilter filter) {
  return switch (filter) {
    OperationalCaseStatusFilter.all => true,
    OperationalCaseStatusFilter.queued => item.status == 'queued',
    OperationalCaseStatusFilter.claimed => item.status == 'claimed',
    OperationalCaseStatusFilter.inReview => item.status == 'in_review',
    OperationalCaseStatusFilter.waiting => const {'waiting_for_user', 'waiting_for_external'}.contains(item.status),
    OperationalCaseStatusFilter.escalated => item.status == 'escalated',
    OperationalCaseStatusFilter.closed => const {'resolved', 'rejected', 'closed'}.contains(item.status),
  };
}

bool _matchesSearch(AdminOperationalCaseItem item, String search) {
  final normalized = search.trim().toLowerCase();
  if (normalized.isEmpty) {
    return true;
  }
  return item.id.toLowerCase().contains(normalized) ||
      item.caseType.toLowerCase().contains(normalized) ||
      item.businessLabel.toLowerCase().contains(normalized) ||
      item.queueClassification.toLowerCase().contains(normalized) ||
      item.status.toLowerCase().contains(normalized) ||
      item.waitingReason.toLowerCase().contains(normalized) ||
      item.resolutionSummary.toLowerCase().contains(normalized) ||
      item.claimedByLabel.toLowerCase().contains(normalized) ||
      item.claimedByAdminUserId.toLowerCase().contains(normalized) ||
      item.escalatedToLabel.toLowerCase().contains(normalized) ||
      item.escalatedToAdminUserId.toLowerCase().contains(normalized);
}

String _titleCaseWords(String value) {
  final normalized = value.trim().replaceAll('_', ' ');
  if (normalized.isEmpty) {
    return '-';
  }
  return normalized
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _asString(dynamic value) => (value ?? '').toString();

String _loadMaterial(Map<String, dynamic>? load) {
  return _asString(load?['material']).isNotEmpty ? _asString(load?['material']) : _asString(load?['material_type']);
}

String _profileLabel(String id, Map<String, Map<String, dynamic>> profileById) {
  final name = _asString(profileById[id]?['full_name']);
  return name.isEmpty ? id : '$name ($id)';
}

final adminOperationalCaseBackendProvider = Provider<AdminOperationalCaseBackend>((ref) {
  return SupabaseAdminOperationalCaseBackend(ref.watch(adminSupabaseClientProvider));
});

final adminOperationalCaseRepositoryProvider = Provider<AdminOperationalCaseRepository>((ref) {
  return AdminOperationalCaseRepository(backend: ref.watch(adminOperationalCaseBackendProvider));
});
