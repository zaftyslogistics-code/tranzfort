import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/admin_app_state_providers.dart';

part 'admin_user_repository_models.dart';
part 'admin_user_repository_backend.dart';

class AdminUserRepository {
  final AdminUserBackend backend;

  const AdminUserRepository({required this.backend});

  Future<AdminUserListPage> searchUsers(AdminUserListQuery query) async {
    final profiles = await backend.fetchProfiles();
    final searched = _applyFilterAndSearch(profiles, query);
    final total = searched.length;
    final start = query.page * query.pageSize;
    if (start >= total) {
      return const AdminUserListPage(items: [], hasMore: false);
    }
    final end = (start + query.pageSize) > total ? total : start + query.pageSize;
    final pageRows = searched.sublist(start, end);

    final supplierIds = <String>[];
    final truckerIds = <String>[];
    for (final row in pageRows) {
      final role = _asString(row['user_role_type']);
      final userId = _asString(row['id']);
      if (role == 'supplier') {
        supplierIds.add(userId);
      } else if (role == 'trucker') {
        truckerIds.add(userId);
      }
    }
    final supplierCounts = await backend.batchCountSupplierLoads(supplierIds);
    final truckerCounts = await backend.batchCountTruckerTrips(truckerIds);

    final items = pageRows.map((row) {
      final role = _asString(row['user_role_type']);
      final userId = _asString(row['id']);
      final activityCount = role == 'supplier'
          ? (supplierCounts[userId] ?? 0)
          : role == 'trucker'
              ? (truckerCounts[userId] ?? 0)
              : 0;
      return AdminUserListItem(
        id: userId,
        fullName: _asString(row['full_name']),
        mobile: _asString(row['mobile']),
        email: _asString(row['email']),
        role: role,
        verificationStatus: _asString(row['verification_status']),
        isBanned: row['is_banned'] == true,
        banReason: _asString(row['ban_reason']),
        activityCount: activityCount,
        createdAt: DateTime.tryParse(_asString(row['created_at'])),
        lastLoginAt: DateTime.tryParse(_asString(row['last_login_at'])),
      );
    }).toList(growable: false);

    return AdminUserListPage(
      items: items,
      hasMore: end < total,
    );
  }

  Future<AdminUserDetail?> getUserDetail(String userId) async {
    try {
      debugPrint('[AdminUserRepository] getUserDetail: Starting for userId: $userId');
      
      debugPrint('[AdminUserRepository] getUserDetail: Fetching profile...');
      final profile = await backend.fetchProfileById(userId);
      debugPrint('[AdminUserRepository] getUserDetail: Profile: $profile');
      if (profile == null) {
        debugPrint('[AdminUserRepository] getUserDetail: Profile is null, returning null');
        return null;
      }

    final role = _asString(profile['user_role_type']);
    final activityCount = role == 'supplier'
        ? await backend.countSupplierLoads(userId)
        : role == 'trucker'
            ? await backend.countTruckerTrips(userId)
            : 0;

    final profileItem = AdminUserListItem(
      id: _asString(profile['id']),
      fullName: _asString(profile['full_name']),
      mobile: _asString(profile['mobile']),
      email: _asString(profile['email']),
      role: role,
      verificationStatus: _asString(profile['verification_status']),
      isBanned: profile['is_banned'] == true,
      banReason: _asString(profile['ban_reason']),
      activityCount: activityCount,
      createdAt: DateTime.tryParse(_asString(profile['created_at'])),
      lastLoginAt: DateTime.tryParse(_asString(profile['last_login_at'])),
    );

    final documents = await _buildVerificationDocuments([
      _DocumentSeed(label: 'Aadhaar Front', path: _asString(profile['aadhaar_front_document_path'])),
      _DocumentSeed(label: 'Aadhaar Back', path: _asString(profile['aadhaar_back_document_path'])),
      _DocumentSeed(label: 'PAN Card', path: _asString(profile['pan_document_path'])),
      _DocumentSeed(label: 'Profile Photo', path: _asString(profile['profile_photo_document_path'])),
    ]);
    final feedbackMap = _asStringKeyedMap(profile['verification_feedback_json']);
    final verificationRejectionReason = _asString(profile['verification_rejection_reason']);
    final verificationFeedbackSummary = _asString(feedbackMap['summary']);
    final verificationFeedbackNextStep = _asString(feedbackMap['next_step']);
    final verificationCaseRow = switch (role) {
      'supplier' => await backend.fetchLatestVerificationCase(
          userId: userId,
          subjectType: 'supplier_profile',
        ),
      'trucker' => await backend.fetchLatestVerificationCase(
          userId: userId,
          subjectType: 'trucker_profile',
        ),
      _ => null,
    };
    final verificationCaseFeedbackMap = _asStringKeyedMap(verificationCaseRow?['current_review_feedback_json']);
    final latestVerificationCase = verificationCaseRow == null
        ? null
        : AdminVerificationCaseSummary(
            id: _asString(verificationCaseRow['id']),
            status: _asString(verificationCaseRow['case_status']),
            decisionSummary: _asString(verificationCaseRow['current_decision_summary']),
            reviewFeedbackSummary: _asString(verificationCaseFeedbackMap['summary']),
            reviewFeedbackNextStep: _asString(verificationCaseFeedbackMap['next_step']),
            lastReviewedAt: DateTime.tryParse(_asString(verificationCaseRow['last_reviewed_at'])),
          );

    Map<String, String> roleMetadata = {};
    Map<String, String> stats = {};
    List<AdminRecentItem> recentItems = const [];
    List<AdminFleetTruck> fleetTrucks = const [];
    final auditRows = await backend.fetchUserAuditEntries(userId);
    final auditEntries = auditRows
        .map(
          (row) => AdminAuditEntry(
            id: _asString(row['id']),
            actionType: _asString(row['action_type']),
            summary: _asString(row['summary_text']),
            targetObjectType: _asString(row['target_object_type']),
            targetObjectId: _asString(row['target_object_id']),
            createdAt: DateTime.tryParse(_asString(row['created_at'])),
          ),
        )
        .toList(growable: false);

    if (role == 'supplier') {
      final supplier = await backend.fetchSupplierById(userId);
      final activeLoads = await backend.countActiveSupplierLoads(userId);
      final verificationCity = _asString(supplier?['verification_location_city']);
      final verificationState = _asString(supplier?['verification_location_state']);
      final verificationLat = _asString(supplier?['verification_location_lat']);
      final verificationLng = _asString(supplier?['verification_location_lng']);
      roleMetadata = {
        'Company': _asString(supplier?['company_name']),
        'GST': _asString(supplier?['gst_number']),
        'Business licence': _asString(supplier?['business_licence_number']),
        'Verification location': [verificationCity, verificationState].where((part) => part.isNotEmpty).join(', '),
        'Verification coordinates': verificationLat.isEmpty || verificationLng.isEmpty ? '' : '$verificationLat, $verificationLng',
      };
      stats = {
        'Loads posted': activityCount.toString(),
        'Active loads': activeLoads.toString(),
      };
      documents.addAll(
        await _buildVerificationDocuments([
          _DocumentSeed(label: 'GST Certificate', path: _asString(supplier?['gst_certificate_document_path'])),
          _DocumentSeed(label: 'Business Licence', path: _asString(supplier?['business_licence_document_path'])),
        ]),
      );
      final rows = await backend.fetchSupplierRecentLoads(userId);
      recentItems = rows.map((row) {
        return AdminRecentItem(
          id: _asString(row['id']),
          title: '${_asString(row['origin_city'])} -> ${_asString(row['dest_city'])}',
          status: _asString(row['status']),
          createdAt: DateTime.tryParse(_asString(row['created_at'])),
        );
      }).toList(growable: false);
    } else if (role == 'trucker') {
      final trucker = await backend.fetchTruckerById(userId);
      final fleetRows = await backend.fetchTruckerFleet(userId);
      roleMetadata = {
        'DL Number': _asString(trucker?['dl_number']),
        'Rating': _asString(trucker?['rating']),
        'Completed trips': _asString(trucker?['completed_trips']),
        'Total trips': _asString(trucker?['total_trips']),
      };
      stats = {
        'Trips total': _asString(trucker?['total_trips']).isEmpty ? activityCount.toString() : _asString(trucker?['total_trips']),
        'Completed trips': _asString(trucker?['completed_trips']).isEmpty ? '0' : _asString(trucker?['completed_trips']),
        'Rating': _asString(trucker?['rating']).isEmpty ? '0' : _asString(trucker?['rating']),
        'Fleet size': fleetRows.length.toString(),
      };
      final fleetTruckIds = fleetRows.map((row) => _asString(row['id'])).where((id) => id.isNotEmpty).toList(growable: false);
      final latestTruckCases = await backend.fetchLatestTruckVerificationCases(fleetTruckIds);
      fleetTrucks = fleetRows.map((row) {
        final modelMap = row['truck_models'];
        final resolvedModelMap = modelMap is Map<String, dynamic> ? modelMap : <String, dynamic>{};
        final feedbackMap = _asStringKeyedMap(row['verification_feedback_json']);
        final make = _asString(resolvedModelMap['make']);
        final model = _asString(resolvedModelMap['model']);
        final modelLabel = [make, model].where((part) => part.isNotEmpty).join(' ');
        final truckId = _asString(row['id']);
        final latestTruckCase = latestTruckCases[truckId];
        return AdminFleetTruck(
          id: truckId,
          truckNumber: _asString(row['truck_number']),
          bodyType: _asString(row['body_type']),
          tyres: int.tryParse(_asString(row['tyres'])) ?? 0,
          capacityTonnes: _asString(row['capacity_tonnes']),
          status: _asString(row['status']),
          verificationCaseId: _asString(latestTruckCase?['id']),
          verificationCaseStatus: _asString(latestTruckCase?['case_status']),
          rejectionReason: _asString(row['rejection_reason']),
          feedbackSummary: _asString(feedbackMap['summary']),
          feedbackNextStep: _asString(feedbackMap['next_step']),
          modelLabel: modelLabel,
          verifiedAt: DateTime.tryParse(_asString(row['verified_at'])),
        );
      }).toList(growable: false);
      final rows = await backend.fetchTruckerRecentTrips(userId);
      recentItems = rows.map((row) {
        return AdminRecentItem(
          id: _asString(row['id']),
          title: 'Trip ${_trimIdentifier(_asString(row['id']))}',
          status: _asString(row['stage']),
          createdAt: DateTime.tryParse(_asString(row['created_at'])),
        );
      }).toList(growable: false);
    }

    return AdminUserDetail(
      profile: profileItem,
      roleMetadata: roleMetadata,
      stats: stats,
      verificationRejectionReason: verificationRejectionReason,
      verificationFeedbackSummary: verificationFeedbackSummary,
      verificationFeedbackNextStep: verificationFeedbackNextStep,
      latestVerificationCase: latestVerificationCase,
      documents: documents.where((doc) => doc.label.isNotEmpty && doc.path.isNotEmpty).toList(growable: false),
      recentItems: recentItems,
      auditEntries: auditEntries,
      fleetTrucks: fleetTrucks,
    );
    } catch (error, stackTrace) {
      debugPrint('[AdminUserRepository] getUserDetail ERROR: $error');
      debugPrint('[AdminUserRepository] getUserDetail STACK: $stackTrace');
      rethrow;
    }
  }

  Future<List<VerificationDocument>> _buildVerificationDocuments(List<_DocumentSeed> seeds) async {
    final documents = <VerificationDocument>[];
    for (final seed in seeds) {
      if (seed.label.isEmpty || seed.path.isEmpty) {
        continue;
      }
      final signedUrl = await backend.createVerificationDocumentSignedUrl(seed.path);
      documents.add(
        VerificationDocument(
          label: seed.label,
          path: seed.path,
          signedUrl: signedUrl ?? '',
        ),
      );
    }
    return documents;
  }

  Future<bool> setBanStatus({
    required String userId,
    required bool isBanned,
    String? reason,
  }) {
    return backend.updateBanStatus(
      userId: userId,
      isBanned: isBanned,
      reason: reason,
    );
  }

  List<Map<String, dynamic>> _applyFilterAndSearch(
    List<Map<String, dynamic>> profiles,
    AdminUserListQuery query,
  ) {
    final filtered = profiles.where((row) {
      final role = _asString(row['user_role_type']);
      final isBanned = row['is_banned'] == true;
      return switch (query.filter) {
        AdminUserFilter.all => true,
        AdminUserFilter.supplier => role == 'supplier',
        AdminUserFilter.trucker => role == 'trucker',
        AdminUserFilter.banned => isBanned,
      };
    }).toList(growable: false);

    final search = query.search.trim().toLowerCase();
    if (search.isEmpty) {
      return filtered;
    }

    return filtered.where((row) {
      return _asString(row['id']).toLowerCase().contains(search) ||
          _asString(row['full_name']).toLowerCase().contains(search) ||
          _asString(row['mobile']).toLowerCase().contains(search) ||
          _asString(row['email']).toLowerCase().contains(search) ||
          _asString(row['user_role_type']).toLowerCase().contains(search) ||
          _asString(row['verification_status']).toLowerCase().contains(search) ||
          _asString(row['ban_reason']).toLowerCase().contains(search);
    }).toList(growable: false);
  }
}

String _asString(dynamic value) => (value ?? '').toString();

Map<String, dynamic> _asStringKeyedMap(dynamic value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

String _trimIdentifier(String value) {
  if (value.length <= 8) {
    return value;
  }
  return value.substring(0, 8);
}

class _DocumentSeed {
  final String label;
  final String path;

  const _DocumentSeed({required this.label, required this.path});
}

final adminUserBackendProvider = Provider<AdminUserBackend>((ref) {
  return SupabaseAdminUserBackend(ref.watch(adminSupabaseClientProvider));
});

final adminUserRepositoryProvider = Provider<AdminUserRepository>((ref) {
  return AdminUserRepository(
    backend: ref.watch(adminUserBackendProvider),
  );
});
