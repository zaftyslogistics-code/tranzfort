import 'package:admin/src/core/repositories/admin_user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminUserBackend implements AdminUserBackend {
  List<Map<String, dynamic>> profiles = const [];
  Map<String, int> supplierLoadCounts = const {};
  Map<String, int> supplierActiveLoadCounts = const {};
  Map<String, int> truckerTripCounts = const {};
  Map<String, Map<String, dynamic>> profileById = const {};
  Map<String, Map<String, dynamic>> supplierById = const {};
  Map<String, Map<String, dynamic>> truckerById = const {};
  Map<String, List<Map<String, dynamic>>> supplierRecentLoads = const {};
  Map<String, List<Map<String, dynamic>>> truckerRecentTrips = const {};
  Map<String, List<Map<String, dynamic>>> userAuditEntries = const {};
  Map<String, List<Map<String, dynamic>>> truckerFleet = const {};
  Map<String, Map<String, dynamic>> latestVerificationCases = const {};
  Map<String, Map<String, dynamic>> latestTruckVerificationCases = const {};
  Map<String, String> signedUrlsByPath = const {};
  bool banStatusResult = true;
  String? lastBanUserId;
  bool? lastBanValue;
  String? lastBanReason;

  @override
  Future<int> countSupplierLoads(String userId) async => supplierLoadCounts[userId] ?? 0;

  @override
  Future<int> countActiveSupplierLoads(String userId) async => supplierActiveLoadCounts[userId] ?? 0;

  @override
  Future<int> countTruckerTrips(String userId) async => truckerTripCounts[userId] ?? 0;

  @override
  Future<Map<String, dynamic>?> fetchProfileById(String userId) async => profileById[userId];

  @override
  Future<List<Map<String, dynamic>>> fetchProfiles() async => profiles;

  @override
  Future<Map<String, dynamic>?> fetchSupplierById(String userId) async => supplierById[userId];

  @override
  Future<List<Map<String, dynamic>>> fetchSupplierRecentLoads(String userId) async => supplierRecentLoads[userId] ?? const [];

  @override
  Future<Map<String, dynamic>?> fetchTruckerById(String userId) async => truckerById[userId];

  @override
  Future<List<Map<String, dynamic>>> fetchTruckerFleet(String userId) async => truckerFleet[userId] ?? const [];

  @override
  Future<List<Map<String, dynamic>>> fetchTruckerRecentTrips(String userId) async => truckerRecentTrips[userId] ?? const [];

  @override
  Future<List<Map<String, dynamic>>> fetchUserAuditEntries(String userId) async => userAuditEntries[userId] ?? const [];

  @override
  Future<Map<String, dynamic>?> fetchLatestVerificationCase({
    required String userId,
    required String subjectType,
  }) async => latestVerificationCases['$subjectType:$userId'];

  @override
  Future<Map<String, Map<String, dynamic>>> fetchLatestTruckVerificationCases(List<String> truckIds) async {
    return {
      for (final id in truckIds)
        if (latestTruckVerificationCases.containsKey(id)) id: latestTruckVerificationCases[id]!,
    };
  }

  @override
  Future<String?> createVerificationDocumentSignedUrl(String path) async => signedUrlsByPath[path];

  @override
  Future<bool> updateBanStatus({required String userId, required bool isBanned, String? reason}) async {
    lastBanUserId = userId;
    lastBanValue = isBanned;
    lastBanReason = reason;
    return banStatusResult;
  }

  @override
  Future<Map<String, int>> batchCountSupplierLoads(List<String> userIds) async {
    return {for (final id in userIds) if (supplierLoadCounts.containsKey(id)) id: supplierLoadCounts[id]!};
  }

  @override
  Future<Map<String, int>> batchCountTruckerTrips(List<String> userIds) async {
    return {for (final id in userIds) if (truckerTripCounts.containsKey(id)) id: truckerTripCounts[id]!};
  }
}

void main() {
  test('AdminUserListQuery equality includes pagination fields', () {
    const a = AdminUserListQuery(filter: AdminUserFilter.supplier, search: 'mumbai', page: 1, pageSize: 20);
    const b = AdminUserListQuery(filter: AdminUserFilter.supplier, search: 'mumbai', page: 1, pageSize: 20);
    const c = AdminUserListQuery(filter: AdminUserFilter.supplier, search: 'mumbai', page: 0, pageSize: 20);

    expect(a, equals(b));
    expect(a.hashCode, b.hashCode);
    expect(a == c, isFalse);
  });

  test('searchUsers filters and paginates supplier results', () async {
    final backend = _FakeAdminUserBackend()
      ..profiles = [
        {
          'id': 'user-1',
          'full_name': 'Supplier One',
          'mobile': '9999999999',
          'email': 'supplier@example.com',
          'user_role_type': 'supplier',
          'verification_status': 'approved',
          'is_banned': false,
          'ban_reason': '',
          'created_at': '2026-03-11T10:00:00.000Z',
          'last_login_at': '2026-03-11T11:00:00.000Z',
        },
        {
          'id': 'user-2',
          'full_name': 'Trucker One',
          'mobile': '8888888888',
          'email': 'trucker@example.com',
          'user_role_type': 'trucker',
          'verification_status': 'pending',
          'is_banned': false,
          'ban_reason': '',
          'created_at': '2026-03-11T09:00:00.000Z',
          'last_login_at': null,
        },
      ]
      ..supplierLoadCounts = {'user-1': 5}
      ..truckerTripCounts = {'user-2': 3};

    final container = ProviderContainer(
      overrides: [
        adminUserBackendProvider.overrideWithValue(backend),
      ],
    );
    addTearDown(container.dispose);

    final repository = container.read(adminUserRepositoryProvider);
    final page = await repository.searchUsers(const AdminUserListQuery(filter: AdminUserFilter.supplier, search: 'supplier'));
    final idPage = await repository.searchUsers(const AdminUserListQuery(filter: AdminUserFilter.all, search: 'user-2'));
    final statePage = await repository.searchUsers(const AdminUserListQuery(filter: AdminUserFilter.all, search: 'pending'));

    expect(page.items, hasLength(1));
    expect(page.items.single.fullName, 'Supplier One');
    expect(page.items.single.activityCount, 5);
    expect(page.hasMore, isFalse);
    expect(idPage.items, hasLength(1));
    expect(idPage.items.single.id, 'user-2');
    expect(statePage.items, hasLength(1));
    expect(statePage.items.single.verificationStatus, 'pending');
  });

  test('getUserDetail returns supplier metadata and documents', () async {
    final backend = _FakeAdminUserBackend()
      ..profileById = {
        'user-1': {
          'id': 'user-1',
          'full_name': 'Supplier One',
          'mobile': '9999999999',
          'email': 'supplier@example.com',
          'user_role_type': 'supplier',
          'verification_status': 'approved',
          'is_banned': false,
          'ban_reason': '',
          'created_at': '2026-03-11T10:00:00.000Z',
          'last_login_at': '2026-03-11T11:00:00.000Z',
          'verification_feedback_json': {
            'summary': 'GST certificate mismatch',
            'next_step': 'Upload the correct GST certificate and resubmit.',
          },
          'aadhaar_front_document_path': 'user-1/aadhaar_front/aadhaar_front.jpg',
          'aadhaar_back_document_path': '',
          'pan_document_path': 'user-1/pan/pan.jpg',
          'profile_photo_document_path': 'user-1/profile_photo/profile_photo.jpg',
        },
      }
      ..supplierById = {
        'user-1': {
          'company_name': 'S1 Logistics',
          'gst_number': 'GST123',
          'gst_certificate_document_path': 'user-1/gst_certificate/gst_certificate.jpg',
          'business_licence_number': 'LIC123',
          'business_licence_document_path': 'user-1/business_licence/business_licence.jpg',
          'verification_location_city': 'Mumbai',
          'verification_location_state': 'Maharashtra',
          'verification_location_lat': 19.076,
          'verification_location_lng': 72.8777,
        },
      }
      ..supplierRecentLoads = {
        'user-1': [
          {
            'id': 'load-1',
            'origin_city': 'Mumbai',
            'dest_city': 'Pune',
            'status': 'active',
            'created_at': '2026-03-11T09:00:00.000Z',
          },
        ],
      }
      ..userAuditEntries = {
        'user-1': [
          {
            'id': 'audit-1',
            'action_type': 'user_verification_rejected',
            'summary_text': 'Verification rejected for missing GST proof',
            'target_object_type': 'profile',
            'target_object_id': 'user-1',
            'created_at': '2026-03-11T08:00:00.000Z',
          },
        ],
      }
      ..supplierLoadCounts = {'user-1': 8}
      ..supplierActiveLoadCounts = {'user-1': 3}
      ..latestVerificationCases = {
        'supplier_profile:user-1': {
          'id': 'case-1',
          'case_status': 'waiting_for_resubmission',
          'current_decision_summary': 'Documents need correction',
          'current_review_feedback_json': {
            'summary': 'Business licence details do not match',
            'next_step': 'Upload the corrected business licence copy.',
          },
          'last_reviewed_at': '2026-03-11T12:00:00.000Z',
        },
      }
      ..signedUrlsByPath = {
        'user-1/aadhaar_front/aadhaar_front.jpg': 'https://signed/aadhaar-front',
        'user-1/pan/pan.jpg': 'https://signed/pan',
        'user-1/profile_photo/profile_photo.jpg': 'https://signed/profile-photo',
        'user-1/gst_certificate/gst_certificate.jpg': 'https://signed/gst',
        'user-1/business_licence/business_licence.jpg': 'https://signed/licence',
      };

    final container = ProviderContainer(
      overrides: [
        adminUserBackendProvider.overrideWithValue(backend),
      ],
    );
    addTearDown(container.dispose);

    final repository = container.read(adminUserRepositoryProvider);
    final detail = await repository.getUserDetail('user-1');

    expect(detail, isNotNull);
    expect(detail!.profile.activityCount, 8);
    expect(detail.roleMetadata['Company'], 'S1 Logistics');
    expect(detail.roleMetadata['Verification location'], 'Mumbai, Maharashtra');
    expect(detail.roleMetadata['Verification coordinates'], contains('19.076'));
    expect(detail.verificationFeedbackSummary, 'GST certificate mismatch');
    expect(detail.verificationFeedbackNextStep, contains('resubmit'));
    expect(detail.latestVerificationCase, isNotNull);
    expect(detail.latestVerificationCase!.status, 'waiting_for_resubmission');
    expect(detail.latestVerificationCase!.decisionSummary, 'Documents need correction');
    expect(detail.stats['Loads posted'], '8');
    expect(detail.stats['Active loads'], '3');
    expect(detail.documents.any((doc) => doc.label == 'GST Certificate'), isTrue);
    expect(detail.documents.any((doc) => doc.label == 'PAN Card' && doc.signedUrl == 'https://signed/pan'), isTrue);
    expect(detail.recentItems.single.title, 'Mumbai -> Pune');
    expect(detail.auditEntries.single.actionType, 'user_verification_rejected');
    expect(detail.auditEntries.single.summary, contains('GST proof'));
  });

  test('setBanStatus delegates mutation to backend', () async {
    final backend = _FakeAdminUserBackend();

    final container = ProviderContainer(
      overrides: [
        adminUserBackendProvider.overrideWithValue(backend),
      ],
    );
    addTearDown(container.dispose);

    final repository = container.read(adminUserRepositoryProvider);
    final ok = await repository.setBanStatus(
      userId: 'user-1',
      isBanned: true,
      reason: 'Repeated fraud reports',
    );

    expect(ok, isTrue);
    expect(backend.lastBanUserId, 'user-1');
    expect(backend.lastBanValue, isTrue);
    expect(backend.lastBanReason, 'Repeated fraud reports');
  });

  test('getUserDetail returns trucker fleet data', () async {
    final backend = _FakeAdminUserBackend()
      ..profileById = {
        'user-2': {
          'id': 'user-2',
          'full_name': 'Trucker One',
          'mobile': '8888888888',
          'email': 'trucker@example.com',
          'user_role_type': 'trucker',
          'verification_status': 'approved',
          'is_banned': false,
          'ban_reason': '',
          'created_at': '2026-03-11T10:00:00.000Z',
          'last_login_at': '2026-03-11T11:00:00.000Z',
          'aadhaar_front_document_path': '',
          'aadhaar_back_document_path': '',
          'pan_document_path': '',
          'profile_photo_document_path': '',
        },
      }
      ..truckerById = {
        'user-2': {
          'dl_number': 'DL123',
          'rating': '4.8',
          'completed_trips': '12',
          'total_trips': '16',
        },
      }
      ..truckerTripCounts = {'user-2': 16}
      ..truckerFleet = {
        'user-2': [
          {
            'id': 'truck-1',
            'truck_number': 'MH12AB1234',
            'body_type': 'Open Body',
            'tyres': 10,
            'capacity_tonnes': '21',
            'status': 'rejected',
            'rejection_reason': 'RC copy is blurry',
            'verification_feedback_json': {
              'summary': 'RC document could not be verified',
              'next_step': 'Upload a clearer RC photo and resubmit.',
            },
            'verified_at': null,
            'truck_models': {'make': 'Tata', 'model': 'Signa'},
          },
        ],
      }
      ..latestTruckVerificationCases = {
        'truck-1': {
          'id': 'case-truck-1',
          'case_status': 'submitted',
        },
      }
      ..truckerRecentTrips = {
        'user-2': [
          {
            'id': 'trip-1',
            'stage': 'in_transit',
            'created_at': '2026-03-11T09:00:00.000Z',
          },
        ],
      };

    final container = ProviderContainer(
      overrides: [
        adminUserBackendProvider.overrideWithValue(backend),
      ],
    );
    addTearDown(container.dispose);

    final repository = container.read(adminUserRepositoryProvider);
    final detail = await repository.getUserDetail('user-2');

    expect(detail, isNotNull);
    expect(detail!.stats['Fleet size'], '1');
    expect(detail.documents, isEmpty);
    expect(detail.roleMetadata['DL Number'], 'DL123');
    expect(detail.roleMetadata['Total trips'], '16');
    expect(detail.fleetTrucks.single.truckNumber, 'MH12AB1234');
    expect(detail.fleetTrucks.single.modelLabel, 'Tata Signa');
    expect(detail.fleetTrucks.single.verificationCaseId, 'case-truck-1');
    expect(detail.fleetTrucks.single.verificationCaseStatus, 'submitted');
    expect(detail.fleetTrucks.single.rejectionReason, 'RC copy is blurry');
    expect(detail.fleetTrucks.single.feedbackSummary, contains('RC document'));
  });
}
