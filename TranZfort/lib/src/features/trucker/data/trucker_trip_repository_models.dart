import '../../../core/constants/lifecycle_status_constants.dart';
import '../../../core/services/route_snapshot_service.dart';

class TruckerTrip {
  final String id;
  final String loadId;
  final String routeLabel;
  final String? originLabel;
  final String? destinationLabel;
  final double? originLat;
  final double? originLng;
  final double? destinationLat;
  final double? destinationLng;
  final String material;
  final String stage;
  final String truckId;
  final String truckNumber;
  final DateTime assignedAt;
  final DateTime? deliveredAt;
  final DateTime? podUploadedAt;
  final DateTime? completedAt;
  final bool hasLrProof;
  final bool hasPodProof;

  const TruckerTrip({
    required this.id,
    required this.loadId,
    required this.routeLabel,
    this.originLabel,
    this.destinationLabel,
    this.originLat,
    this.originLng,
    this.destinationLat,
    this.destinationLng,
    required this.material,
    required this.stage,
    required this.truckId,
    required this.truckNumber,
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
    if (stage == 'proof_submitted') {
      return 'Proof submitted';
    }
    return 'Proof pending';
  }

  String get timeContext {
    return switch (stage) {
      'completed' when completedAt != null => 'Completed ${_formatDate(completedAt!)}',
      'proof_submitted' when podUploadedAt != null => 'POD uploaded ${_formatDate(podUploadedAt!)}',
      'delivered' when deliveredAt != null => 'Delivered ${_formatDate(deliveredAt!)}',
      _ => 'Assigned ${_formatDate(assignedAt)}',
    };
  }

  String get stageLabel => stage.replaceAll('_', ' ');

  double get progressValue {
    final order = TripStages.progressOrder[stage] ?? 1;
    return (order / 7).clamp(0, 1).toDouble();
  }

  static String _formatDate(DateTime value) {
    final month = switch (value.month) {
      1 => 'Jan',
      2 => 'Feb',
      3 => 'Mar',
      4 => 'Apr',
      5 => 'May',
      6 => 'Jun',
      7 => 'Jul',
      8 => 'Aug',
      9 => 'Sep',
      10 => 'Oct',
      11 => 'Nov',
      12 => 'Dec',
      _ => '',
    };
    return '${value.day} $month ${value.year}';
  }
}

class TruckerTripSupplierSummary {
  final String id;
  final String fullName;
  final String? companyName;
  final String? mobile;
  final String verificationStatus;

  const TruckerTripSupplierSummary({
    required this.id,
    required this.fullName,
    required this.companyName,
    required this.mobile,
    required this.verificationStatus,
  });
}

class TruckerTripRating {
  final String id;
  final int score;
  final String? comment;
  final DateTime createdAt;

  const TruckerTripRating({
    required this.id,
    required this.score,
    required this.comment,
    required this.createdAt,
  });
}

class TruckerTripDisputeSummary {
  final String category;
  final String status;
  final DateTime updatedAt;

  const TruckerTripDisputeSummary({
    required this.category,
    required this.status,
    required this.updatedAt,
  });
}

class TruckerTripDetail {
  final String id;
  final String loadId;
  final String truckerId;
  final String supplierId;
  final String stage;
  final String routeLabel;
  final String material;
  final String truckId;
  final String truckNumber;
  final String? truckBodyType;
  final int? truckTyres;
  final String originLabel;
  final String destinationLabel;
  final String? originCity;
  final String? originState;
  final double? originLat;
  final double? originLng;
  final String? destinationCity;
  final String? destinationState;
  final double? destinationLat;
  final double? destinationLng;
  final double? routeDistanceKm;
  final int? routeDurationMinutes;
  final String? routeSnapshotSource;
  final DateTime? pickupDate;
  final DateTime assignedAt;
  final DateTime? startedAt;
  final DateTime? deliveredAt;
  final DateTime? podUploadedAt;
  final DateTime? completedAt;
  final bool hasLrProof;
  final bool hasPodProof;
  final TruckerTripDisputeSummary? disputeSummary;
  final TruckerTripSupplierSummary supplier;

  const TruckerTripDetail({
    required this.id,
    required this.loadId,
    required this.truckerId,
    required this.supplierId,
    required this.stage,
    required this.routeLabel,
    required this.material,
    required this.truckId,
    required this.truckNumber,
    required this.truckBodyType,
    required this.truckTyres,
    required this.originLabel,
    required this.destinationLabel,
    required this.originCity,
    required this.originState,
    required this.originLat,
    required this.originLng,
    required this.destinationCity,
    required this.destinationState,
    required this.destinationLat,
    required this.destinationLng,
    required this.routeDistanceKm,
    required this.routeDurationMinutes,
    required this.routeSnapshotSource,
    required this.pickupDate,
    required this.assignedAt,
    required this.startedAt,
    required this.deliveredAt,
    required this.podUploadedAt,
    required this.completedAt,
    required this.hasLrProof,
    required this.hasPodProof,
    required this.disputeSummary,
    required this.supplier,
  });

  String get stageLabel => stage.replaceAll('_', ' ');

  RouteSnapshot? get routeSnapshot {
    if (routeDistanceKm == null || routeDurationMinutes == null) {
      return null;
    }
    return RouteSnapshot.fromStoredFields(
      distanceKm: routeDistanceKm,
      durationMinutes: routeDurationMinutes,
      source: routeSnapshotSource,
    );
  }

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
    if (stage == 'proof_submitted') {
      return 'Proof submitted';
    }
    return 'Proof pending';
  }

  double get progressValue {
    return TruckerTrip(
      id: id,
      loadId: loadId,
      routeLabel: routeLabel,
      originLabel: originLabel,
      destinationLabel: destinationLabel,
      originLat: originLat,
      originLng: originLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      material: material,
      stage: stage,
      truckId: truckId,
      truckNumber: truckNumber,
      assignedAt: assignedAt,
      deliveredAt: deliveredAt,
      podUploadedAt: podUploadedAt,
      completedAt: completedAt,
      hasLrProof: hasLrProof,
      hasPodProof: hasPodProof,
    ).progressValue;
  }
}

abstract class TruckerTripsBackend {
  Future<List<Map<String, dynamic>>> fetchTrips({
    required String truckerId,
    required List<String> stages,
    int limit = 15,
    int offset = 0,
  });

  Future<Map<String, dynamic>?> fetchTripDetail({
    required String truckerId,
    required String tripId,
  });

  /// Consolidated RPC that fetches trip detail with supplier data in single call
  Future<Map<String, dynamic>?> fetchTripDetailWithSupplier({
    required String truckerId,
    required String tripId,
  });

  Future<void> advanceTripStage({
    required String tripId,
    required String newStage,
    double? gpsLat,
    double? gpsLng,
  });

  Future<void> uploadTripProof({
    required String tripId,
    required String podPath,
    String? lrPath,
    double? gpsLat,
    double? gpsLng,
  });

  Future<Map<String, dynamic>?> uploadTripLr({
    required String tripId,
    required String lrPath,
  });

  Future<Map<String, dynamic>?> fetchOwnRating({
    required String reviewerId,
    required String loadId,
  });

  Future<void> submitRating({
    required String loadId,
    required int score,
    String? comment,
  });

  Future<Map<String, dynamic>?> fetchSupplierProfile(String supplierId);

  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId);

  Future<Map<String, dynamic>?> fetchTripDisputeSummary({
    required String tripId,
  });
}
