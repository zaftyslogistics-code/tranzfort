part of 'verification_repository.dart';

class VerificationDetail {
  final String profileId;
  final AppUserRole role;
  final String verificationStatus;
  final String? rejectionReason;
  final String? aadhaarNumber;
  final String? aadhaarLast4;
  final String? aadhaarFrontDocumentPath;
  final String? aadhaarBackDocumentPath;
  final String? panNumber;
  final String? panLast4; // P0.7: Added panLast4 field
  final String? panDocumentPath;
  final String? profilePhotoDocumentPath;
  final String? businessLicenceNumber;
  final String? businessLicenceDocumentPath;
  final String? gstNumber;
  final String? gstCertificateDocumentPath;
  final int approvedTruckCount;
  final int verificationReadyTruckCount;
  final String? companyName;
  final String? verificationLocationCity;
  final String? verificationLocationState;
  final double? verificationLatitude;
  final double? verificationLongitude;
  final VerificationReviewFeedback reviewFeedback;

  const VerificationDetail({
    required this.profileId,
    required this.role,
    required this.verificationStatus,
    required this.rejectionReason,
    required this.aadhaarNumber,
    required this.aadhaarLast4,
    required this.aadhaarFrontDocumentPath,
    required this.aadhaarBackDocumentPath,
    required this.panNumber,
    required this.panLast4, // P0.7: Added panLast4 parameter
    required this.panDocumentPath,
    required this.profilePhotoDocumentPath,
    required this.businessLicenceNumber,
    required this.businessLicenceDocumentPath,
    required this.gstNumber,
    required this.gstCertificateDocumentPath,
    required this.approvedTruckCount,
    required this.verificationReadyTruckCount,
    required this.companyName,
    required this.verificationLocationCity,
    required this.verificationLocationState,
    required this.verificationLatitude,
    required this.verificationLongitude,
    required this.reviewFeedback,
  });

  bool get isPending => verificationStatus.trim().toLowerCase() == 'pending';
  bool get isVerified => verificationStatus.trim().toLowerCase() == 'verified';
  bool get isRejected => verificationStatus.trim().toLowerCase() == 'rejected';
  bool get isUnverified => verificationStatus.trim().toLowerCase() == 'unverified' || verificationStatus.trim().isEmpty;
  bool get isTrucker => role == AppUserRole.trucker;
  bool get isSupplier => role == AppUserRole.supplier;
  bool get hasApprovedTruckRequirement => !isTrucker || approvedTruckCount > 0;
  bool get hasVerificationReadyTruckRequirement => !isTrucker || verificationReadyTruckCount > 0;
  bool get hasSupplierCompanyName => !isSupplier || (companyName ?? '').trim().isNotEmpty;
  bool get hasIdentityNumbers => (aadhaarNumber ?? '').trim().isNotEmpty && (panNumber ?? '').trim().isNotEmpty;
  bool get hasSupplierBusinessNumbers => !isSupplier || (businessLicenceNumber ?? '').trim().isNotEmpty;
  bool get hasVerificationLocation =>
      (verificationLocationCity ?? '').trim().isNotEmpty && verificationLatitude != null && verificationLongitude != null;

  List<VerificationDocumentType> get visibleDocuments {
    if (isSupplier) {
      return const <VerificationDocumentType>[
        VerificationDocumentType.profilePhoto,
        VerificationDocumentType.aadhaarFront,
        VerificationDocumentType.aadhaarBack,
        VerificationDocumentType.pan,
        VerificationDocumentType.businessLicence,
        VerificationDocumentType.gstCertificate,
      ];
    }
    return const <VerificationDocumentType>[
      VerificationDocumentType.profilePhoto,
      VerificationDocumentType.aadhaarFront,
      VerificationDocumentType.aadhaarBack,
      VerificationDocumentType.pan,
    ];
  }

  bool isDocumentRequired(VerificationDocumentType type) {
    return switch (type) {
      VerificationDocumentType.aadhaarFront => true,
      VerificationDocumentType.aadhaarBack => true,
      VerificationDocumentType.pan => true,
      VerificationDocumentType.profilePhoto => false,
      VerificationDocumentType.businessLicence => isSupplier,
      VerificationDocumentType.gstCertificate => false,
      VerificationDocumentType.truckRc => false,
      VerificationDocumentType.truckPhoto => false,
    };
  }

  String? documentPathFor(VerificationDocumentType type) {
    return switch (type) {
      VerificationDocumentType.aadhaarFront => aadhaarFrontDocumentPath,
      VerificationDocumentType.aadhaarBack => aadhaarBackDocumentPath,
      VerificationDocumentType.pan => panDocumentPath,
      VerificationDocumentType.profilePhoto => profilePhotoDocumentPath,
      VerificationDocumentType.businessLicence => businessLicenceDocumentPath,
      VerificationDocumentType.gstCertificate => gstCertificateDocumentPath,
      VerificationDocumentType.truckRc => null,
      VerificationDocumentType.truckPhoto => null,
    };
  }

  bool isDocumentUploaded(VerificationDocumentType type) {
    return (documentPathFor(type) ?? '').trim().isNotEmpty;
  }

  bool get canSubmitForReview {
    if (isPending || isVerified) {
      return false;
    }
    if (!hasIdentityNumbers) {
      return false;
    }
    if (!hasSupplierCompanyName) {
      return false;
    }
    if (!hasSupplierBusinessNumbers) {
      return false;
    }
    for (final type in visibleDocuments) {
      if (isDocumentRequired(type) && !isDocumentUploaded(type)) {
        return false;
      }
    }
    if (isSupplier && !hasVerificationLocation) {
      return false;
    }
    return hasVerificationReadyTruckRequirement;
  }

  String? get submissionBlockedReason {
    if (isVerified) {
      return 'Verification is already complete.';
    }
    if (isPending) {
      return 'Verification is already under review.';
    }
    if (!hasIdentityNumbers) {
      return 'Enter your identity numbers before submitting verification.';
    }
    if (!hasSupplierCompanyName) {
      return 'Enter your company name before submitting supplier verification.';
    }
    if (!hasSupplierBusinessNumbers) {
      return 'Enter your business numbers before submitting supplier verification.';
    }
    for (final type in visibleDocuments) {
      if (isDocumentRequired(type) && !isDocumentUploaded(type)) {
        return 'Upload ${type.label.toLowerCase()} before submitting verification.';
      }
    }
    if (isSupplier && !hasVerificationLocation) {
      return 'Capture your verification location before submitting supplier verification.';
    }
    if (!hasVerificationReadyTruckRequirement) {
      return 'Add one truck with its RC document before submitting verification.';
    }
    return null;
  }

  factory VerificationDetail.fromMaps(
    Map<String, dynamic> profileMap,
    Map<String, dynamic>? supplierMap, {
    required int approvedTruckCount,
    required int verificationReadyTruckCount,
  }) {
    final rawRole = (profileMap['user_role_type'] ?? '').toString().trim().toLowerCase();
    final role = switch (rawRole) {
      'supplier' => AppUserRole.supplier,
      'trucker' => AppUserRole.trucker,
      _ => AppUserRole.unknown,
    };
    return VerificationDetail(
      profileId: (profileMap['id'] ?? '').toString(),
      role: role,
      verificationStatus: (profileMap['verification_status'] ?? 'unverified').toString(),
      rejectionReason: nullableString(profileMap['verification_rejection_reason']),
      // P0.7 Simplified: Full numbers no longer stored in profiles, set to empty
      aadhaarNumber: '', // Full number not stored anymore
      aadhaarLast4: nullableString(profileMap['aadhaar_last4']),
      aadhaarFrontDocumentPath: nullableString(profileMap['aadhaar_front_document_path']),
      aadhaarBackDocumentPath: nullableString(profileMap['aadhaar_back_document_path']),
      panNumber: '', // Full number not stored anymore
      panLast4: nullableString(profileMap['pan_last4']),
      panDocumentPath: nullableString(profileMap['pan_document_path']),
      profilePhotoDocumentPath: nullableString(profileMap['profile_photo_document_path']),
      businessLicenceNumber: nullableString(supplierMap?['business_licence_number']),
      businessLicenceDocumentPath: nullableString(supplierMap?['business_licence_document_path']),
      gstNumber: nullableString(supplierMap?['gst_number']),
      gstCertificateDocumentPath: nullableString(supplierMap?['gst_certificate_document_path']),
      approvedTruckCount: approvedTruckCount,
      verificationReadyTruckCount: verificationReadyTruckCount,
      companyName: nullableString(supplierMap?['company_name']),
      verificationLocationCity: nullableString(supplierMap?['verification_location_city']),
      verificationLocationState: nullableString(supplierMap?['verification_location_state']),
      verificationLatitude: readDouble(supplierMap?['verification_location_lat']),
      verificationLongitude: readDouble(supplierMap?['verification_location_lng']),
      reviewFeedback: VerificationReviewFeedback.fromJson(profileMap['verification_feedback_json']),
    );
  }

  static String? nullableString(Object? value) {
    final raw = (value ?? '').toString().trim();
    return raw.isEmpty ? null : raw;
  }

  static double? readDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}
