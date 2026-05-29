import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/features/verification/data/verification_document_upload_service.dart';
import 'package:tranzfort/src/features/verification/data/verification_location_service.dart';
import 'package:tranzfort/src/features/verification/data/verification_repository.dart';
import 'package:tranzfort/src/features/verification/providers/verification_provider.dart';

class _MutableVerificationBackend implements VerificationBackend {
  Map<String, dynamic> profileMap = {
    'id': 'trucker-1',
    'user_role_type': 'trucker',
    'verification_status': 'unverified',
    'verification_rejection_reason': null,
    'aadhaar_number': null,
    'aadhaar_last4': null,
    'pan_number': null,
    'aadhaar_front_document_path': null,
    'aadhaar_back_document_path': null,
    'pan_document_path': null,
    'profile_photo_document_path': null,
  };
  Map<String, dynamic>? supplierMap;
  int approvedTruckCount = 1;
  int verificationReadyTruckCount = 1;

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
    profileMap = {
      ...profileMap,
      'verification_status': 'pending',
      'verification_rejection_reason': null,
    };
    return 'case-2';
  }

  @override
  Future<String> submitVerificationForReview() async {
    profileMap = {
      ...profileMap,
      'verification_status': 'pending',
      'verification_rejection_reason': null,
    };
    return 'case-1';
  }

  @override
  Future<void> updateProfileFields(String userId, Map<String, dynamic> values) async {
    profileMap = {...profileMap, ...values};
  }

  @override
  Future<void> updateSupplierFields(String userId, Map<String, dynamic> values) async {
    supplierMap = {
      'id': userId,
      ...?supplierMap,
      ...values,
    };
  }
}

class _FakeVerificationUploadService extends VerificationDocumentUploadService {
  final String? storagePath;

  _FakeVerificationUploadService({required this.storagePath}) : super(null);

  @override
  Future<Result<String?>> pickCompressAndUploadDocument({
    required String profileId,
    required VerificationDocumentType type,
    required ImageSource source,
  }) async {
    return Success<String?>(storagePath);
  }
}

class _FakeVerificationLocationService extends VerificationLocationService {
  final VerificationLocation? location;

  _FakeVerificationLocationService({required this.location});

  @override
  Future<VerificationLocation?> captureSupplierVerificationLocation() async {
    return location;
  }
}

void _ignoreVerificationInvalidation(VerificationDetail? detail) {}

void main() {
  group('VerificationController', () {
    test('uploads a document and refreshes verification detail', () async {
      final backend = _MutableVerificationBackend();
      final controller = VerificationController(
        _ignoreVerificationInvalidation,
        VerificationRepository(backend, () => 'trucker-1'),
        _FakeVerificationUploadService(storagePath: 'trucker-1/pan/pan.jpg'),
        _FakeVerificationLocationService(location: null),
      );

      await Future<void>.delayed(Duration.zero);
      final result = await controller.uploadDocument(
        type: VerificationDocumentType.pan,
        source: ImageSource.gallery,
      );

      expect(result.isSuccess, isTrue);
      expect(controller.state.detail?.panDocumentPath, 'trucker-1/pan/pan.jpg');
      expect(controller.state.uploadingDocumentType, isNull);
    });

    test('submits verification and refreshes pending state', () async {
      final backend = _MutableVerificationBackend()
        ..profileMap = {
          'id': 'trucker-1',
          'user_role_type': 'trucker',
          'verification_status': 'unverified',
          'verification_rejection_reason': null,
          'aadhaar_number': '123412341234',
          'aadhaar_last4': '1234',
          'pan_number': 'ABCDE1234F',
          'aadhaar_front_document_path': 'trucker-1/aadhaar_front/aadhaar_front.jpg',
          'aadhaar_back_document_path': 'trucker-1/aadhaar_back/aadhaar_back.jpg',
          'pan_document_path': 'trucker-1/pan/pan.jpg',
          'profile_photo_document_path': 'trucker-1/profile_photo/profile_photo.jpg',
        }
        ..approvedTruckCount = 0
        ..verificationReadyTruckCount = 1;
      final controller = VerificationController(
        _ignoreVerificationInvalidation,
        VerificationRepository(backend, () => 'trucker-1'),
        _FakeVerificationUploadService(storagePath: null),
        _FakeVerificationLocationService(location: null),
      );

      await Future<void>.delayed(Duration.zero);
      final result = await controller.submitForReview();

      expect(result.isSuccess, isTrue);
      expect(controller.state.detail?.verificationStatus, 'pending');
      expect(controller.state.detail?.approvedTruckCount, 0);
      expect(controller.state.detail?.verificationReadyTruckCount, 1);
      expect(controller.state.isSubmitting, isFalse);
    });

    test('saves verification packet fields and refreshes detail', () async {
      final backend = _MutableVerificationBackend();
      final controller = VerificationController(
        _ignoreVerificationInvalidation,
        VerificationRepository(backend, () => 'trucker-1'),
        _FakeVerificationUploadService(storagePath: null),
        _FakeVerificationLocationService(location: null),
      );

      await Future<void>.delayed(Duration.zero);
      final result = await controller.saveVerificationPacketFields(
        aadhaarNumber: '123412341234',
        panNumber: 'abcde1234f',
      );

      expect(result.isSuccess, isTrue);
      expect(controller.state.detail?.aadhaarNumber, '123412341234');
      expect(controller.state.detail?.panNumber, 'ABCDE1234F');
    });

    test('saves supplier company name with verification packet fields and refreshes detail', () async {
      final backend = _MutableVerificationBackend()
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
          'company_name': null,
          'business_licence_number': 'BL-7788',
          'business_licence_document_path': 'supplier-1/business_licence/business_licence.jpg',
          'gst_certificate_document_path': null,
          'verification_location_city': 'Mumbai',
          'verification_location_state': 'Maharashtra',
          'verification_location_lat': 19.076,
          'verification_location_lng': 72.8777,
        };
      final controller = VerificationController(
        _ignoreVerificationInvalidation,
        VerificationRepository(backend, () => 'supplier-1'),
        _FakeVerificationUploadService(storagePath: null),
        _FakeVerificationLocationService(location: null),
      );

      await Future<void>.delayed(Duration.zero);
      final result = await controller.saveVerificationPacketFields(
        companyName: 'North Hub Logistics',
        aadhaarNumber: '123412341234',
        panNumber: 'abcde1234f',
        businessLicenceNumber: 'BL-7788',
        gstNumber: '27ABCDE1234F1Z5',
      );

      expect(result.isSuccess, isTrue);
      expect(controller.state.detail?.companyName, 'North Hub Logistics');
      expect(controller.state.detail?.gstNumber, '27ABCDE1234F1Z5');
    });

    test('captures supplier verification location and refreshes detail', () async {
      final backend = _MutableVerificationBackend()
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
          'gst_certificate_document_path': null,
          'verification_location_city': null,
          'verification_location_state': null,
          'verification_location_lat': null,
          'verification_location_lng': null,
        };
      final supplierBackend = backend;
      final controller = VerificationController(
        _ignoreVerificationInvalidation,
        VerificationRepository(supplierBackend, () => 'supplier-1'),
        _FakeVerificationUploadService(storagePath: null),
        _FakeVerificationLocationService(
          location: const VerificationLocation(
            city: 'Mumbai',
            state: 'Maharashtra',
            latitude: 19.076,
            longitude: 72.8777,
            source: 'test',
          ),
        ),
      );

      await Future<void>.delayed(Duration.zero);
      final result = await controller.captureSupplierLocation();

      expect(result.isSuccess, isTrue);
      expect(controller.state.detail?.verificationLocationCity, 'Mumbai');
      expect(controller.state.isCapturingLocation, isFalse);
    });
  });
}
