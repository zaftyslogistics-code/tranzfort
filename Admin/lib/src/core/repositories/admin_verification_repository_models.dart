part of 'admin_verification_repository.dart';

enum VerificationQueueTab { suppliers, truckers, trucks }

Map<String, String> _feedbackDocumentReasons(Map<String, dynamic> primary, {Map<String, dynamic>? fallback}) {
  final documents = <String, String>{};
  void mergeFrom(Map<String, dynamic>? source) {
    final sourceDocuments = source == null ? null : _asMap(source['documents']);
    if (sourceDocuments == null) {
      return;
    }
    for (final entry in sourceDocuments.entries) {
      final documentMap = _asMap(entry.value);
      final reason = _asString(documentMap['reason']).trim();
      if (entry.key.trim().isEmpty || reason.isEmpty) {
        continue;
      }
      documents.putIfAbsent(entry.key.trim(), () => reason);
    }
  }

  mergeFrom(primary);
  mergeFrom(fallback);
  return Map<String, String>.unmodifiable(documents);
}

enum VerificationQueueSort { slaUrgency, newest }

class VerificationQueueQuery {
  final VerificationQueueTab tab;
  final VerificationQueueSort sort;
  final String search;
  final int page;
  final int pageSize;

  const VerificationQueueQuery({
    required this.tab,
    required this.sort,
    required this.search,
    this.page = 0,
    this.pageSize = 20,
  });

  VerificationQueueQuery copyWith({
    VerificationQueueTab? tab,
    VerificationQueueSort? sort,
    String? search,
    int? page,
    int? pageSize,
  }) {
    return VerificationQueueQuery(
      tab: tab ?? this.tab,
      sort: sort ?? this.sort,
      search: search ?? this.search,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is VerificationQueueQuery &&
        other.tab == tab &&
        other.sort == sort &&
        other.search == search &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(tab, sort, search, page, pageSize);
}

class VerificationQueueCounts {
  final int suppliers;
  final int truckers;
  final int trucks;

  const VerificationQueueCounts({
    required this.suppliers,
    required this.truckers,
    required this.trucks,
  });

  factory VerificationQueueCounts.empty() {
    return const VerificationQueueCounts(suppliers: 0, truckers: 0, trucks: 0);
  }
}

class VerificationQueueItem {
  final String caseId;
  final String subjectId;
  final String subjectType;
  final String displayName;
  final String secondaryLabel;
  final String contactLabel;
  final String profileLinkId;
  final String profileLinkLabel;
  final String caseStatus;
  final DateTime? submittedAt;
  final String slaLabel;
  final int slaPriority;
  final bool isClaimed;
  final String assignedAdminUserId;
  final String assignedAdminLabel;

  const VerificationQueueItem({
    required this.caseId,
    required this.subjectId,
    required this.subjectType,
    required this.displayName,
    required this.secondaryLabel,
    required this.contactLabel,
    this.profileLinkId = '',
    this.profileLinkLabel = '',
    required this.caseStatus,
    required this.submittedAt,
    required this.slaLabel,
    required this.slaPriority,
    required this.isClaimed,
    this.assignedAdminUserId = '',
    this.assignedAdminLabel = '',
  });
}

class VerificationQueuePage {
  final List<VerificationQueueItem> items;
  final bool hasMore;
  final VerificationQueueCounts counts;

  const VerificationQueuePage({
    required this.items,
    required this.hasMore,
    required this.counts,
  });
}

class VerificationDocument {
  final String label;
  final String backendKey;
  final String path;
  final String signedUrl;
  final String feedbackReason;

  const VerificationDocument({
    required this.label,
    required this.backendKey,
    required this.path,
    this.signedUrl = '',
    this.feedbackReason = '',
  });

  bool get isUploaded => path.trim().isNotEmpty;
}

class VerificationReviewFeedbackPayload {
  final String summary;
  final String nextStep;
  final Map<String, String> documentReasons;

  const VerificationReviewFeedbackPayload({
    required this.summary,
    required this.nextStep,
    required this.documentReasons,
  });

  Map<String, dynamic> toJson() {
    final documents = <String, dynamic>{};
    for (final entry in documentReasons.entries) {
      final reason = entry.value.trim();
      if (entry.key.trim().isEmpty || reason.isEmpty) {
        continue;
      }
      documents[entry.key.trim()] = {
        'status': 'rejected',
        'reason': reason,
      };
    }
    return {
      'summary': summary.trim(),
      'next_step': nextStep.trim(),
      if (documents.isNotEmpty) 'documents': documents,
    };
  }
}

class VerificationCaseEvent {
  final String id;
  final String eventType;
  final String summary;
  final String internalNote;
  final DateTime? createdAt;

  const VerificationCaseEvent({
    required this.id,
    required this.eventType,
    required this.summary,
    required this.internalNote,
    required this.createdAt,
  });
}

class AdminVerificationDetail {
  final String caseId;
  final String subjectId;
  final String subjectType;
  final String subjectTypeLabel;
  final String displayName;
  final String subjectLabel;
  final String profileLinkId;
  final String profileLinkLabel;
  final String caseStatus;
  final DateTime? submittedAt;
  final DateTime? lastReviewedAt;
  final String decisionSummary;
  final String reviewFeedbackSummary;
  final String reviewFeedbackNextStep;
  final Map<String, String> reviewFeedbackDocumentReasons;
  final bool isClaimed;
  final String assignedAdminUserId;
  final String assignedAdminLabel;
  final String slaLabel;
  final Map<String, String> subjectMetadata;
  final List<VerificationDocument> documents;
  final List<VerificationCaseEvent> events;

  const AdminVerificationDetail({
    required this.caseId,
    required this.subjectId,
    required this.subjectType,
    required this.subjectTypeLabel,
    required this.displayName,
    required this.subjectLabel,
    this.profileLinkId = '',
    this.profileLinkLabel = '',
    required this.caseStatus,
    required this.submittedAt,
    required this.lastReviewedAt,
    required this.decisionSummary,
    required this.reviewFeedbackSummary,
    required this.reviewFeedbackNextStep,
    required this.reviewFeedbackDocumentReasons,
    required this.isClaimed,
    this.assignedAdminUserId = '',
    this.assignedAdminLabel = '',
    required this.slaLabel,
    required this.subjectMetadata,
    required this.documents,
    required this.events,
  });
}

class _DocumentSeed {
  final String label;
  final String backendKey;
  final String path;

  const _DocumentSeed({required this.label, required this.backendKey, required this.path});
}

enum VerificationReviewDecision { approve, reject }

abstract class AdminVerificationBackend {
  Future<List<Map<String, dynamic>>> fetchVerificationCases();

  Future<Map<String, dynamic>?> fetchVerificationCaseById(String caseId);

  Future<List<Map<String, dynamic>>> fetchVerificationCaseEvents(String caseId);

  Future<List<Map<String, dynamic>>> fetchAdminUsersByIds(List<String> ids);

  Future<List<Map<String, dynamic>>> fetchProfilesByIds(List<String> ids);

  Future<Map<String, dynamic>?> fetchProfileById(String id);

  Future<List<Map<String, dynamic>>> fetchSuppliersByIds(List<String> ids);

  Future<Map<String, dynamic>?> fetchSupplierById(String id);

  Future<Map<String, dynamic>?> fetchTruckerById(String id);

  Future<List<Map<String, dynamic>>> fetchTrucksByIds(List<String> ids);

  Future<Map<String, dynamic>?> fetchTruckById(String id);

  Future<String?> createVerificationDocumentSignedUrl(String path);

  Future<bool> approveVerificationCase({
    required String caseId,
    required String subjectType,
    required String subjectId,
  });

  Future<bool> rejectVerificationCase({
    required String caseId,
    required String subjectType,
    required String subjectId,
    required String reason,
    VerificationReviewFeedbackPayload? feedback,
  });
}
