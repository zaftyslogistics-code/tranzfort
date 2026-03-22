part of 'supplier_trip_repository.dart';

class SupplierTrip {
  final String id;
  final String loadId;
  final String routeLabel;
  final String material;
  final String stage;
  final String truckerId;
  final String truckId;
  final DateTime assignedAt;
  final DateTime? deliveredAt;
  final DateTime? podUploadedAt;
  final DateTime? completedAt;
  final bool hasLrProof;
  final bool hasPodProof;

  const SupplierTrip({
    required this.id,
    required this.loadId,
    required this.routeLabel,
    required this.material,
    required this.stage,
    required this.truckerId,
    required this.truckId,
    required this.assignedAt,
    required this.deliveredAt,
    required this.podUploadedAt,
    required this.completedAt,
    required this.hasLrProof,
    required this.hasPodProof,
  });

  String get proofStatus {
    if (hasPodProof) {
      return 'POD uploaded';
    }
    if (hasLrProof) {
      return 'LR uploaded';
    }
    if (stage == 'delivered') {
      return 'Awaiting POD';
    }
    return 'Proof pending';
  }
}

class SupplierTripTrucker {
  final String id;
  final String fullName;
  final String verificationStatus;

  const SupplierTripTrucker({
    required this.id,
    required this.fullName,
    required this.verificationStatus,
  });
}

class SupplierTripRating {
  final String id;
  final int score;
  final String? comment;
  final DateTime createdAt;

  const SupplierTripRating({
    required this.id,
    required this.score,
    required this.comment,
    required this.createdAt,
  });
}

class SupplierTripDisputeSummary {
  final String category;
  final String status;
  final DateTime updatedAt;

  const SupplierTripDisputeSummary({
    required this.category,
    required this.status,
    required this.updatedAt,
  });
}

class SupplierTripDetail {
  final String id;
  final String loadId;
  final String routeLabel;
  final String material;
  final String stage;
  final String truckId;
  final String truckNumber;
  final String? truckBodyType;
  final int? truckTyres;
  final DateTime assignedAt;
  final DateTime? deliveredAt;
  final DateTime? podUploadedAt;
  final DateTime? completedAt;
  final String originLabel;
  final String destinationLabel;
  final double? routeDistanceKm;
  final int? routeDurationMinutes;
  final DateTime? pickupDate;
  final String? lrDocumentPath;
  final String? podDocumentPath;
  final String? lrSignedUrl;
  final String? podSignedUrl;
  final SupplierTripDisputeSummary? disputeSummary;
  final SupplierTripTrucker trucker;

  const SupplierTripDetail({
    required this.id,
    required this.loadId,
    required this.routeLabel,
    required this.material,
    required this.stage,
    required this.truckId,
    required this.truckNumber,
    required this.truckBodyType,
    required this.truckTyres,
    required this.assignedAt,
    required this.deliveredAt,
    required this.podUploadedAt,
    required this.completedAt,
    required this.originLabel,
    required this.destinationLabel,
    required this.routeDistanceKm,
    required this.routeDurationMinutes,
    required this.pickupDate,
    required this.lrDocumentPath,
    required this.podDocumentPath,
    required this.lrSignedUrl,
    required this.podSignedUrl,
    required this.disputeSummary,
    required this.trucker,
  });

  String get stageLabel => stage.replaceAll('_', ' ');
}

abstract class SupplierTripsBackend {
  Future<List<Map<String, dynamic>>> fetchTrips({
    required String supplierId,
    required List<String> stages,
  });

  Future<Map<String, dynamic>?> fetchTripDetail({
    required String supplierId,
    required String tripId,
  });

  Future<Map<String, dynamic>?> fetchTruckerProfile(String truckerId);

  Future<Map<String, dynamic>?> fetchOwnRating({
    required String reviewerId,
    required String loadId,
  });

  Future<void> submitRating({
    required String loadId,
    required int score,
    String? comment,
  });

  Future<String?> createProofSignedUrl(String path);

  Future<void> confirmTripDelivery(String tripId);

  Future<void> cancelTrip(String tripId);

  Future<Map<String, dynamic>?> fetchTripDisputeSummary({
    required String tripId,
  });

  Future<String> raiseTripDispute({
    required String tripId,
    required String category,
    required String reason,
    String? attachmentPath,
  });
}
