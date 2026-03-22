part of 'verification_repository.dart';

class VerificationDocumentReviewFeedback {
  final String status;
  final String? reason;

  const VerificationDocumentReviewFeedback({
    required this.status,
    required this.reason,
  });

  bool get isRejected => status.trim().toLowerCase() == 'rejected';
}

class VerificationReviewFeedback {
  final String? summary;
  final String? nextStep;
  final Map<VerificationDocumentType, VerificationDocumentReviewFeedback> documents;

  const VerificationReviewFeedback({
    required this.summary,
    required this.nextStep,
    required this.documents,
  });

  bool get hasDocumentFeedback => documents.isNotEmpty;

  VerificationDocumentReviewFeedback? feedbackFor(VerificationDocumentType type) {
    return documents[type];
  }

  factory VerificationReviewFeedback.fromJson(Object? raw) {
    if (raw is! Map) {
      return const VerificationReviewFeedback(
        summary: null,
        nextStep: null,
        documents: <VerificationDocumentType, VerificationDocumentReviewFeedback>{},
      );
    }

    final map = raw.map((key, value) => MapEntry(key.toString(), value));
    final documentsRaw = map['documents'];
    final documents = <VerificationDocumentType, VerificationDocumentReviewFeedback>{};
    if (documentsRaw is Map) {
      for (final entry in documentsRaw.entries) {
        final type = VerificationDocumentTypeX.fromBackendKey(entry.key.toString());
        final value = entry.value;
        if (type == null || value is! Map) {
          continue;
        }
        final feedbackMap = value.map((key, value) => MapEntry(key.toString(), value));
        documents[type] = VerificationDocumentReviewFeedback(
          status: (feedbackMap['status'] ?? 'rejected').toString(),
          reason: VerificationDetail.nullableString(feedbackMap['reason']),
        );
      }
    }

    return VerificationReviewFeedback(
      summary: VerificationDetail.nullableString(map['summary']),
      nextStep: VerificationDetail.nullableString(map['next_step']),
      documents: Map.unmodifiable(documents),
    );
  }
}

enum VerificationDocumentType {
  aadhaarFront,
  aadhaarBack,
  pan,
  profilePhoto,
  businessLicence,
  gstCertificate,
}

extension VerificationDocumentTypeX on VerificationDocumentType {
  String get label {
    return switch (this) {
      VerificationDocumentType.aadhaarFront => 'Aadhaar front',
      VerificationDocumentType.aadhaarBack => 'Aadhaar back',
      VerificationDocumentType.pan => 'PAN card',
      VerificationDocumentType.profilePhoto => 'Profile photo',
      VerificationDocumentType.businessLicence => 'Business licence',
      VerificationDocumentType.gstCertificate => 'GST certificate',
    };
  }

  String get backendKey {
    return switch (this) {
      VerificationDocumentType.aadhaarFront => 'aadhaar_front',
      VerificationDocumentType.aadhaarBack => 'aadhaar_back',
      VerificationDocumentType.pan => 'pan',
      VerificationDocumentType.profilePhoto => 'profile_photo',
      VerificationDocumentType.businessLicence => 'business_licence',
      VerificationDocumentType.gstCertificate => 'gst_certificate',
    };
  }

  static VerificationDocumentType? fromBackendKey(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'aadhaar_front' => VerificationDocumentType.aadhaarFront,
      'aadhaar_back' => VerificationDocumentType.aadhaarBack,
      'pan' => VerificationDocumentType.pan,
      'profile_photo' => VerificationDocumentType.profilePhoto,
      'business_licence' => VerificationDocumentType.businessLicence,
      'gst_certificate' => VerificationDocumentType.gstCertificate,
      _ => null,
    };
  }
}
