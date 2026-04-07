import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/admin_app_state_providers.dart';
import 'admin_verification_helpers.dart';
import 'admin_verification_repository_models.dart';
import 'admin_verification_repository_backend.dart';

export 'admin_verification_helpers.dart';
export 'admin_verification_repository_models.dart';
export 'admin_verification_repository_backend.dart';

class AdminVerificationRepository {
  final AdminVerificationBackend backend;

  const AdminVerificationRepository({required this.backend});

  Future<VerificationQueuePage> getVerificationQueue(VerificationQueueQuery query) async {
    final rows = await backend.fetchVerificationCases();
    final counts = VerificationQueueCounts(
      suppliers: rows.where((row) => asString(row['subject_type']) == 'supplier_profile').length,
      truckers: rows.where((row) => asString(row['subject_type']) == 'trucker_profile').length,
      trucks: rows.where((row) => asString(row['subject_type']) == 'truck').length,
    );

    final assignedAdminUserIds = rows
        .map((row) => asString(row['assigned_admin_user_id']))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final profileIds = rows
        .where((row) => asString(row['subject_type']) != 'truck')
        .map((row) => asString(row['subject_id']))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final truckIds = rows
        .where((row) => asString(row['subject_type']) == 'truck')
        .map((row) => asString(row['subject_id']))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final adminUsers = await _safeLookup(() => backend.fetchAdminUsersByIds(assignedAdminUserIds), 'fetchAdminUsersByIds');
    final profiles = await _safeLookup(() => backend.fetchProfilesByIds(profileIds), 'fetchProfilesByIds');
    final suppliers = await _safeLookup(() => backend.fetchSuppliersByIds(profileIds), 'fetchSuppliersByIds');
    final trucks = await _safeLookup(() => backend.fetchTrucksByIds(truckIds), 'fetchTrucksByIds');
    final truckOwnerProfileIds = trucks
        .map((truck) => asString(truck['owner_id']))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final truckOwnerProfiles = await _safeLookup(() => backend.fetchProfilesByIds(truckOwnerProfileIds), 'fetchTruckOwnerProfiles');

    final adminUserById = {for (final row in adminUsers) asString(row['id']): row};
    final profileById = {for (final row in profiles) asString(row['id']): row};
    final supplierById = {for (final row in suppliers) asString(row['id']): row};
    final truckById = {for (final row in trucks) asString(row['id']): row};
    final truckOwnerProfileById = {for (final row in truckOwnerProfiles) asString(row['id']): row};

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

    final subjectType = asString(caseRow['subject_type']);
    final reviewType = asString(caseRow['review_type']).isEmpty ? 'full_verification' : asString(caseRow['review_type']);
    final subjectId = asString(caseRow['subject_id']);
    final submittedAt = DateTime.tryParse(asString(caseRow['submitted_at']));
    final feedbackMap = asMap(caseRow['current_review_feedback_json']);
    final assignedAdminUserId = asString(caseRow['assigned_admin_user_id']);
    final assignedAdminLabel = assignedAdminUserId.isEmpty
        ? ''
        : _adminUserLabel(
            (await backend.fetchAdminUsersByIds([assignedAdminUserId])).firstWhere(
              (row) => asString(row['id']) == assignedAdminUserId,
              orElse: () => const <String, dynamic>{},
            ),
          );
    final events = (await backend.fetchVerificationCaseEvents(caseId))
        .map(
          (row) => VerificationCaseEvent(
            id: asString(row['id']),
            eventType: asString(row['event_type']),
            summary: asString(row['event_summary']).isEmpty ? asString(row['internal_note']) : asString(row['event_summary']),
            internalNote: asString(row['internal_note']),
            createdAt: DateTime.tryParse(asString(row['created_at'])),
          ),
        )
        .toList(growable: false);

    final sla = _slaState(submittedAt);
    if (subjectType == 'truck') {
      final truck = await backend.fetchTruckById(subjectId);
      final ownerProfile = await backend.fetchProfileById(asString(truck?['owner_id']));
      final truckFeedback = asMap(truck?['verification_feedback_json']);
      final docReasons = feedbackDocumentReasons(feedbackMap, fallback: truckFeedback);
      final documents = await _buildVerificationDocuments([
        DocumentSeed(label: 'RC Document', backendKey: 'rc_document', path: asString(truck?['rc_document_path'])),
      ], docReasons);
      return AdminVerificationDetail(
        caseId: asString(caseRow['id']),
        subjectId: subjectId,
        subjectType: subjectType,
        subjectTypeLabel: 'Truck',
        displayName: asString(truck?['truck_number']).isEmpty ? 'Unnamed truck' : asString(truck?['truck_number']),
        subjectLabel: 'Truck verification case',
        profileLinkId: asString(truck?['owner_id']),
        profileLinkLabel: 'Open owner profile',
        caseStatus: asString(caseRow['case_status']),
        submittedAt: submittedAt,
        lastReviewedAt: DateTime.tryParse(asString(caseRow['last_reviewed_at'])),
        decisionSummary: asString(caseRow['current_decision_summary']),
        reviewFeedbackSummary: asString(feedbackMap['summary']).isEmpty ? asString(truckFeedback['summary']) : asString(feedbackMap['summary']),
        reviewFeedbackNextStep: asString(feedbackMap['next_step']).isEmpty ? asString(truckFeedback['next_step']) : asString(feedbackMap['next_step']),
        reviewFeedbackDocumentReasons: docReasons,
        isClaimed: assignedAdminUserId.isNotEmpty,
        assignedAdminUserId: assignedAdminUserId,
        assignedAdminLabel: assignedAdminLabel,
        slaLabel: sla.label,
        subjectMetadata: {
          'Truck number': asString(truck?['truck_number']),
          'Body type': asString(truck?['body_type']),
          'Tyres': asString(truck?['tyres']),
          'Capacity tonnes': asString(truck?['capacity_tonnes']),
          'Owner profile id': asString(truck?['owner_id']),
          'Owner': asString(ownerProfile?['full_name']),
          'Owner mobile': asString(ownerProfile?['mobile']),
          'Owner verification': asString(ownerProfile?['verification_status']),
          'Owner registered': _formatDateTimeText(DateTime.tryParse(asString(ownerProfile?['created_at']))),
          'Current truck status': asString(truck?['status']),
          'Verified at': _formatDateTimeText(DateTime.tryParse(asString(truck?['verified_at']))),
          'Rejection reason': asString(truck?['rejection_reason']),
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
    final profileFeedback = asMap(profile['verification_feedback_json']);
    final profilePhotoFeedback = asMap(profile['profile_photo_feedback_json']);
    final approvedAvatarPath = asString(profile['avatar_url']);
    final pendingProfilePhotoPath = asString(profile['profile_photo_document_path']);
    final docReasons = feedbackDocumentReasons(feedbackMap, fallback: profileFeedback);
    final effectiveFeedbackReasons = reviewType == 'profile_photo_update'
        ? feedbackDocumentReasons(feedbackMap, fallback: profilePhotoFeedback)
        : docReasons;
    final documentSeeds = reviewType == 'profile_photo_update'
        ? <DocumentSeed>[
            DocumentSeed(label: 'Approved Avatar', backendKey: 'approved_avatar', path: approvedAvatarPath),
            DocumentSeed(label: 'Submitted Profile Photo', backendKey: 'profile_photo', path: pendingProfilePhotoPath),
          ]
        : <DocumentSeed>[
            DocumentSeed(label: 'Aadhaar Front', backendKey: 'aadhaar_front', path: asString(profile['aadhaar_front_document_path'])),
            DocumentSeed(label: 'Aadhaar Back', backendKey: 'aadhaar_back', path: asString(profile['aadhaar_back_document_path'])),
            DocumentSeed(label: 'PAN Card', backendKey: 'pan', path: asString(profile['pan_document_path'])),
            DocumentSeed(label: 'Profile Photo', backendKey: 'profile_photo', path: pendingProfilePhotoPath),
            DocumentSeed(label: 'Business Licence', backendKey: 'business_licence', path: asString(supplier?['business_licence_document_path'])),
            DocumentSeed(label: 'GST Certificate', backendKey: 'gst_certificate', path: asString(supplier?['gst_certificate_document_path'])),
          ];
    final documents = await _buildVerificationDocuments(documentSeeds, effectiveFeedbackReasons);

    return AdminVerificationDetail(
      caseId: asString(caseRow['id']),
      subjectId: subjectId,
      subjectType: subjectType,
      reviewType: reviewType,
      subjectTypeLabel: reviewType == 'profile_photo_update'
          ? 'Profile Photo Update'
          : (subjectType == 'supplier_profile' ? 'Supplier' : 'Trucker'),
      displayName: subjectType == 'supplier_profile' && asString(supplier?['company_name']).isNotEmpty
          ? asString(supplier?['company_name'])
          : (asString(profile['full_name']).isEmpty ? 'Unnamed profile' : asString(profile['full_name'])),
      subjectLabel: reviewType == 'profile_photo_update'
          ? 'Profile photo review case'
          : (subjectType == 'supplier_profile' ? 'Supplier profile verification case' : 'Trucker profile verification case'),
      profileLinkId: subjectId,
      profileLinkLabel: 'Open subject profile',
      caseStatus: asString(caseRow['case_status']),
      submittedAt: submittedAt,
      lastReviewedAt: DateTime.tryParse(asString(caseRow['last_reviewed_at'])),
      decisionSummary: asString(caseRow['current_decision_summary']),
      reviewFeedbackSummary: asString(feedbackMap['summary']).isEmpty
          ? asString((reviewType == 'profile_photo_update' ? profilePhotoFeedback : profileFeedback)['summary'])
          : asString(feedbackMap['summary']),
      reviewFeedbackNextStep: asString(feedbackMap['next_step']).isEmpty
          ? asString((reviewType == 'profile_photo_update' ? profilePhotoFeedback : profileFeedback)['next_step'])
          : asString(feedbackMap['next_step']),
      reviewFeedbackDocumentReasons: effectiveFeedbackReasons,
      isClaimed: assignedAdminUserId.isNotEmpty,
      assignedAdminUserId: assignedAdminUserId,
      assignedAdminLabel: assignedAdminLabel,
      slaLabel: sla.label,
      subjectMetadata: {
        'Name': asString(profile['full_name']),
        'Mobile': asString(profile['mobile']),
        'Email': asString(profile['email']),
        'Verification status': asString(profile['verification_status']),
        'Aadhaar number': asString(profile['aadhaar_number']),
        'Aadhaar last 4': asString(profile['aadhaar_last4']),
        'PAN number': asString(profile['pan_number']),
        'Registered': _formatDateTimeText(DateTime.tryParse(asString(profile['created_at']))),
        if (subjectType == 'supplier_profile') 'Company': asString(supplier?['company_name']),
        if (subjectType == 'supplier_profile') 'GST number': asString(supplier?['gst_number']),
        if (subjectType == 'supplier_profile') 'Licence number': asString(supplier?['business_licence_number']),
        if (subjectType == 'supplier_profile') 'Verification location': [
          asString(supplier?['verification_location_city']),
          asString(supplier?['verification_location_state']),
        ].where((part) => part.isNotEmpty).join(', '),
        if (subjectType == 'supplier_profile') 'Verification coordinates': _formatCoordinateLabel(
          asString(supplier?['verification_location_lat']),
          asString(supplier?['verification_location_lng']),
        ),
        if (subjectType == 'trucker_profile') 'DL number': asString(trucker?['dl_number']),
        if (subjectType == 'trucker_profile') 'Rating': asString(trucker?['rating']),
        if (subjectType == 'trucker_profile') 'Total trips': asString(trucker?['total_trips']),
        if (subjectType == 'trucker_profile') 'Completed trips': asString(trucker?['completed_trips']),
        if (reviewType == 'profile_photo_update') 'Approved avatar path': approvedAvatarPath,
        if (reviewType == 'profile_photo_update') 'Pending profile photo path': pendingProfilePhotoPath,
        if (reviewType == 'profile_photo_update') 'Photo review status': asString(profile['profile_photo_review_status']),
        if (reviewType == 'profile_photo_update') 'Photo rejection reason': asString(profile['profile_photo_rejection_reason']),
      },
      approvedAvatarPath: approvedAvatarPath,
      pendingProfilePhotoPath: pendingProfilePhotoPath,
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
    List<DocumentSeed> seeds,
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
    final subjectType = asString(row['subject_type']);
    final reviewType = asString(row['review_type']).isEmpty ? 'full_verification' : asString(row['review_type']);
    final subjectId = asString(row['subject_id']);
    final assignedAdminUserId = asString(row['assigned_admin_user_id']);
    final submittedAt = DateTime.tryParse(asString(row['submitted_at']));
    final sla = _slaState(submittedAt);

    if (subjectType == 'truck') {
      final truck = truckById[subjectId];
      final ownerProfile = truckOwnerProfileById[asString(truck?['owner_id'])];
      return VerificationQueueItem(
        caseId: asString(row['id']),
        subjectId: subjectId,
        subjectType: subjectType,
        reviewType: reviewType,
        displayName: asString(truck?['truck_number']).isEmpty ? 'Unnamed truck' : asString(truck?['truck_number']),
        secondaryLabel: asString(truck?['body_type']),
        contactLabel: [
          asString(ownerProfile?['full_name']),
          asString(ownerProfile?['mobile']),
        ].where((part) => part.isNotEmpty).join(' • '),
        profileLinkId: asString(truck?['owner_id']),
        profileLinkLabel: 'Open owner profile',
        caseStatus: asString(row['case_status']),
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
    final displayName = subjectType == 'supplier_profile' && asString(supplier?['company_name']).isNotEmpty
        ? asString(supplier?['company_name'])
        : asString(profile?['full_name']);

    return VerificationQueueItem(
      caseId: asString(row['id']),
      subjectId: subjectId,
      subjectType: subjectType,
      reviewType: reviewType,
      displayName: displayName.isEmpty ? 'Unnamed verification subject' : displayName,
      secondaryLabel: reviewType == 'profile_photo_update' ? 'Profile photo update' : asString(profile?['email']),
      contactLabel: asString(profile?['mobile']),
      profileLinkId: subjectId,
      profileLinkLabel: 'Open subject profile',
      caseStatus: asString(row['case_status']),
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
  final fullName = asString(row?['full_name']);
  final role = asString(row?['role']);
  if (fullName.isEmpty && role.isEmpty) {
    return '';
  }
  if (fullName.isEmpty) {
    return role;
  }
  return role.isEmpty ? fullName : '$fullName ($role)';
}

bool _matchesTab(Map<String, dynamic> row, VerificationQueueTab tab) {
  final subjectType = asString(row['subject_type']);
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

final adminVerificationBackendProvider = Provider<AdminVerificationBackend>((ref) {
  return SupabaseAdminVerificationBackend(ref.watch(adminSupabaseClientProvider));
});

final adminVerificationRepositoryProvider = Provider<AdminVerificationRepository>((ref) {
  return AdminVerificationRepository(
    backend: ref.watch(adminVerificationBackendProvider),
  );
});
