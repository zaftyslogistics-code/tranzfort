import '../../../core/utils/map_readers.dart';

class CreateLoadDto {
  final String originLabel;
  final String originCity;
  final String? originState;
  final double? originLat;
  final double? originLng;
  final String destinationLabel;
  final String destinationCity;
  final String? destinationState;
  final double? destinationLat;
  final double? destinationLng;
  final double? routeDistanceKm;
  final int? routeDurationMinutes;
  final String? routePolyline;
  final String? routeSnapshotSource;
  final String material;
  final double weightTonnes;
  final String? requiredBodyType;
  final List<int>? requiredTyres;
  final int trucksNeeded;
  final double priceAmount;
  final String priceType;
  final int? advancePercentage;
  final DateTime pickupDate;

  const CreateLoadDto({
    required this.originLabel,
    required this.originCity,
    required this.originState,
    required this.originLat,
    required this.originLng,
    required this.destinationLabel,
    required this.destinationCity,
    required this.destinationState,
    required this.destinationLat,
    required this.destinationLng,
    required this.routeDistanceKm,
    required this.routeDurationMinutes,
    required this.routePolyline,
    required this.routeSnapshotSource,
    required this.material,
    required this.weightTonnes,
    required this.requiredBodyType,
    required this.requiredTyres,
    required this.trucksNeeded,
    required this.priceAmount,
    required this.priceType,
    required this.advancePercentage,
    required this.pickupDate,
  });

  Map<String, dynamic> toRpcParams() {
    return {
      'p_origin_label': originLabel.trim(),
      'p_origin_city': originCity.trim(),
      'p_origin_state': nullableString(originState),
      'p_origin_lat': originLat,
      'p_origin_lng': originLng,
      'p_destination_label': destinationLabel.trim(),
      'p_destination_city': destinationCity.trim(),
      'p_destination_state': nullableString(destinationState),
      'p_destination_lat': destinationLat,
      'p_destination_lng': destinationLng,
      'p_route_distance_km': routeDistanceKm,
      'p_route_duration_minutes': routeDurationMinutes,
      'p_route_polyline': nullableString(routePolyline),
      'p_route_snapshot_source': nullableString(routeSnapshotSource),
      'p_material': material.trim(),
      'p_weight_tonnes': weightTonnes,
      'p_required_body_type': nullableString(requiredBodyType),
      'p_required_tyres': requiredTyres == null || requiredTyres!.isEmpty ? null : requiredTyres,
      'p_trucks_needed': trucksNeeded,
      'p_price_amount': priceAmount,
      'p_price_type': backendPriceType(priceType),
      'p_advance_percentage': advancePercentage,
      'p_pickup_date': pickupDate.toIso8601String().split('T').first,
    };
  }

  /// Feature flag: when true, 'per_ton' is sent directly to the backend RPC.
  /// When false (current default), 'per_ton' maps to 'negotiable' for legacy DB enum.
  ///
  /// Flip to true only after DB migration adds 'per_ton' to the price_type enum
  /// and the create_load RPC accepts it directly.
  static bool backendSupportsPerTonDirectly = false;

  /// Maps UI-facing price type to database enum value.
  ///
  /// Mapping contract:
  /// - `'per_ton'` → `'negotiable'` (legacy DB enum does not include 'per_ton')
  ///   when [backendSupportsPerTonDirectly] is false.
  /// - `'per_ton'` → `'per_ton'` (direct pass-through)
  ///   when [backendSupportsPerTonDirectly] is true.
  /// - `'fixed'` → `'fixed'` (direct pass-through)
  /// - `'negotiable'` → `'negotiable'` (direct pass-through for backward compatibility)
  static String backendPriceType(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'per_ton') {
      return backendSupportsPerTonDirectly ? 'per_ton' : 'negotiable';
    }
    return normalized;
  }

  /// Validates supported price type values (both UI-facing and DB-facing).
  ///
  /// Accepts: `'fixed'`, `'per_ton'` (UI-facing), `'negotiable'` (DB-facing).
  /// This allows backward compatibility with existing data that may use either value.
  static bool isSupportedPriceType(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'fixed' || normalized == 'per_ton' || normalized == 'negotiable';
  }
}

class LoadFilters {
  final List<String> statuses;
  final String? searchQuery;

  const LoadFilters({
    this.statuses = const [],
    this.searchQuery,
  });

  bool get hasStatuses => statuses.isNotEmpty;
  bool get hasSearchQuery => (searchQuery ?? '').trim().isNotEmpty;
}

class Load {
  final String id;
  final String originLabel;
  final String destinationLabel;
  final String material;
  final double weightTonnes;
  final int trucksNeeded;
  final int trucksBooked;
  final double priceAmount;
  final String priceType;
  final DateTime pickupDate;
  final String status;
  final String? requiredBodyType;
  final List<int> requiredTyres;
  final bool isSuperLoad;
  final String superStatus;
  final DateTime? publishedAt;

  const Load({
    required this.id,
    required this.originLabel,
    required this.destinationLabel,
    required this.material,
    required this.weightTonnes,
    required this.trucksNeeded,
    required this.trucksBooked,
    required this.priceAmount,
    required this.priceType,
    required this.pickupDate,
    required this.status,
    required this.requiredBodyType,
    required this.requiredTyres,
    required this.isSuperLoad,
    required this.superStatus,
    required this.publishedAt,
  });
}

class LoadDetail {
  final Load summary;
  final String originCity;
  final String? originState;
  final double? originLat;
  final double? originLng;
  final String destinationCity;
  final String? destinationState;
  final double? destinationLat;
  final double? destinationLng;
  final double? routeDistanceKm;
  final int? routeDurationMinutes;
  final String? routePolyline;
  final String? routeSnapshotSource;
  final String? parentLoadId;
  final String? assignedTruckerId;
  final String? assignedTruckId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LoadBookingRequest? bookingRequest;
  final List<LinkedTrip> linkedTrips;

  const LoadDetail({
    required this.summary,
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
    required this.routePolyline,
    required this.routeSnapshotSource,
    required this.parentLoadId,
    required this.assignedTruckerId,
    required this.assignedTruckId,
    required this.createdAt,
    required this.updatedAt,
    required this.bookingRequest,
    required this.linkedTrips,
  });

}

class LoadBookingRequest {
  final String id;
  final String loadId;
  final String truckerId;
  final String truckId;
  final String status;
  final String? decisionReason;
  final DateTime createdAt;
  final DateTime? decidedAt;
  final String? truckerName;
  final String? truckerVerificationStatus;
  final double? truckerRating;
  final String? truckerAvatarUrl;
  final String? truckNumber;
  final String? truckBodyType;
  final int? truckTyres;
  final String? truckModelLabel;

  const LoadBookingRequest({
    required this.id,
    required this.loadId,
    required this.truckerId,
    required this.truckId,
    required this.status,
    required this.decisionReason,
    required this.createdAt,
    required this.decidedAt,
    required this.truckerName,
    required this.truckerVerificationStatus,
    required this.truckerRating,
    this.truckerAvatarUrl,
    required this.truckNumber,
    required this.truckBodyType,
    required this.truckTyres,
    required this.truckModelLabel,
  });

  bool get isSubmitted => status == 'submitted';

  String get displayTruckerName => truckerName ?? 'Trucker ${truckerId.length > 8 ? truckerId.substring(0, 8) : truckerId}';

  String get displayTruckLabel {
    final number = truckNumber ?? 'Truck ${truckId.length > 8 ? truckId.substring(0, 8) : truckId}';
    final model = truckModelLabel;
    if (model != null) {
      return '$number - $model';
    }
    return number;
  }

  factory LoadBookingRequest.fromMap(Map<String, dynamic> map) {
    return LoadBookingRequest(
      id: (map['id'] ?? '').toString(),
      loadId: (map['load_id'] ?? '').toString(),
      truckerId: (map['trucker_id'] ?? '').toString(),
      truckId: (map['truck_id'] ?? '').toString(),
      status: (map['status'] ?? 'submitted').toString(),
      decisionReason: _nullableString(map['decision_reason']),
      createdAt: DateTime.parse((map['created_at'] ?? '').toString()),
      decidedAt: _readDateTime(map['decided_at']),
      truckerName: _nullableString(map['trucker_name']),
      truckerVerificationStatus: _nullableString(map['trucker_verification_status']),
      truckerRating: _readDouble(map['trucker_rating']),
      truckerAvatarUrl: _nullableString(map['trucker_avatar_url']),
      truckNumber: _nullableString(map['truck_number']),
      truckBodyType: _nullableString(map['truck_body_type']),
      truckTyres: LoadListItemDto._readInt(map['truck_tyres']) == 0 && map['truck_tyres'] == null
          ? null
          : LoadListItemDto._readInt(map['truck_tyres']),
      truckModelLabel: _nullableString(map['truck_model_label']),
    );
  }
}

class LinkedTrip {
  final String id;
  final String loadId;
  final String? parentLoadId;
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

  const LinkedTrip({
    required this.id,
    required this.loadId,
    required this.parentLoadId,
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

  factory LinkedTrip.fromMap(Map<String, dynamic> map) {
    final relatedLoad = map['loads'] is Map<String, dynamic>
        ? map['loads'] as Map<String, dynamic>
        : <String, dynamic>{};
    final origin = (relatedLoad['origin_label'] ?? map['origin_label'] ?? 'Load').toString();
    final destination = (relatedLoad['destination_label'] ?? map['destination_label'] ?? '').toString();
    final material = (relatedLoad['material'] ?? map['material'] ?? 'Material pending').toString();

    return LinkedTrip(
      id: (map['id'] ?? '').toString(),
      loadId: (map['load_id'] ?? '').toString(),
      parentLoadId: _nullableString(relatedLoad['parent_load_id']),
      routeLabel: destination.isEmpty ? origin : '$origin > $destination',
      material: material,
      stage: (map['stage'] ?? 'assigned').toString(),
      truckerId: (map['trucker_id'] ?? '').toString(),
      truckId: (map['truck_id'] ?? '').toString(),
      assignedAt: DateTime.parse((map['assigned_at'] ?? '').toString()),
      deliveredAt: _readDateTime(map['delivered_at']),
      podUploadedAt: _readDateTime(map['pod_uploaded_at']),
      completedAt: _readDateTime(map['completed_at']),
      hasLrProof: _nullableString(map['lr_document_path']) != null,
      hasPodProof: _nullableString(map['pod_document_path']) != null,
    );
  }
}

class LoadDetailDto {
  final LoadListItemDto summary;
  final String originCity;
  final String? originState;
  final double? originLat;
  final double? originLng;
  final String destinationCity;
  final String? destinationState;
  final double? destinationLat;
  final double? destinationLng;
  final num? routeDistanceKm;
  final int? routeDurationMinutes;
  final String? routePolyline;
  final String? routeSnapshotSource;
  final String? parentLoadId;
  final String? assignedTruckerId;
  final String? assignedTruckId;
  final String createdAt;
  final String updatedAt;

  const LoadDetailDto({
    required this.summary,
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
    required this.routePolyline,
    required this.routeSnapshotSource,
    required this.parentLoadId,
    required this.assignedTruckerId,
    required this.assignedTruckId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LoadDetailDto.fromMap(Map<String, dynamic> map) {
    return LoadDetailDto(
      summary: LoadListItemDto.fromMap(map),
      originCity: (map['origin_city'] ?? '').toString(),
      originState: map['origin_state']?.toString(),
      originLat: _readDouble(map['origin_lat']),
      originLng: _readDouble(map['origin_lng']),
      destinationCity: (map['destination_city'] ?? '').toString(),
      destinationState: map['destination_state']?.toString(),
      destinationLat: _readDouble(map['destination_lat']),
      destinationLng: _readDouble(map['destination_lng']),
      routeDistanceKm: _readDouble(map['route_distance_km']),
      routeDurationMinutes: LoadListItemDto._readInt(map['route_duration_minutes']) == 0 && map['route_duration_minutes'] == null
          ? null
          : LoadListItemDto._readInt(map['route_duration_minutes']),
      routePolyline: map['route_polyline']?.toString(),
      routeSnapshotSource: map['route_snapshot_source']?.toString(),
      parentLoadId: map['parent_load_id']?.toString(),
      assignedTruckerId: map['assigned_trucker_id']?.toString(),
      assignedTruckId: map['assigned_truck_id']?.toString(),
      createdAt: (map['created_at'] ?? '').toString(),
      updatedAt: (map['updated_at'] ?? '').toString(),
    );
  }

  LoadDetail toDomain() {
    return LoadDetail(
      summary: summary.toDomain(),
      originCity: originCity,
      originState: originState,
      originLat: originLat,
      originLng: originLng,
      destinationCity: destinationCity,
      destinationState: destinationState,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      routeDistanceKm: routeDistanceKm?.toDouble(),
      routeDurationMinutes: routeDurationMinutes,
      routePolyline: routePolyline,
      routeSnapshotSource: routeSnapshotSource,
      parentLoadId: parentLoadId,
      assignedTruckerId: assignedTruckerId,
      assignedTruckId: assignedTruckId,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      bookingRequest: null,
      linkedTrips: const [],
    );
  }

  static double? _readDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}

class LoadListItemDto {
  final String id;
  final String originLabel;
  final String destinationLabel;
  final String material;
  final num weightTonnes;
  final int trucksNeeded;
  final int trucksBooked;
  final num priceAmount;
  final String priceType;
  final String pickupDate;
  final String status;
  final String? requiredBodyType;
  final List<int> requiredTyres;
  final bool isSuperLoad;
  final String superStatus;
  final String? publishedAt;

  const LoadListItemDto({
    required this.id,
    required this.originLabel,
    required this.destinationLabel,
    required this.material,
    required this.weightTonnes,
    required this.trucksNeeded,
    required this.trucksBooked,
    required this.priceAmount,
    required this.priceType,
    required this.pickupDate,
    required this.status,
    required this.requiredBodyType,
    required this.requiredTyres,
    required this.isSuperLoad,
    required this.superStatus,
    required this.publishedAt,
  });

  factory LoadListItemDto.fromMap(Map<String, dynamic> map) {
    return LoadListItemDto(
      id: (map['id'] ?? '').toString(),
      originLabel: (map['origin_label'] ?? '').toString(),
      destinationLabel: (map['destination_label'] ?? '').toString(),
      material: (map['material'] ?? '').toString(),
      weightTonnes: (map['weight_tonnes'] ?? 0) as num,
      trucksNeeded: _readInt(map['trucks_needed']),
      trucksBooked: _readInt(map['trucks_booked']),
      priceAmount: (map['price_amount'] ?? 0) as num,
      priceType: _uiPriceType((map['price_type'] ?? 'negotiable').toString()),
      pickupDate: (map['pickup_date'] ?? '').toString(),
      status: (map['status'] ?? 'draft').toString(),
      requiredBodyType: map['required_body_type']?.toString(),
      requiredTyres: _readIntList(map['required_tyres']),
      isSuperLoad: map['is_super_load'] == true,
      superStatus: (map['super_status'] ?? 'none').toString(),
      publishedAt: map['published_at']?.toString(),
    );
  }

  Load toDomain() {
    return Load(
      id: id,
      originLabel: originLabel,
      destinationLabel: destinationLabel,
      material: material,
      weightTonnes: weightTonnes.toDouble(),
      trucksNeeded: trucksNeeded,
      trucksBooked: trucksBooked,
      priceAmount: priceAmount.toDouble(),
      priceType: priceType,
      pickupDate: DateTime.parse(pickupDate),
      status: status,
      requiredBodyType: requiredBodyType,
      requiredTyres: requiredTyres,
      isSuperLoad: isSuperLoad,
      superStatus: superStatus,
      publishedAt: publishedAt == null || publishedAt!.isEmpty ? null : DateTime.parse(publishedAt!),
    );
  }

  static String _uiPriceType(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'negotiable') {
      return 'per_ton';
    }
    return normalized;
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }

    return int.tryParse((value ?? '0').toString()) ?? 0;
  }

  static List<int> _readIntList(Object? value) {
    if (value is List) {
      return value.map((item) => int.tryParse(item.toString()) ?? 0).toList(growable: false);
    }

    return const [];
  }
}

String? _nullableString(Object? value) {
  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty) {
    return null;
  }
  return raw;
}

double? _readDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

DateTime? _readDateTime(Object? value) {
  final raw = _nullableString(value);
  if (raw == null) {
    return null;
  }
  return DateTime.parse(raw);
}
