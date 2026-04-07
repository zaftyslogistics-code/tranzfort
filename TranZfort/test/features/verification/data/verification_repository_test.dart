import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/verification/data/verification_repository.dart';

class _FakeVerificationBackend implements VerificationBackend {
  Map<String, dynamic>? profileMap;
  Map<String, dynamic>? supplierMap;
  int approvedTruckCount = 0;
  int verificationReadyTruckCount = 0;
  Map<String, dynamic>? lastProfileUpdate;
  Map<String, dynamic>? lastSupplierUpdate;
  bool submitCalled = false;
  bool resubmitCalled = false;

  @override
  Future<int> countApprovedTrucks(String userId) async => approvedTruckCount;

  @override
  Future<int> countVerificationReadyTrucks(String userId) async => verificationReadyTruckCount;

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async => profileMap;

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String userId) async => supplierMap;

  @override
  Future<String> resubmitVerificationCase() async {
    resubmitCalled = true;
    return 'case-2';
  }

  @override
  Future<void> updateProfileFields(String userId, Map<String, dynamic> values) async {
    lastProfileUpdate = values;
  }

  @override
  Future<void> updateSupplierFields(String userId, Map<String, dynamic> values) async {
    lastSupplierUpdate = values;
  }

  @override
  Future<String> submitVerificationForReview() async {
    submitCalled = true;
    return 'case-1';
  }
}

void main() {
  group('VerificationRepository', () {
    test('maps trucker verification detail and truck readiness', () async {
      final backend = _FakeVerificationBackend()
        ..profileMap = {
          'id': 'trucker-1',
          'user_role_type': 'trucker',
          'verification_status': 'rejected',
          'verification_rejection_reason': 'PAN image unreadable',
          'aadhaar_number': '123412341234',
          'aadhaar_last4': '1234',
          'pan_number': 'ABCDE1234F',
          'verification_feedback_json': {
            'summary': 'Two items need correction',
            'next_step': 'Replace the rejected documents and resubmit.',
            'documents': {
              'pan': {
                'status': 'rejected',
                'reason': 'PAN image unreadable',
              },
            },
          },
          'aadhaar_front_document_path': 'trucker-1/aadhaar_front/aadhaar_front.jpg',
          'aadhaar_back_document_path': null,
          'pan_document_path': 'trucker-1/pan/pan.jpg',
          'profile_photo_document_path': null,
        }
        ..approvedTruckCount = 1
        ..verificationReadyTruckCount = 1;
      final repository = VerificationRepository(backend, () => 'trucker-1');

      final result = await repository.fetchCurrentDetail();

      expect(result.isSuccess, isTrue);
      final detail = result.valueOrNull!;
      expect(detail.role, AppUserRole.trucker);
      expect(detail.isRejected, isTrue);
      expect(detail.rejectionReason, 'PAN image unreadable');
      expect(detail.reviewFeedback.summary, 'Two items need correction');
      expect(detail.reviewFeedback.nextStep, 'Replace the rejected documents and resubmit.');
      expect(detail.reviewFeedback.feedbackFor(VerificationDocumentType.pan)?.isRejected, isTrue);
      expect(detail.reviewFeedback.feedbackFor(VerificationDocumentType.pan)?.reason, 'PAN image unreadable');
      expect(detail.visibleDocuments, hasLength(4));
      expect(detail.hasApprovedTruckRequirement, isTrue);
      expect(detail.hasVerificationReadyTruckRequirement, isTrue);
      expect(detail.aadhaarNumber, '123412341234');
      expect(detail.panNumber, 'ABCDE1234F');
      expect(detail.canSubmitForReview, isFalse);
      expect(detail.submissionBlockedReason, contains('aadhaar back'));
    });

    test('maps supplier verification detail including optional gst and business licence', () async {
      final backend = _FakeVerificationBackend()
        ..profileMap = {
          'id': 'supplier-1',
          'user_role_type': 'supplier',
          'verification_status': 'unverified',
          'verification_rejection_reason': null,
          'aadhaar_number': '123412341234',
          'aadhaar_last4': '1234',
          'pan_number': 'ABCDE1234F',
          'aadhaar_front_document_path': 'supplier-1/aadhaar_front/aadhaar_front.jpg',
          'aadhaar_back_document_path': 'supplier-1/aadhaar_back/aadhaar_back.jpg',
          'pan_document_path': 'supplier-1/pan/pan.jpg',
          'profile_photo_document_path': 'supplier-1/profile_photo/profile_photo.jpg',
        }
        ..supplierMap = {
          'id': 'supplier-1',
          'company_name': 'North Hub Logistics',
          'business_licence_number': 'BL-7788',
          'business_licence_document_path': 'supplier-1/business_licence/business_licence.jpg',
          'gst_number': null,
          'gst_certificate_document_path': null,
          'verification_location_city': 'Mumbai',
          'verification_location_state': 'Maharashtra',
          'verification_location_lat': 19.076,
          'verification_location_lng': 72.8777,
        };
      final repository = VerificationRepository(backend, () => 'supplier-1');

      final result = await repository.fetchCurrentDetail();

      expect(result.isSuccess, isTrue);
      final detail = result.valueOrNull!;
      expect(detail.role, AppUserRole.supplier);
      expect(detail.visibleDocuments, hasLength(6));
      expect(detail.canSubmitForReview, isTrue);
      expect(detail.companyName, 'North Hub Logistics');
      expect(detail.businessLicenceNumber, 'BL-7788');
      expect(detail.businessLicenceDocumentPath, contains('business_licence'));
      expect(detail.gstCertificateDocumentPath, isNull);
      expect(detail.verificationLocationCity, 'Mumbai');
      expect(detail.hasVerificationLocation, isTrue);
    });

    test('saveVerificationPacketFields stores profile and supplier identifiers', () async {
      final backend = _FakeVerificationBackend()
        ..profileMap = {
          'id': 'supplier-1',
          'user_role_type': 'supplier',
          'verification_status': 'unverified',
        };
      final repository = VerificationRepository(backend, () => 'supplier-1');

      final result = await repository.saveVerificationPacketFields(
        companyName: 'North Hub Logistics',
        aadhaarNumber: '123412341234',
        panNumber: 'abcde1234f',
        businessLicenceNumber: 'BL-7788',
        gstNumber: '27ABCDE1234F1Z5',
      );

      expect(result.isSuccess, isTrue);
      expect(backend.lastProfileUpdate?['aadhaar_number'], '123412341234');
      expect(backend.lastProfileUpdate?['aadhaar_last4'], '1234');
      expect(backend.lastProfileUpdate?['pan_number'], 'ABCDE1234F');
      expect(backend.lastSupplierUpdate?['company_name'], 'North Hub Logistics');
      expect(backend.lastSupplierUpdate?['business_licence_number'], 'BL-7788');
      expect(backend.lastSupplierUpdate?['gst_number'], '27ABCDE1234F1Z5');
    });

    test('saveDocumentPath updates supplier fields for business licence', () async {
      final backend = _FakeVerificationBackend()
        ..profileMap = {
          'id': 'supplier-1',
          'user_role_type': 'supplier',
          'verification_status': 'unverified',
        };
      final repository = VerificationRepository(backend, () => 'supplier-1');

      final result = await repository.saveDocumentPath(
        type: VerificationDocumentType.businessLicence,
        storagePath: 'supplier-1/business_licence/business_licence.jpg',
      );

      expect(result.isSuccess, isTrue);
      expect(backend.lastSupplierUpdate?['business_licence_document_path'], 'supplier-1/business_licence/business_licence.jpg');
      expect(backend.lastProfileUpdate, isNull);
    });

    test('saveDocumentPath updates profile fields for trucker identity documents', () async {
      final backend = _FakeVerificationBackend()
        ..profileMap = {
          'id': 'trucker-1',
          'user_role_type': 'trucker',
          'verification_status': 'unverified',
        };
      final repository = VerificationRepository(backend, () => 'trucker-1');

      final result = await repository.saveDocumentPath(
        type: VerificationDocumentType.pan,
        storagePath: 'trucker-1/pan/pan.jpg',
      );

      expect(result.isSuccess, isTrue);
      expect(backend.lastProfileUpdate?['pan_document_path'], 'trucker-1/pan/pan.jpg');
      expect(backend.lastSupplierUpdate, isNull);
    });

    test('saveDocumentPath stores profile photo review document without updating avatar_url', () async {
      final backend = _FakeVerificationBackend()
        ..profileMap = {
          'id': 'trucker-1',
          'user_role_type': 'trucker',
          'verification_status': 'unverified',
          'avatar_url': 'trucker-1/avatar/current-approved.jpg',
        };
      final repository = VerificationRepository(backend, () => 'trucker-1');

      final result = await repository.saveDocumentPath(
        type: VerificationDocumentType.profilePhoto,
        storagePath: 'trucker-1/profile_photo/new-review-photo.jpg',
      );

      expect(result.isSuccess, isTrue);
      expect(backend.lastProfileUpdate?['profile_photo_document_path'], 'trucker-1/profile_photo/new-review-photo.jpg');
      expect(backend.lastProfileUpdate?.containsKey('avatar_url'), isFalse);
      expect(backend.lastSupplierUpdate, isNull);
    });

    test('submitForReview uses resubmission rpc when requested', () async {
      final backend = _FakeVerificationBackend();
      final repository = VerificationRepository(backend, () => 'profile-1');

      final result = await repository.submitForReview(isResubmission: true);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, 'case-2');
      expect(backend.resubmitCalled, isTrue);
      expect(backend.submitCalled, isFalse);
    });

    test('saveSupplierVerificationLocation updates supplier location fields', () async {
      final backend = _FakeVerificationBackend()
        ..profileMap = {
          'id': 'supplier-1',
          'user_role_type': 'supplier',
          'verification_status': 'unverified',
        };
      final repository = VerificationRepository(backend, () => 'supplier-1');

      final result = await repository.saveSupplierVerificationLocation(
        city: 'Mumbai',
        state: 'Maharashtra',
        latitude: 19.076,
        longitude: 72.8777,
      );

      expect(result.isSuccess, isTrue);
      expect(backend.lastSupplierUpdate?['verification_location_city'], 'Mumbai');
      expect(backend.lastSupplierUpdate?['verification_location_state'], 'Maharashtra');
      expect(backend.lastSupplierUpdate?['verification_location_lat'], 19.076);
      expect(backend.lastSupplierUpdate?['verification_location_lng'], 72.8777);
    });

    test('returns unauthorized without current user', () async {
      final repository = VerificationRepository(_FakeVerificationBackend(), () => null);

      final result = await repository.saveDocumentPath(
        type: VerificationDocumentType.pan,
        storagePath: 'profile-1/pan/pan.jpg',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });
  });
}
