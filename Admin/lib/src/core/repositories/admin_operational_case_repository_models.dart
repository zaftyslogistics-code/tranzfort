part of 'admin_operational_case_repository.dart';

enum OperationalCaseStatusFilter { all, queued, claimed, inReview, waiting, escalated, closed }

class OperationalCaseQuery {
  final OperationalCaseStatusFilter statusFilter;
  final String search;
  final int page;
  final int pageSize;

  const OperationalCaseQuery({
    required this.statusFilter,
    required this.search,
    this.page = 0,
    this.pageSize = 20,
  });

  OperationalCaseQuery copyWith({
    OperationalCaseStatusFilter? statusFilter,
    String? search,
    int? page,
    int? pageSize,
  }) {
    return OperationalCaseQuery(
      statusFilter: statusFilter ?? this.statusFilter,
      search: search ?? this.search,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class OperationalCaseCounts {
  final int queued;
  final int claimed;
  final int inReview;
  final int waiting;
  final int escalated;
  final int closed;

  const OperationalCaseCounts({
    required this.queued,
    required this.claimed,
    required this.inReview,
    required this.waiting,
    required this.escalated,
    required this.closed,
  });

  factory OperationalCaseCounts.empty() {
    return const OperationalCaseCounts(queued: 0, claimed: 0, inReview: 0, waiting: 0, escalated: 0, closed: 0);
  }
}

class AdminOperationalCaseItem {
  final String id;
  final String caseType;
  final String primaryObjectType;
  final String primaryObjectId;
  final String queueClassification;
  final String status;
  final String claimedByAdminUserId;
  final String claimedByLabel;
  final String escalatedToAdminUserId;
  final String escalatedToLabel;
  final String businessLabel;
  final String waitingReason;
  final String resolutionSummary;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  const AdminOperationalCaseItem({
    required this.id,
    required this.caseType,
    required this.primaryObjectType,
    required this.primaryObjectId,
    required this.queueClassification,
    required this.status,
    required this.claimedByAdminUserId,
    required this.claimedByLabel,
    required this.escalatedToAdminUserId,
    required this.escalatedToLabel,
    required this.businessLabel,
    required this.waitingReason,
    required this.resolutionSummary,
    required this.createdAt,
    required this.updatedAt,
    required this.resolvedAt,
  });
}

class AdminOperationalCaseEvent {
  final String id;
  final String eventType;
  final String summary;
  final String internalNote;
  final DateTime? createdAt;

  const AdminOperationalCaseEvent({
    required this.id,
    required this.eventType,
    required this.summary,
    required this.internalNote,
    required this.createdAt,
  });
}

class AdminOperationalCaseDetail {
  final AdminOperationalCaseItem item;
  final Map<String, String> contextMetadata;
  final Map<String, String> linkedObjectMetadata;
  final List<AdminOperationalCaseEvent> events;

  const AdminOperationalCaseDetail({
    required this.item,
    required this.contextMetadata,
    required this.linkedObjectMetadata,
    required this.events,
  });
}

class AdminOperationalEscalationTarget {
  final String id;
  final String name;
  final String role;

  const AdminOperationalEscalationTarget({
    required this.id,
    required this.name,
    required this.role,
  });
}

enum OperationalCaseTransitionTarget { inReview, waitingForUser, waitingForExternal, closed }

enum OperationalCaseResolutionTarget { resolved, rejected }

class AdminOperationalCasePage {
  final List<AdminOperationalCaseItem> items;
  final bool hasMore;
  final OperationalCaseCounts counts;

  const AdminOperationalCasePage({
    required this.items,
    required this.hasMore,
    required this.counts,
  });
}

abstract class AdminOperationalCaseBackend {
  Future<List<Map<String, dynamic>>> fetchOperationalCases();

  Future<Map<String, dynamic>?> fetchOperationalCaseById(String caseId);

  Future<List<Map<String, dynamic>>> fetchOperationalCaseEvents(String caseId);

  Future<List<Map<String, dynamic>>> fetchProfilesByIds(List<String> ids);

  Future<List<Map<String, dynamic>>> fetchTripsByIds(List<String> ids);

  Future<Map<String, dynamic>?> fetchTripById(String id);

  Future<List<Map<String, dynamic>>> fetchLoadsByIds(List<String> ids);

  Future<Map<String, dynamic>?> fetchLoadById(String id);

  Future<List<Map<String, dynamic>>> fetchAdminUsersByIds(List<String> ids);

  Future<Map<String, dynamic>?> fetchAdminUserById(String id);

  Future<List<Map<String, dynamic>>> fetchActiveSuperAdmins();

  Future<bool> claimOperationalCase(String caseId);

  Future<bool> releaseOperationalCase(String caseId);

  Future<bool> transitionOperationalCase({
    required String caseId,
    required OperationalCaseTransitionTarget target,
    String? summary,
    String? internalNote,
  });

  Future<bool> resolveOperationalCase({
    required String caseId,
    required OperationalCaseResolutionTarget target,
    required String summary,
  });

  Future<bool> escalateOperationalCase({
    required String caseId,
    required String targetAdminUserId,
    String? reason,
  });
}
