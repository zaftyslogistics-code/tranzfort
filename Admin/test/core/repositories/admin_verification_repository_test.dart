import 'package:admin/src/core/repositories/admin_verification_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminVerificationBackend implements AdminVerificationBackend {
  List<Map<String, dynamic>> verificationCases = const [];
  Map<String, Map<String, dynamic>> verificationCasesById = const {};
  Map<String, List<Map<String, dynamic>>> verificationCaseEventsById = const {};
  Map<String, Map<String, dynamic>> adminUsersById = const {};
  Map<String, Map<String, dynamic>> profilesById = const {};
  Map<String, Map<String, dynamic>> suppliersById = const {};
  Map<String, Map<String, dynamic>> truckersById = const {};
  Map<String, Map<String, dynamic>> trucksById = const {};
  String? lastApprovedCaseId;
  String? lastRejectedCaseId;
  String? lastRejectedReason;
  String? lastApprovedTruckId;
  String? lastRejectedTruckId;
  VerificationReviewFeedbackPayload? lastRejectedFeedback;

  @override
  Future<List<Map<String, dynamic>>> fetchVerificationCases() async => verificationCases;

  @override
  Future<Map<String, dynamic>?> fetchVerificationCaseById(String caseId) async => verificationCasesById[caseId];

  @override
  Future<List<Map<String, dynamic>>> fetchVerificationCaseEvents(String caseId) async =>
      verificationCaseEventsById[caseId] ?? const [];

  @override
  Future<List<Map<String, dynamic>>> fetchAdminUsersByIds(List<String> ids) async => ids
      .map((id) => adminUsersById[id])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);

  @override
  Future<List<Map<String, dynamic>>> fetchProfilesByIds(List<String> ids) async => ids
      .map((id) => profilesById[id])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);

  @override
  Future<Map<String, dynamic>?> fetchProfileById(String id) async => profilesById[id];

  @override
  Future<List<Map<String, dynamic>>> fetchSuppliersByIds(List<String> ids) async => ids
      .map((id) => suppliersById[id])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);

  @override
  Future<Map<String, dynamic>?> fetchSupplierById(String id) async => suppliersById[id];

  @override
  Future<Map<String, dynamic>?> fetchTruckerById(String id) async => truckersById[id];

  @override
  Future<List<Map<String, dynamic>>> fetchTrucksByIds(List<String> ids) async => ids
      .map((id) => trucksById[id])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);

  @override
  Future<Map<String, dynamic>?> fetchTruckById(String id) async => trucksById[id];

  @override
  Future<String?> createVerificationDocumentSignedUrl(String path) async => 'https://signed/$path';

  @override
  Future<bool> approveVerificationCase({required String caseId, required String subjectType, required String subjectId}) async {
    if (subjectType == 'truck') {
      lastApprovedTruckId = subjectId;
    } else {
      lastApprovedCaseId = caseId;
    }
    return true;
  }

  @override
  Future<bool> rejectVerificationCase({
    required String caseId,
    required String subjectType,
    required String subjectId,
    required String reason,
    VerificationReviewFeedbackPayload? feedback,
  }) async {
    lastRejectedReason = reason;
    lastRejectedFeedback = feedback;
    if (subjectType == 'truck') {
      lastRejectedTruckId = subjectId;
    } else {
      lastRejectedCaseId = caseId;
    }
    return true;
  }
}

void main() {
  test('getVerificationQueue returns tab counts, supports stable search, and maps supplier cases', () async {
    final backend = _FakeAdminVerificationBackend()
      ..verificationCases = [
        {
          'id': 'case-1',
          'subject_type': 'supplier_profile',
          'subject_id': 'user-1',
          'case_status': 'submitted',
          'assigned_admin_user_id': '',
          'submitted_at': '2026-03-10T08:00:00.000Z',
        },
        {
          'id': 'case-2',
          'subject_type': 'truck',
          'subject_id': 'truck-1',
          'case_status': 'in_review',
          'assigned_admin_user_id': 'admin-1',
          'submitted_at': '2026-03-11T08:00:00.000Z',
        },
      ]
      ..adminUsersById = {
        'admin-1': {
          'id': 'admin-1',
          'full_name': 'Ops One',
          'role': 'ops_admin',
        },
      }
      ..profilesById = {
        'user-1': {
          'id': 'user-1',
          'full_name': 'Supplier One',
          'mobile': '9999999999',
          'email': 'supplier@example.com',
        },
        'owner-1': {
          'id': 'owner-1',
          'full_name': 'Trucker Owner',
          'mobile': '8888888888',
          'email': 'trucker@example.com',
        },
      }
      ..suppliersById = {
        'user-1': {
          'id': 'user-1',
          'company_name': 'S1 Logistics',
        },
      }
      ..trucksById = {
        'truck-1': {
          'id': 'truck-1',
          'owner_id': 'owner-1',
          'truck_number': 'MH12AB1234',
          'body_type': 'Open Body',
        },
      };

    final container = ProviderContainer(
      overrides: [
        adminVerificationBackendProvider.overrideWithValue(backend),
      ],
    );
    addTearDown(container.dispose);

    final repository = container.read(adminVerificationRepositoryProvider);
    final page = await repository.getVerificationQueue(
      const VerificationQueueQuery(
        tab: VerificationQueueTab.suppliers,
        sort: VerificationQueueSort.slaUrgency,
        search: 'logistics',
      ),
    );
    final assignedAdminPage = await repository.getVerificationQueue(
      const VerificationQueueQuery(
        tab: VerificationQueueTab.trucks,
        sort: VerificationQueueSort.slaUrgency,
        search: 'admin-1',
      ),
    );
    final subjectIdPage = await repository.getVerificationQueue(
      const VerificationQueueQuery(
        tab: VerificationQueueTab.trucks,
        sort: VerificationQueueSort.slaUrgency,
        search: 'truck-1',
      ),
    );

    expect(page.counts.suppliers, 1);
    expect(page.counts.trucks, 1);
    expect(page.items, hasLength(1));
    expect(page.items.single.displayName, 'S1 Logistics');
    expect(page.items.single.contactLabel, '9999999999');
    expect(page.items.single.assignedAdminUserId, '');
    expect(page.items.single.assignedAdminLabel, '');
    expect(assignedAdminPage.items, hasLength(1));
    expect(assignedAdminPage.items.single.caseId, 'case-2');
    expect(subjectIdPage.items, hasLength(1));
    expect(subjectIdPage.items.single.caseId, 'case-2');
  });

  test('getVerificationDetail maps supplier case documents and timeline', () async {
    final backend = _FakeAdminVerificationBackend()
      ..verificationCasesById = {
        'case-1': {
          'id': 'case-1',
          'subject_type': 'supplier_profile',
          'subject_id': 'user-1',
          'case_status': 'waiting_for_resubmission',
          'assigned_admin_user_id': 'admin-1',
          'submitted_at': '2026-03-11T08:00:00.000Z',
          'last_reviewed_at': '2026-03-11T10:00:00.000Z',
          'current_decision_summary': 'Documents need correction',
          'current_review_feedback_json': {
            'summary': 'Business licence mismatch',
            'next_step': 'Upload corrected licence copy',
            'documents': {
              'pan': {
                'status': 'rejected',
                'reason': 'PAN image unreadable',
              },
              'profile_photo': {
                'status': 'rejected',
                'reason': 'Face is not clearly visible',
              },
            },
          },
        },
      }
      ..adminUsersById = {
        'admin-1': {
          'id': 'admin-1',
          'full_name': 'Ops One',
          'role': 'ops_admin',
        },
      }
      ..verificationCaseEventsById = {
        'case-1': [
          {
            'id': 'event-1',
            'event_type': 'case_submitted',
            'event_summary': 'Verification submitted',
            'internal_note': '',
            'created_at': '2026-03-11T08:00:00.000Z',
          },
        ],
      }
      ..profilesById = {
        'user-1': {
          'id': 'user-1',
          'full_name': 'Supplier One',
          'mobile': '9999999999',
          'email': 'supplier@example.com',
          'aadhaar_number': '123412341234',
          'aadhaar_last4': '1234',
          'pan_number': 'ABCDE1234F',
          'aadhaar_front_document_path': 'user-1/aadhaar-front.jpg',
          'aadhaar_back_document_path': 'user-1/aadhaar-back.jpg',
          'pan_document_path': 'user-1/pan.jpg',
          'profile_photo_document_path': 'user-1/photo.jpg',
          'verification_feedback_json': const {},
        },
      }
      ..suppliersById = {
        'user-1': {
          'id': 'user-1',
          'company_name': 'S1 Logistics',
          'gst_number': '27ABCDE1234F1Z5',
          'gst_certificate_document_path': 'user-1/gst.jpg',
          'business_licence_number': 'BL-001',
          'business_licence_document_path': 'user-1/licence.jpg',
          'verification_location_city': 'Mumbai',
          'verification_location_state': 'Maharashtra',
        },
      };

    final container = ProviderContainer(
      overrides: [
        adminVerificationBackendProvider.overrideWithValue(backend),
      ],
    );
    addTearDown(container.dispose);

    final repository = container.read(adminVerificationRepositoryProvider);
    final detail = await repository.getVerificationDetail('case-1');

    expect(detail, isNotNull);
    expect(detail!.displayName, 'S1 Logistics');
    expect(detail.documents, isNotEmpty);
    expect(detail.documents.first.signedUrl, contains('https://signed/'));
    expect(detail.reviewFeedbackSummary, 'Business licence mismatch');
    expect(detail.reviewFeedbackDocumentReasons['pan'], 'PAN image unreadable');
    expect(detail.assignedAdminUserId, 'admin-1');
    expect(detail.assignedAdminLabel, 'Ops One (ops_admin)');
    expect(detail.events.single.eventType, 'case_submitted');
    expect(detail.subjectMetadata['Aadhaar number'], '123412341234');
    expect(detail.subjectMetadata['Aadhaar last 4'], '1234');
    expect(detail.subjectMetadata['PAN number'], 'ABCDE1234F');
  });

  test('getVerificationDetail keeps expected document rows even when some document paths are missing', () async {
    final backend = _FakeAdminVerificationBackend()
      ..verificationCasesById = {
        'case-missing-docs': {
          'id': 'case-missing-docs',
          'subject_type': 'supplier_profile',
          'subject_id': 'user-2',
          'case_status': 'submitted',
          'submitted_at': '2026-03-12T08:00:00.000Z',
          'last_reviewed_at': null,
          'current_decision_summary': null,
          'current_review_feedback_json': const {},
          'assigned_admin_user_id': null,
        },
      }
      ..verificationCaseEventsById = {
        'case-missing-docs': const [],
      }
      ..profilesById = {
        'user-2': {
          'id': 'user-2',
          'full_name': 'Supplier Two',
          'mobile': '8888888888',
          'email': 'supplier2@example.com',
          'aadhaar_front_document_path': 'user-2/aadhaar-front.jpg',
          'aadhaar_back_document_path': '',
          'pan_document_path': '',
          'profile_photo_document_path': '',
          'verification_feedback_json': const {},
        },
      }
      ..suppliersById = {
        'user-2': {
          'id': 'user-2',
          'company_name': 'S2 Logistics',
          'gst_number': '',
          'gst_certificate_document_path': '',
          'business_licence_number': '',
          'business_licence_document_path': '',
          'verification_location_city': '',
          'verification_location_state': '',
        },
      };

    final container = ProviderContainer(
      overrides: [
        adminVerificationBackendProvider.overrideWithValue(backend),
      ],
    );
    addTearDown(container.dispose);

    final repository = container.read(adminVerificationRepositoryProvider);
    final detail = await repository.getVerificationDetail('case-missing-docs');

    expect(detail, isNotNull);
    expect(detail!.documents.map((document) => document.label), containsAll(<String>[
      'Aadhaar Front',
      'Aadhaar Back',
      'PAN Card',
      'Profile Photo',
      'Business Licence',
      'GST Certificate',
    ]));
    expect(detail.documents.firstWhere((document) => document.label == 'Aadhaar Front').isUploaded, isTrue);
    expect(detail.documents.firstWhere((document) => document.label == 'PAN Card').isUploaded, isFalse);
  });

  test('submitReviewDecision routes profile and truck actions to the backend contract', () async {
    final backend = _FakeAdminVerificationBackend();
    final container = ProviderContainer(
      overrides: [
        adminVerificationBackendProvider.overrideWithValue(backend),
      ],
    );
    addTearDown(container.dispose);

    final repository = container.read(adminVerificationRepositoryProvider);

    await repository.submitReviewDecision(
      detail: const AdminVerificationDetail(
        caseId: 'case-1',
        subjectId: 'user-1',
        subjectType: 'supplier_profile',
        subjectTypeLabel: 'Supplier',
        displayName: 'S1 Logistics',
        subjectLabel: 'Supplier profile verification case',
        caseStatus: 'submitted',
        submittedAt: null,
        lastReviewedAt: null,
        decisionSummary: '',
        reviewFeedbackSummary: '',
        reviewFeedbackNextStep: '',
        reviewFeedbackDocumentReasons: {},
        isClaimed: false,
        slaLabel: '12h left',
        subjectMetadata: {},
        documents: [],
        events: [],
      ),
      decision: VerificationReviewDecision.approve,
    );
    await repository.submitReviewDecision(
      detail: const AdminVerificationDetail(
        caseId: 'case-2',
        subjectId: 'truck-1',
        subjectType: 'truck',
        subjectTypeLabel: 'Truck',
        displayName: 'MH12AB1234',
        subjectLabel: 'Truck verification case',
        caseStatus: 'submitted',
        submittedAt: null,
        lastReviewedAt: null,
        decisionSummary: '',
        reviewFeedbackSummary: '',
        reviewFeedbackNextStep: '',
        reviewFeedbackDocumentReasons: {},
        isClaimed: false,
        slaLabel: '12h left',
        subjectMetadata: {},
        documents: [],
        events: [],
      ),
      decision: VerificationReviewDecision.reject,
      reason: 'Missing RC pages',
      feedback: const VerificationReviewFeedbackPayload(
        summary: 'RC pages are incomplete',
        nextStep: 'Upload the full RC document set and resubmit.',
        documentReasons: {
          'rc_document': 'Rear page is missing from the uploaded RC set',
        },
      ),
    );

    expect(backend.lastApprovedCaseId, 'case-1');
    expect(backend.lastRejectedTruckId, 'truck-1');
    expect(backend.lastRejectedReason, 'Missing RC pages');
    expect(backend.lastRejectedFeedback, isNotNull);
    expect(backend.lastRejectedFeedback!.summary, 'RC pages are incomplete');
    expect(backend.lastRejectedFeedback!.documentReasons['rc_document'], 'Rear page is missing from the uploaded RC set');
  });

  test('submitReviewDecision forwards structured feedback for profile rejections', () async {
    final backend = _FakeAdminVerificationBackend();
    final container = ProviderContainer(
      overrides: [
        adminVerificationBackendProvider.overrideWithValue(backend),
      ],
    );
    addTearDown(container.dispose);

    final repository = container.read(adminVerificationRepositoryProvider);

    await repository.submitReviewDecision(
      detail: const AdminVerificationDetail(
        caseId: 'case-3',
        subjectId: 'user-3',
        subjectType: 'supplier_profile',
        subjectTypeLabel: 'Supplier',
        displayName: 'S3 Logistics',
        subjectLabel: 'Supplier profile verification case',
        caseStatus: 'submitted',
        submittedAt: null,
        lastReviewedAt: null,
        decisionSummary: '',
        reviewFeedbackSummary: '',
        reviewFeedbackNextStep: '',
        reviewFeedbackDocumentReasons: {},
        isClaimed: false,
        slaLabel: '12h left',
        subjectMetadata: {},
        documents: [],
        events: [],
      ),
      decision: VerificationReviewDecision.reject,
      reason: 'Two items need correction',
      feedback: const VerificationReviewFeedbackPayload(
        summary: 'Two items need correction',
        nextStep: 'Replace the rejected documents and resubmit.',
        documentReasons: {
          'pan': 'PAN image unreadable',
          'profile_photo': 'Face is not clearly visible',
        },
      ),
    );

    expect(backend.lastRejectedCaseId, 'case-3');
    expect(backend.lastRejectedFeedback, isNotNull);
    expect(backend.lastRejectedFeedback!.summary, 'Two items need correction');
    expect(backend.lastRejectedFeedback!.documentReasons['pan'], 'PAN image unreadable');
  });
}
