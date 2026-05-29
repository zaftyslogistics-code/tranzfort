/// Shared source of truth for load/trip lifecycle status groupings.
///
/// Keeping these in one file prevents drift when dashboards, lists,
/// and filters need the same logical groups.
class LoadStatuses {
  LoadStatuses._();

  static const List<String> active = <String>[
    'active',
    'assigned_partial',
    'assigned_full',
    'in_transit',
  ];

  static const List<String> completed = <String>[
    'completed',
    'filled_outside_app',
    'cancelled',
    'expired',
    'deactivated',
  ];

  static const List<String> supplierViewActive = <String>[
    'draft',
    'active',
    'booked',
    'assigned_partial',
    'assigned_full',
    'in_transit',
  ];
}

class TripStages {
  TripStages._();

  static const List<String> upcoming = <String>[
    'assigned',
    'pickup_pending',
    'picked_up',
  ];

  static const List<String> inProgress = <String>[
    'assigned',
    'pickup_pending',
    'picked_up',
    'in_transit',
    'delivered',
    'proof_submitted',
    'disputed',
  ];

  static const List<String> completed = <String>[
    'completed',
    'cancelled',
  ];

  static const List<String> allowsLrUpload = <String>[
    'pickup_pending',
    'picked_up',
  ];

  static const Map<String, int> progressOrder = <String, int>{
    'assigned': 1,
    'pickup_pending': 2,
    'picked_up': 3,
    'in_transit': 4,
    'delivered': 5,
    'pod_uploaded': 6,
    'proof_submitted': 6,
    'completed': 7,
    'disputed': 6,
    'cancelled': 7,
  };
}

class BidStatuses {
  BidStatuses._();

  static const List<String> active = <String>['submitted'];
}
