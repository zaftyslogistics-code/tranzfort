library;

/// Public profile models for viewing other users' profiles.
/// Plain Dart classes with fromMap factories (NOT freezed).

class PublicProfile {
  // Identity
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? companyName;
  final String? location;
  final String role;
  final DateTime? memberSince;

  // Verification
  final String verificationStatus;

  // Trust & Reviews
  final double avgRating;
  final int reviewCount;
  final int? completedTripsCount;

  // Role-specific
  final List<PublicTruckPreview>? fleet;
  final int? truckCount;
  final bool? isSuperLoadEligible;
  final int? totalLoadsPosted;
  final int? activeLoadsCount;

  // Self-only flag
  final bool isSelf;

  // Capability flags (returned by backend based on viewer relationship)
  final bool canViewContact;
  final bool canReview;
  final bool canMessage;

  const PublicProfile({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.companyName,
    this.location,
    required this.role,
    this.memberSince,
    required this.verificationStatus,
    required this.avgRating,
    required this.reviewCount,
    this.completedTripsCount,
    this.fleet,
    this.truckCount,
    this.isSuperLoadEligible,
    this.totalLoadsPosted,
    this.activeLoadsCount,
    required this.isSelf,
    this.canViewContact = false,
    this.canReview = false,
    this.canMessage = false,
  });

  factory PublicProfile.fromMap(Map<String, dynamic> map) {
    final trustScores = map['trust_scores'] is Map<String, dynamic>
        ? map['trust_scores'] as Map<String, dynamic>
        : <String, dynamic>{};

    final roleSpecific = map['role_specific'] is Map<String, dynamic>
        ? map['role_specific'] as Map<String, dynamic>
        : <String, dynamic>{};

    final fleetList = roleSpecific['fleet'] is List
        ? (roleSpecific['fleet'] as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    final avatarUrl = _nullableString(map['avatar_url']);
    final profilePhotoPath = _nullableString(map['profile_photo_document_path']);

    return PublicProfile(
      id: (map['id'] ?? '').toString(),
      fullName: (map['full_name'] ?? '').toString(),
      avatarUrl: avatarUrl ?? profilePhotoPath,
      companyName: _nullableString(map['company_name']),
      location: _nullableString(map['location']),
      role: (map['role'] ?? '').toString(),
      memberSince: _readDateTime(map['member_since']),
      verificationStatus: (map['verification_status'] ?? 'unverified').toString(),
      avgRating: _readDoubleNullable(trustScores['avg_rating']) ?? 0,
      reviewCount: _readInt(trustScores['review_count']),
      completedTripsCount: _readIntNullable(roleSpecific['completed_trips_count']),
      fleet: fleetList.isEmpty
          ? null
          : fleetList.map(PublicTruckPreview.fromMap).toList(growable: false),
      truckCount: _readIntNullable(roleSpecific['truck_count']),
      isSuperLoadEligible: roleSpecific['is_super_load_eligible'] == true,
      totalLoadsPosted: _readIntNullable(roleSpecific['total_loads_posted']),
      activeLoadsCount: _readIntNullable(roleSpecific['active_loads_count']),
      isSelf: map['is_self'] == true,
      canViewContact: map['can_view_contact'] == true,
      canReview: map['can_review'] == true,
      canMessage: map['can_message'] == true,
    );
  }

  /// Whether this user has any reviews yet.
  bool get hasReviews => reviewCount > 0 && avgRating > 0;

  /// Whether this user is a new trucker (< 5 completed trips).
  bool get isNewTrucker => role == 'trucker' && (completedTripsCount ?? 0) < 5;

  /// Whether this user is a new supplier (< 5 total loads posted).
  bool get isNewSupplier => role == 'supplier' && (totalLoadsPosted ?? 0) < 5;

  /// Display name for the profile header.
  String get displayName {
    if (companyName != null && companyName!.isNotEmpty) {
      return companyName!;
    }
    return fullName;
  }

  /// Display location or fallback.
  String get displayLocation {
    return location ?? 'Location not set';
  }

  /// Verification badge text.
  String get verificationBadge {
    return switch (verificationStatus) {
      'verified' => 'Verified',
      'pending' => 'Pending',
      'rejected' => 'Rejected',
      _ => 'Unverified',
    };
  }

  /// Role-specific badge text.
  String? get newUserBadge {
    if (role == 'trucker' && isNewTrucker) {
      return 'New Trucker';
    }
    if (role == 'supplier' && isNewSupplier) {
      return 'New Supplier';
    }
    return null;
  }
}

class PublicTruckPreview {
  final String id;
  final String truckNumber;
  final String bodyType;
  final int tyres;
  final double capacityTonnes;
  final String status;

  const PublicTruckPreview({
    required this.id,
    required this.truckNumber,
    required this.bodyType,
    required this.tyres,
    required this.capacityTonnes,
    required this.status,
  });

  factory PublicTruckPreview.fromMap(Map<String, dynamic> map) {
    return PublicTruckPreview(
      id: (map['id'] ?? '').toString(),
      truckNumber: (map['truck_number'] ?? '').toString(),
      bodyType: (map['body_type'] ?? '').toString(),
      tyres: _readInt(map['tyres']),
      capacityTonnes: _readDoubleNullable(map['capacity_tonnes']) ?? 0,
      status: (map['status'] ?? '').toString(),
    );
  }
}

class PublicLoadPreview {
  final String id;
  final String originCity;
  final String destinationCity;
  final String material;
  final double weightTonnes;
  final double priceAmount;
  final String priceType;
  final DateTime pickupDate;
  final String status;

  const PublicLoadPreview({
    required this.id,
    required this.originCity,
    required this.destinationCity,
    required this.material,
    required this.weightTonnes,
    required this.priceAmount,
    required this.priceType,
    required this.pickupDate,
    required this.status,
  });

  factory PublicLoadPreview.fromMap(Map<String, dynamic> map) {
    return PublicLoadPreview(
      id: (map['id'] ?? '').toString(),
      originCity: (map['origin_city'] ?? '').toString(),
      destinationCity: (map['destination_city'] ?? '').toString(),
      material: (map['material'] ?? '').toString(),
      weightTonnes: _readDoubleNullable(map['weight_tonnes']) ?? 0,
      priceAmount: _readDoubleNullable(map['price_amount']) ?? 0,
      priceType: (map['price_type'] ?? 'fixed').toString(),
      pickupDate: _readDateTime(map['pickup_date']) ?? DateTime.now(),
      status: (map['status'] ?? '').toString(),
    );
  }

  String get routeLabel => '$originCity to $destinationCity';
}

// Private helper functions

String? _nullableString(Object? value) {
  final raw = (value ?? '').toString().trim();
  return raw.isEmpty ? null : raw;
}

double? _readDoubleNullable(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int _readInt(Object? value) {
  if (value is int) return value;
  return int.tryParse((value ?? '0').toString()) ?? 0;
}

int? _readIntNullable(Object? value) {
  if (value == null) return null;
  return _readInt(value);
}

DateTime? _readDateTime(Object? value) {
  final raw = _nullableString(value);
  if (raw == null) return null;
  return DateTime.tryParse(raw);
}
