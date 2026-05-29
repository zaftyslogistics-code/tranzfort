import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_fleet_repository.dart';
import 'package:tranzfort/src/features/verification/data/verification_repository.dart';
import 'package:tranzfort/src/features/verification/providers/verification_fleet_ready_match.dart';
import 'package:tranzfort/src/features/verification/providers/verification_resubmission.dart';
import 'package:tranzfort/src/features/verification/providers/verification_wizard_draft.dart';
import 'package:tranzfort/src/features/verification/providers/verification_wizard_provider.dart';
import 'package:tranzfort/src/features/verification/providers/verification_wizard_validation_helper.dart';

void main() {
  group('VerificationDraft', () {
    test('copyWith(clearProfilePhoto: true) clears profile photo path', () {
      const draft = VerificationDraft(profilePhotoPath: 'user/photo.jpg');
      final cleared = draft.copyWith(clearProfilePhoto: true);
      expect(cleared.profilePhotoPath, isNull);
    });

    test('TruckDraft copyWith(clearRcDocument: true) clears RC path', () {
      const truck = TruckDraft(rcDocumentPath: 'user/rc.pdf');
      final cleared = truck.copyWith(clearRcDocument: true);
      expect(cleared.rcDocumentPath, isNull);
    });
  });

  group('VerificationWizardValidationHelper', () {
    test('terms not accepted fails submit validation', () {
      final helper = VerificationWizardValidationHelper(role: AppUserRole.trucker);
      final draft = VerificationDraft(
        profilePhotoPath: 'photo.jpg',
        aadhaarNumber: '123456789012',
        panNumber: 'ABCDE1234F',
        aadhaarFrontPath: 'front.jpg',
        aadhaarBackPath: 'back.jpg',
        panDocumentPath: 'pan.jpg',
        truck: const TruckDraft(
          truckNumber: 'MH12AB1234',
          capacityTonnes: 16,
          rcDocumentPath: 'rc.pdf',
        ),
      );

      final result = helper.validateAll(draft, termsAccepted: false);
      expect(result.isValid, isFalse);
      expect(result.fieldErrors['terms'], isNotEmpty);
    });
  });

  group('mapRepositoryFieldKeyToWizard', () {
    test('maps rc_document_path to rcDocument wizard key', () {
      expect(mapRepositoryFieldKeyToWizard('rc_document_path'), 'rcDocument');
      expect(mapRepositoryFieldKeyToWizard('truck_rc_document_path'), 'rcDocument');
    });

    test('maps ValidationFailure field errors onto wizard keys', () {
      final mapped = mapRepositoryFailureToWizardFields(
        const ValidationFailure(
          message: 'RC invalid',
          fieldErrors: {'rc_document_path': 'Upload a clearer RC photo'},
        ),
        wizardFieldKey: 'review',
      );
      expect(mapped['rcDocument'], 'Upload a clearer RC photo');
    });
  });

  group('fleetHasReadyTruckForDraft', () {
    test('returns true when fleet already has matching ready truck', () {
      final draft = const TruckDraft(
        truckNumber: 'mh12ab1234',
        capacityTonnes: 16,
        rcDocumentPath: 'rc.pdf',
      );
      final trucks = [
        TruckerFleetTruck(
          id: 'truck-1',
          truckModelId: null,
          truckNumber: 'MH12AB1234',
          bodyType: 'open',
          tyres: 10,
          capacityTonnes: 16,
          rcDocumentPath: 'fleet/rc.pdf',
          status: TruckerFleetTruckStatus.verified,
          rejectionReason: null,
          reviewFeedback: const TruckerFleetReviewFeedback(summary: null, nextStep: null),
          modelLabel: null,
          verifiedAt: null,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];

      expect(fleetHasReadyTruckForDraft(trucks: trucks, draft: draft), isTrue);
    });

    test('returns false when truck number differs', () {
      final draft = const TruckDraft(
        truckNumber: 'MH99ZZ9999',
        capacityTonnes: 16,
        rcDocumentPath: 'rc.pdf',
      );
      final trucks = [
        TruckerFleetTruck(
          id: 'truck-1',
          truckModelId: null,
          truckNumber: 'MH12AB1234',
          bodyType: 'open',
          tyres: 10,
          capacityTonnes: 16,
          rcDocumentPath: 'fleet/rc.pdf',
          status: TruckerFleetTruckStatus.verified,
          rejectionReason: null,
          reviewFeedback: const TruckerFleetReviewFeedback(summary: null, nextStep: null),
          modelLabel: null,
          verifiedAt: null,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];

      expect(fleetHasReadyTruckForDraft(trucks: trucks, draft: draft), isFalse);
    });
  });

  group('isVerificationResubmission', () {
    test('rejected status enables wizard resubmission mode', () {
      expect(isVerificationResubmission('rejected'), isTrue);
      expect(isVerificationResubmission(' REJECTED '), isTrue);
      expect(isVerificationResubmission('pending'), isFalse);
    });

    test('rejected VerificationDetail aligns with resubmission helper', () {
      final detail = _rejectedTruckerDetail();
      expect(detail.isRejected, isTrue);
      expect(isVerificationResubmission(detail.verificationStatus), isTrue);
    });
  });
}

VerificationDetail _rejectedTruckerDetail() {
  return const VerificationDetail(
    profileId: 'user-1',
    role: AppUserRole.trucker,
    verificationStatus: 'rejected',
    rejectionReason: 'RC unclear',
    aadhaarNumber: null,
    aadhaarLast4: null,
    aadhaarFrontDocumentPath: null,
    aadhaarBackDocumentPath: null,
    panNumber: null,
    panLast4: null,
    panDocumentPath: null,
    profilePhotoDocumentPath: null,
    businessLicenceNumber: null,
    businessLicenceDocumentPath: null,
    gstNumber: null,
    gstCertificateDocumentPath: null,
    approvedTruckCount: 0,
    verificationReadyTruckCount: 0,
    companyName: null,
    verificationLocationCity: null,
    verificationLocationState: null,
    verificationLatitude: null,
    verificationLongitude: null,
    reviewFeedback: VerificationReviewFeedback(
      summary: null,
      nextStep: null,
      documents: {},
    ),
  );
}
