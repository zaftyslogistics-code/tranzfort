import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/admin_app_state_providers.dart';

part 'admin_verification_repository_models.dart';
part 'admin_verification_repository_backend.dart';

class AdminVerificationRepository {
  final AdminVerificationBackend backend;

  const AdminVerificationRepository({required this.backend});

  Future<VerificationQueuePage> getVerificationQueue(VerificationQueueQuery query) async {
    final rows = await backend.fetchVerificationCases();
    final counts = VerificationQueueCounts(
      suppliers: rows.where((row) => _asString(row['subject_type']) == 'supplier_profile').length,
      truckers: rows.where((row) => _asString(row['subject_type']) == 'trucker_profile').length,
      trucks: rows.where((row) => _asString(row['subject_type']) == 'truck').length,
    );

    final assignedAdminUserIds = rows
        .map((row) => _asString(row['assigned_admin_user_id']))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final profileIds = rows
        .where((row) => _asString(row['subject_type']) != 'truck')
        .map((row) => _asString(row['subject_id']))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final truckIds = rows
        .where((row) => _asString(row['subject_type']) == 'truck')
        .map((row) => _asString(row['subject_id']))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final adminUsers = await _safeLookup(() => backend.fetchAdminUsersByIds(assignedAdminUserIds), 'fetchAdminUsersByIds');
    final profiles = await _safeLookup(() => backend.fetchProfilesByIds(profileIds), 'fetchProfilesByIds');
    final suppliers = await _safeLookup(() => backend.fetchSuppliersByIds(profileIds), 'fetchSuppliersByIds');
    final trucks = await _safeLookup(() => backend.fetchTrucksByIds(truckIds), 'fetchTrucksByIds');
    final truckOwnerProfileIds = trucks
        .map((truck) => _asString(truck['owner_id']))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final truckOwnerProfiles = await _safeLookup(() => backend.fetchProfilesByIds(truckOwnerProfileIds), 'fetchTruckOwnerProfiles');

    final adminUserById = {for (final row in adminUsers) _asString(row['id']): row};
    final profileById = {for (final row in profiles) _asString(row['id']): row};
    final supplierById = {for (final row in suppliers) _asString(row['id']): row};
    final truckById = {for (final row in trucks) _asString(row['id']): row};
    final truckOwnerProfileById = {for (final row in truckOwnerProfiles) _asString(row['id']): row};

    final items = rows
        .where((row) => _matchesTab(row, query.tab))
        .map(
          (row) => _mapItem(
            row,
            adminUserById: adminUserById,
            profileById: profileById,
            supplierById: supplierById,
            truckById: truckById,
            truckOwnerProfileById: truckOwnerProfileById,
          ),
        )
        .where((item) => _matchesSearch(item, query.search))
        .toList(growable: false);

    final sorted = [...items]..sort((a, b) {
        if (query.sort == VerificationQueueSort.newest) {
          return (b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0));
        }
        final urgencyCompare = b.slaPriority.compareTo(a.slaPriority);
        if (urgencyCompare != 0) {
          return urgencyCompare;
        }
        return (a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0));
      });

    final total = sorted.length;
    final start = query.page * query.pageSize;
    if (start >= total) {
      return VerificationQueuePage(items: const [], hasMore: false, counts: counts);
    }
    final end = (start + query.pageSize) > total ? total : start + query.pageSize;
    return VerificationQueuePage(
      items: sorted.sublist(start, end),
      hasMore: end < total,
      counts: counts,
    );
  }

  Future<AdminVerificationDetail?> getVerificationDetail(String caseId) async {
    final caseRow = await backend.fetchVerificationCaseById(caseId);
    if (caseRow == null) {
      return null;
    }

    final subjectType = _asString(caseRow['subject_type']);
    final subjectId = _asString(caseRow['subject_id']);
    final submittedAt = DateTime.tryParse(_asString(caseRow['submitted_at']));
    final feedbackMap = _asMap(caseRow['current_review_feedback_json']);
    final assignedAdminUserId = _asString(caseRow['assigned_admin_user_id']);
    final assignedAdminLabel = assignedAdminUserId.isEmpty
        ? ''
        : _adminUserLabel(
            (await backend.fetchAdminUsersByIds([assignedAdminUserId])).firstWhere(
              (row) => _asString(row['id']) == assignedAdminUserId,
              orElse: () => const <String, dynamic>{},
            ),
          );
    final events = (await backend.fetchVerificationCaseEvents(caseId))
        .map(
          (row) => VerificationCaseEvent(
            id: _asString(row['id']),
            eventType: _asString(row['event_type']),
            summary: _asString(row['event_summary']).isEmpty ? _asString(row['internal_note']) : _asString(row['event_summary']),
            internalNote: _asString(row['internal_note']),
            createdAt: DateTime.tryParse(_asString(row['created_at'])),
          ),
        )
        .toList(growable: false);

    final sla = _slaState(submittedAt);
    if (subjectType == 'truck') {
      final truck = await backend.fetchTruckById(subjectId);
      final ownerProfile = await backend.fetchProfileById(_asString(truck?['owner_id']));
      final truckFeedback = _asMap(truck?['verification_feedback_json']);
      final feedbackDocumentReasons = _feedbackDocumentReasons(feedbackMap, fallback: truckFeedback);
      final documents = await _buildVerificationDocuments([
        _DocumentSeed(label: 'RC Document', backendKey: 'rc_document', path: _asString(truck?['rc_document_path'])),
      ], feedbackDocumentReasons);
      return AdminVerificationDetail(
        caseId: _asString(caseRow['id']),
        subjectId: subjectId,
        subjectType: subjectType,
        subjectTypeLabel: 'Truck',
        displayName: _asString(truck?['truck_number']).isEmpty ? 'Unnamed truck' : _asString(truck?['truck_number']),
        subjectLabel: 'Truck verification case',
        profileLinkId: _asString(truck?['owner_id']),
        profileLinkLabel: 'Open owner profile',
        caseStatus: _asString(caseRow['case_status']),
        submittedAt: submittedAt,
        lastReviewedAt: DateTime.tryParse(_asString(caseRow['last_reviewed_at'])),
        decisionSummary: _asString(caseRow['current_decision_summary']),
        reviewFeedbackSummary: _asString(feedbackMap['summary']).isEmpty ? _asString(truckFeedback['summary']) : _asString(feedbackMap['summary']),
        reviewFeedbackNextStep: _asString(feedbackMap['next_step']).isEmpty ? _asString(truckFeedback['next_step']) : _asString(feedbackMap['next_step']),
        reviewFeedbackDocumentReasons: feedbackDocumentReasons,
        isClaimed: assignedAdminUserId.isNotEmpty,
        assignedAdminUserId: assignedAdminUserId,
        assignedAdminLabel: assignedAdminLabel,
        slaLabel: sla.label,
        subjectMetadata: {
          'Truck number': _asString(truck?['truck_number']),
          'Body type': _asString(truck?['body_type']),
          'Tyres': _asString(truck?['tyres']),
          'Capacity tonnes': _asString(truck?['capacity_tonnes']),
          'Owner profile id': _asString(truck?['owner_id']),
          'Owner': _asString(ownerProfile?['full_name']),
          'Owner mobile': _asString(ownerProfile?['mobile']),
          'Owner verification': _asString(ownerProfile?['verification_status']),
          'Owner registered': _formatDateTimeText(DateTime.tryParse(_asString(ownerProfile?['created_at']))),
          'Current truck status': _asString(truck?['status']),
          'Verified at': _formatDateTimeText(DateTime.tryParse(_asString(truck?['verified_at']))),
          'Rejection reason': _asString(truck?['rejection_reason']),
        },
        documents: documents,
        events: events,
      );
    }

    final profile = await backend.fetchProfileById(subjectId);
    if (profile == null) {
      return null;
    }
    final supplier = subjectType == 'supplier_profile' ? await backend.fetchSupplierById(subjectId) : null;
    final trucker = subjectType == 'trucker_profile' ? await backend.fetchTruckerById(subjectId) : null;
    final profileFeedback = _asMap(profile['verification_feedback_json']);
    final feedbackDocumentReasons = _feedbackDocumentReasons(feedbackMap, fallback: profileFeedback);
    final documents = await _buildVerificationDocuments([
      _DocumentSeed(label: 'Aadhaar Front', backendKey: 'aadhaar_front', path: _asString(profile['aadhaar_front_document_path'])),
      _DocumentSeed(label: 'Aadhaar Back', backendKey: 'aadhaar_back', path: _asString(profile['aadhaar_back_document_path'])),
      _DocumentSeed(label: 'PAN Card', backendKey: 'pan', path: _asString(profile['pan_document_path'])),
      _DocumentSeed(label: 'Profile Photo', backendKey: 'profile_photo', path: _asString(profile['profile_photo_document_path'])),
      _DocumentSeed(label: 'Business Licence', backendKey: 'business_licence', path: _asString(supplier?['business_licence_document_path'])),
      _DocumentSeed(label: 'GST Certificate', backendKey: 'gst_certificate', path: _asString(supplier?['gst_certificate_document_path'])),
    ], feedbackDocumentReasons);

    return AdminVerificationDetail(
      caseId: _asString(caseRow['id']),
      subjectId: subjectId,
      subjectType: subjectType,
      subjectTypeLabel: subjectType == 'supplier_profile' ? 'Supplier' : 'Trucker',
      displayName: subjectType == 'supplier_profile' && _asString(supplier?['company_name']).isNotEmpty
          ? _asString(supplier?['company_name'])
          : (_asString(profile['full_name']).isEmpty ? 'Unnamed profile' : _asString(profile['full_name'])),
      subjectLabel: subjectType == 'supplier_profile' ? 'Supplier profile verification case' : 'Trucker profile verification case',
      profileLinkId: subjectId,
      profileLinkLabel: 'Open subject profile',
      caseStatus: _asString(caseRow['case_status']),
      submittedAt: submittedAt,
      lastReviewedAt: DateTime.tryParse(_asString(caseRow['last_reviewed_at'])),
      decisionSummary: _asString(caseRow['current_decision_summary']),
      reviewFeedbackSummary: _asString(feedbackMap['summary']).isEmpty ? _asString(profileFeedback['summary']) : _asString(feedbackMap['summary']),
      reviewFeedbackNextStep: _asString(feedbackMap['next_step']).isEmpty ? _asString(profileFeedback['next_step']) : _asString(feedbackMap['next_step']),
      reviewFeedbackDocumentReasons: feedbackDocumentReasons,
      isClaimed: assignedAdminUserId.isNotEmpty,
      assignedAdminUserId: assignedAdminUserId,
      assignedAdminLabel: assignedAdminLabel,
      slaLabel: sla.label,
      subjectMetadata: {
        'Name': _asString(profile['full_name']),
        'Mobile': _asString(profile['mobile']),
        'Email': _asString(profile['email']),
        'Verification status': _asString(profile['verification_status']),
        'Aadhaar number': _asString(profile['aadhaar_number']),
        'Aadhaar last 4': _asString(profile['aadhaar_last4']),
        'PAN number': _asString(profile['pan_number']),
        'Registered': _formatDateTimeText(DateTime.tryParse(_asString(profile['created_at']))),
        if (subjectType == 'supplier_profile') 'Company': _asString(supplier?['company_name']),
        if (subjectType == 'supplier_profile') 'GST number': _asString(supplier?['gst_number']),
        if (subjectType == 'supplier_profile') 'Licence number': _asString(supplier?['business_licence_number']),
        if (subjectType == 'supplier_profile') 'Verification location': [
          _asString(supplier?['verification_location_city']),
          _asString(supplier?['verification_location_state']),
        ].where((part) => part.isNotEmpty).join(', '),
        if (subjectType == 'supplier_profile') 'Verification coordinates': _formatCoordinateLabel(
          _asString(supplier?['verification_location_lat']),
          _asString(supplier?['verification_location_lng']),
        ),
        if (subjectType == 'trucker_profile') 'DL number': _asString(trucker?['dl_number']),
        if (subjectType == 'trucker_profile') 'Rating': _asString(trucker?['rating']),
        if (subjectType == 'trucker_profile') 'Total trips': _asString(trucker?['total_trips']),
        if (subjectType == 'trucker_profile') 'Completed trips': _asString(trucker?['completed_trips']),
      },
      documents: documents,
      events: events,
    );
  }

  static String _formatDateTimeText(DateTime? value) {
    if (value == null) {
      return '';
    }
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }

  static String _formatCoordinateLabel(String lat, String lng) {
    final normalizedLat = lat.trim();
    final normalizedLng = lng.trim();
    if (normalizedLat.isEmpty || normalizedLng.isEmpty) {
      return '';
    }
    return '$normalizedLat, $normalizedLng';
  }

  Future<List<VerificationDocument>> _buildVerificationDocuments(
    List<_DocumentSeed> seeds,
    Map<String, String> feedbackDocumentReasons,
  ) async {
    final documents = <VerificationDocument>[];
    for (final seed in seeds) {
      if (seed.label.isEmpty || seed.backendKey.isEmpty) {
        continue;
      }
      final normalizedPath = seed.path.trim();
      final signedUrl = normalizedPath.isEmpty ? null : await backend.createVerificationDocumentSignedUrl(normalizedPath);
      documents.add(
        VerificationDocument(
          label: seed.label,
          backendKey: seed.backendKey,
          path: normalizedPath,
          signedUrl: signedUrl ?? '',
          feedbackReason: feedbackDocumentReasons[seed.backendKey] ?? '',
        ),
      );
    }
    return documents;
  }

  Future<bool> submitReviewDecision({
    required AdminVerificationDetail detail,
    required VerificationReviewDecision decision,
    String? reason,
    VerificationReviewFeedbackPayload? feedback,
  }) async {
    try {
      if (decision == VerificationReviewDecision.approve) {
        return await backend.approveVerificationCase(
          caseId: detail.caseId,
          subjectType: detail.subjectType,
          subjectId: detail.subjectId,
        );
      }
      return await backend.rejectVerificationCase(
        caseId: detail.caseId,
        subjectType: detail.subjectType,
        subjectId: detail.subjectId,
        reason: (reason ?? '').trim(),
        feedback: feedback,
      );
    } catch (error, stackTrace) {
      debugPrint('submitReviewDecision failed: $error\n$stackTrace');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> _safeLookup(
    Future<List<Map<String, dynamic>>> Function() fetch,
    String label,
  ) async {
    try {
      return await fetch();
    } catch (error, stackTrace) {
      debugPrint('AdminVerificationRepository.$label failed: $error\n$stackTrace');
      return const [];
    }
  }

  VerificationQueueItem _mapItem(
    Map<String, dynamic> row, {
    required Map<String, Map<String, dynamic>> adminUserById,
    required Map<String, Map<String, dynamic>> profileById,
    required Map<String, Map<String, dynamic>> supplierById,
    required Map<String, Map<String, dynamic>> truckById,
    required Map<String, Map<String, dynamic>> truckOwnerProfileById,
  }) {
    final subjectType = _asString(row['subject_type']);
    final subjectId = _asString(row['subject_id']);
    final assignedAdminUserId = _asString(row['assigned_admin_user_id']);
    final submittedAt = DateTime.tryParse(_asString(row['submitted_at']));
    final sla = _slaState(submittedAt);

    if (subjectType == 'truck') {
      final truck = truckById[subjectId];
      final ownerProfile = truckOwnerProfileById[_asString(truck?['owner_id'])];
      return VerificationQueueItem(
        caseId: _asString(row['id']),
        subjectId: subjectId,
        subjectType: subjectType,
        displayName: _asString(truck?['truck_number']).isEmpty ? 'Unnamed truck' : _asString(truck?['truck_number']),
        secondaryLabel: _asString(truck?['body_type']),
        contactLabel: [
          _asString(ownerProfile?['full_name']),
          _asString(ownerProfile?['mobile']),
        ].where((part) => part.isNotEmpty).join(' • '),
        profileLinkId: _asString(truck?['owner_id']),
        profileLinkLabel: 'Open owner profile',
        caseStatus: _asString(row['case_status']),
        submittedAt: submittedAt,
        slaLabel: sla.label,
        slaPriority: sla.priority,
        isClaimed: assignedAdminUserId.isNotEmpty,
        assignedAdminUserId: assignedAdminUserId,
        assignedAdminLabel: _adminUserLabel(adminUserById[assignedAdminUserId]),
      );
    }

    final profile = profileById[subjectId];
    final supplier = supplierById[subjectId];
    final displayName = subjectType == 'supplier_profile' && _asString(supplier?['company_name']).isNotEmpty
        ? _asString(supplier?['company_name'])
        : _asString(profile?['full_name']);

    return VerificationQueueItem(
      caseId: _asString(row['id']),
      subjectId: subjectId,
      subjectType: subjectType,
      displayName: displayName.isEmpty ? 'Unnamed verification subject' : displayName,
      secondaryLabel: _asString(profile?['email']),
      contactLabel: _asString(profile?['mobile']),
      profileLinkId: subjectId,
      profileLinkLabel: 'Open subject profile',
      caseStatus: _asString(row['case_status']),
      submittedAt: submittedAt,
      slaLabel: sla.label,
      slaPriority: sla.priority,
      isClaimed: assignedAdminUserId.isNotEmpty,
      assignedAdminUserId: assignedAdminUserId,
      assignedAdminLabel: _adminUserLabel(adminUserById[assignedAdminUserId]),
    );
  }
}

String _adminUserLabel(Map<String, dynamic>? row) {
  final fullName = _asString(row?['full_name']);
  final role = _asString(row?['role']);
  if (fullName.isEmpty && role.isEmpty) {
    return '';
  }
  if (fullName.isEmpty) {
    return role;
  }
  return role.isEmpty ? fullName : '$fullName ($role)';
}

bool _matchesTab(Map<String, dynamic> row, VerificationQueueTab tab) {
  final subjectType = _asString(row['subject_type']);
  return switch (tab) {
    VerificationQueueTab.suppliers => subjectType == 'supplier_profile',
    VerificationQueueTab.truckers => subjectType == 'trucker_profile',
    VerificationQueueTab.trucks => subjectType == 'truck',
  };
}

bool _matchesSearch(VerificationQueueItem item, String search) {
  final normalized = search.trim().toLowerCase();
  if (normalized.isEmpty) {
    return true;
  }
  return item.caseId.toLowerCase().contains(normalized) ||
      item.subjectId.toLowerCase().contains(normalized) ||
      item.subjectType.toLowerCase().contains(normalized) ||
      item.displayName.toLowerCase().contains(normalized) ||
      item.secondaryLabel.toLowerCase().contains(normalized) ||
      item.contactLabel.toLowerCase().contains(normalized) ||
      item.caseStatus.toLowerCase().contains(normalized) ||
      item.assignedAdminUserId.toLowerCase().contains(normalized) ||
      item.assignedAdminLabel.toLowerCase().contains(normalized);
}

({String label, int priority}) _slaState(DateTime? submittedAt) {
  if (submittedAt == null) {
    return (label: '-', priority: 0);
  }
  final diff = DateTime.now().toUtc().difference(submittedAt.toUtc());
  const totalWindow = Duration(hours: 24);
  const amberThreshold = Duration(hours: 20);
  if (diff >= totalWindow) {
    final overBy = diff - totalWindow;
    return (label: 'Breached by ${overBy.inHours}h', priority: 3);
  }
  if (diff >= amberThreshold) {
    final remaining = totalWindow - diff;
    return (label: '${remaining.inHours}h left', priority: 2);
  }
  final remaining = totalWindow - diff;
  return (label: '${remaining.inHours}h left', priority: 1);
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

String _asString(dynamic value) => (value ?? '').toString();

final adminVerificationBackendProvider = Provider<AdminVerificationBackend>((ref) {
  return SupabaseAdminVerificationBackend(ref.watch(adminSupabaseClientProvider));
});

final adminVerificationRepositoryProvider = Provider<AdminVerificationRepository>((ref) {
  return AdminVerificationRepository(
    backend: ref.watch(adminVerificationBackendProvider),
  );
});
