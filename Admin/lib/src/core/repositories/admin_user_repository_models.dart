part of 'admin_user_repository.dart';

enum AdminUserFilter { all, supplier, trucker, banned }

class AdminUserListQuery {
  final AdminUserFilter filter;
  final String search;
  final int page;
  final int pageSize;

  const AdminUserListQuery({
    required this.filter,
    required this.search,
    this.page = 0,
    this.pageSize = 50,
  });

  AdminUserListQuery copyWith({
    AdminUserFilter? filter,
    String? search,
    int? page,
    int? pageSize,
  }) {
    return AdminUserListQuery(
      filter: filter ?? this.filter,
      search: search ?? this.search,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AdminUserListQuery &&
        other.filter == filter &&
        other.search == search &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(filter, search, page, pageSize);
}

class AdminUserListItem {
  final String id;
  final String fullName;
  final String mobile;
  final String email;
  final String role;
  final String verificationStatus;
  final bool isBanned;
  final String banReason;
  final int activityCount;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const AdminUserListItem({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.role,
    required this.verificationStatus,
    required this.isBanned,
    required this.banReason,
    required this.activityCount,
    required this.createdAt,
    required this.lastLoginAt,
  });
}

class VerificationDocument {
  final String label;
  final String path;
  final String signedUrl;

  const VerificationDocument({
    required this.label,
    required this.path,
    this.signedUrl = '',
  });
}

class AdminRecentItem {
  final String id;
  final String title;
  final String status;
  final DateTime? createdAt;

  const AdminRecentItem({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
  });
}

class AdminAuditEntry {
  final String id;
  final String actionType;
  final String summary;
  final String targetObjectType;
  final String targetObjectId;
  final DateTime? createdAt;

  const AdminAuditEntry({
    required this.id,
    required this.actionType,
    required this.summary,
    required this.targetObjectType,
    required this.targetObjectId,
    required this.createdAt,
  });
}

class AdminFleetTruck {
  final String id;
  final String truckNumber;
  final String bodyType;
  final int tyres;
  final String capacityTonnes;
  final String status;
  final String verificationCaseId;
  final String verificationCaseStatus;
  final String rejectionReason;
  final String feedbackSummary;
  final String feedbackNextStep;
  final String modelLabel;
  final DateTime? verifiedAt;

  const AdminFleetTruck({
    required this.id,
    required this.truckNumber,
    required this.bodyType,
    required this.tyres,
    required this.capacityTonnes,
    required this.status,
    this.verificationCaseId = '',
    this.verificationCaseStatus = '',
    required this.rejectionReason,
    this.feedbackSummary = '',
    this.feedbackNextStep = '',
    required this.modelLabel,
    required this.verifiedAt,
  });
}

class AdminVerificationCaseSummary {
  final String id;
  final String status;
  final String decisionSummary;
  final String reviewFeedbackSummary;
  final String reviewFeedbackNextStep;
  final DateTime? lastReviewedAt;

  const AdminVerificationCaseSummary({
    required this.id,
    required this.status,
    this.decisionSummary = '',
    this.reviewFeedbackSummary = '',
    this.reviewFeedbackNextStep = '',
    required this.lastReviewedAt,
  });
}

class AdminUserDetail {
  final AdminUserListItem profile;
  final Map<String, String> roleMetadata;
  final Map<String, String> stats;
  final String verificationRejectionReason;
  final String verificationFeedbackSummary;
  final String verificationFeedbackNextStep;
  final AdminVerificationCaseSummary? latestVerificationCase;
  final List<VerificationDocument> documents;
  final List<AdminRecentItem> recentItems;
  final List<AdminAuditEntry> auditEntries;
  final List<AdminFleetTruck> fleetTrucks;

  const AdminUserDetail({
    required this.profile,
    required this.roleMetadata,
    this.stats = const {},
    this.verificationRejectionReason = '',
    this.verificationFeedbackSummary = '',
    this.verificationFeedbackNextStep = '',
    this.latestVerificationCase,
    required this.documents,
    required this.recentItems,
    this.auditEntries = const [],
    this.fleetTrucks = const [],
  });
}

class AdminUserListPage {
  final List<AdminUserListItem> items;
  final bool hasMore;

  const AdminUserListPage({
    required this.items,
    required this.hasMore,
  });
}

abstract class AdminUserBackend {
  Future<List<Map<String, dynamic>>> fetchProfiles();

  Future<int> countSupplierLoads(String userId);

  Future<int> countActiveSupplierLoads(String userId);

  Future<int> countTruckerTrips(String userId);

  Future<Map<String, dynamic>?> fetchProfileById(String userId);

  Future<Map<String, dynamic>?> fetchSupplierById(String userId);

  Future<Map<String, dynamic>?> fetchTruckerById(String userId);

  Future<List<Map<String, dynamic>>> fetchTruckerFleet(String userId);

  Future<List<Map<String, dynamic>>> fetchSupplierRecentLoads(String userId);

  Future<List<Map<String, dynamic>>> fetchTruckerRecentTrips(String userId);

  Future<List<Map<String, dynamic>>> fetchUserAuditEntries(String userId);

  Future<Map<String, dynamic>?> fetchLatestVerificationCase({
    required String userId,
    required String subjectType,
  });

  Future<Map<String, Map<String, dynamic>>> fetchLatestTruckVerificationCases(List<String> truckIds);

  Future<String?> createVerificationDocumentSignedUrl(String path);

  Future<bool> updateBanStatus({
    required String userId,
    required bool isBanned,
    String? reason,
  });

  Future<Map<String, int>> batchCountSupplierLoads(List<String> userIds);

  Future<Map<String, int>> batchCountTruckerTrips(List<String> userIds);
}
