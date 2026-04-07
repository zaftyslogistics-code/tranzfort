enum SuperOpsTab { requests, dispatch, podReview, completed }

String superOpsTabStatus(SuperOpsTab tab) {
  switch (tab) {
    case SuperOpsTab.requests:
      return 'pending_approval';
    case SuperOpsTab.dispatch:
      return 'processing';
    case SuperOpsTab.podReview:
      return 'pod_review';
    case SuperOpsTab.completed:
      return 'completed';
  }
}

class SuperOpsQueueQuery {
  final SuperOpsTab tab;
  final String search;

  const SuperOpsQueueQuery({required this.tab, required this.search});

  @override
  bool operator ==(Object other) {
    return other is SuperOpsQueueQuery &&
        other.tab == tab &&
        other.search == search;
  }

  @override
  int get hashCode => Object.hash(tab, search);
}

class SuperOpsQueueCounts {
  final int requests;
  final int dispatch;
  final int podReview;
  final int completed;

  const SuperOpsQueueCounts({
    this.requests = 0,
    this.dispatch = 0,
    this.podReview = 0,
    this.completed = 0,
  });
}

class SuperOpsLoadSummary {
  final String id;
  final String routeLabel;
  final String material;
  final double weightTonnes;
  final double price;
  final String requiredTruckType;
  final int trucksNeeded;
  final int trucksBooked;
  final String supplierName;
  final String status;
  final String superStatus;
  final DateTime? pickupDate;
  final DateTime? createdAt;

  const SuperOpsLoadSummary({
    required this.id,
    required this.routeLabel,
    required this.material,
    required this.weightTonnes,
    required this.price,
    required this.requiredTruckType,
    required this.trucksNeeded,
    required this.trucksBooked,
    required this.supplierName,
    required this.status,
    required this.superStatus,
    required this.pickupDate,
    required this.createdAt,
  });
}

class SuperOpsLoadDetail {
  final String id;
  final String routeLabel;
  final double? originLat;
  final double? originLng;
  final String material;
  final double weightTonnes;
  final double price;
  final String priceType;
  final int advancePercentage;
  final DateTime? pickupDate;
  final String requiredTruckType;
  final List<int> requiredTyres;
  final int trucksNeeded;
  final int trucksBooked;
  final String status;
  final String superStatus;
  final String podPhotoUrl;
  final String lrPhotoUrl;
  final DateTime? createdAt;
  final SuperOpsSupplierInfo supplier;
  final SuperOpsPayoutInfo payout;
  final List<SuperOpsAssignmentSummary> assignments;

  const SuperOpsLoadDetail({
    required this.id,
    required this.routeLabel,
    required this.originLat,
    required this.originLng,
    required this.material,
    required this.weightTonnes,
    required this.price,
    required this.priceType,
    required this.advancePercentage,
    required this.pickupDate,
    required this.requiredTruckType,
    required this.requiredTyres,
    required this.trucksNeeded,
    required this.trucksBooked,
    required this.status,
    required this.superStatus,
    required this.podPhotoUrl,
    required this.lrPhotoUrl,
    required this.createdAt,
    required this.supplier,
    required this.payout,
    required this.assignments,
  });
}

class SuperOpsSupplierInfo {
  final String id;
  final String fullName;
  final String companyName;
  final String mobile;
  final String email;
  final String verificationStatus;
  final String gstNumber;

  const SuperOpsSupplierInfo({
    required this.id,
    required this.fullName,
    required this.companyName,
    required this.mobile,
    required this.email,
    required this.verificationStatus,
    required this.gstNumber,
  });
}

class SuperOpsPayoutInfo {
  final String accountHolderName;
  final String accountNumberLast4;
  final String ifscCode;
  final String bankName;
  final String status;

  const SuperOpsPayoutInfo({
    required this.accountHolderName,
    required this.accountNumberLast4,
    required this.ifscCode,
    required this.bankName,
    required this.status,
  });
}

class SuperOpsAssignmentSummary {
  final String childLoadId;
  final String truckerId;
  final String truckerName;
  final String truckId;
  final String truckNumber;

  const SuperOpsAssignmentSummary({
    required this.childLoadId,
    required this.truckerId,
    required this.truckerName,
    required this.truckId,
    required this.truckNumber,
  });
}

class DispatchTruckerCandidate {
  final String truckerId;
  final String truckerName;
  final String mobile;
  final double rating;
  final int completedTrips;
  final String superTruckerStatus;
  final double? lastKnownLat;
  final double? lastKnownLng;
  final double? distanceKm;
  final List<DispatchTruckOption> trucks;
  final bool isFallbackMatch;

  const DispatchTruckerCandidate({
    required this.truckerId,
    required this.truckerName,
    required this.mobile,
    required this.rating,
    required this.completedTrips,
    required this.superTruckerStatus,
    this.lastKnownLat,
    this.lastKnownLng,
    this.distanceKm,
    required this.trucks,
    this.isFallbackMatch = false,
  });

  DispatchTruckerCandidate copyWith({
    String? truckerId,
    String? truckerName,
    String? mobile,
    double? rating,
    int? completedTrips,
    String? superTruckerStatus,
    double? lastKnownLat,
    double? lastKnownLng,
    double? distanceKm,
    bool clearDistance = false,
    List<DispatchTruckOption>? trucks,
    bool? isFallbackMatch,
  }) {
    return DispatchTruckerCandidate(
      truckerId: truckerId ?? this.truckerId,
      truckerName: truckerName ?? this.truckerName,
      mobile: mobile ?? this.mobile,
      rating: rating ?? this.rating,
      completedTrips: completedTrips ?? this.completedTrips,
      superTruckerStatus: superTruckerStatus ?? this.superTruckerStatus,
      lastKnownLat: lastKnownLat ?? this.lastKnownLat,
      lastKnownLng: lastKnownLng ?? this.lastKnownLng,
      distanceKm: clearDistance ? null : (distanceKm ?? this.distanceKm),
      trucks: trucks ?? this.trucks,
      isFallbackMatch: isFallbackMatch ?? this.isFallbackMatch,
    );
  }
}

class DispatchTruckOption {
  final String id;
  final String truckNumber;
  final String bodyType;
  final int tyres;

  const DispatchTruckOption({
    required this.id,
    required this.truckNumber,
    required this.bodyType,
    required this.tyres,
  });
}

class SuperOpsSupplierOption {
  final String supplierId;
  final String supplierName;
  final String mobile;
  final String companyName;

  const SuperOpsSupplierOption({
    required this.supplierId,
    required this.supplierName,
    required this.mobile,
    required this.companyName,
  });
}

class SuperOpsPostLoadPayload {
  final String supplierId;
  final String originCity;
  final String originState;
  final String destCity;
  final String destState;
  final String material;
  final double weightTonnes;
  final String requiredTruckType;
  final int trucksNeeded;
  final double price;
  final String priceType;
  final int advancePercentage;
  final DateTime pickupDate;

  const SuperOpsPostLoadPayload({
    required this.supplierId,
    required this.originCity,
    required this.originState,
    required this.destCity,
    required this.destState,
    required this.material,
    required this.weightTonnes,
    required this.requiredTruckType,
    required this.trucksNeeded,
    required this.price,
    required this.priceType,
    required this.advancePercentage,
    required this.pickupDate,
  });
}
