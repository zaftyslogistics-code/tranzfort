enum TripStage {
  assigned('assigned'),
  pickupPending('pickup_pending'),
  pickedUp('picked_up'),
  inTransit('in_transit'),
  delivered('delivered'),
  podUploaded('pod_uploaded'),
  proofSubmitted('proof_submitted'),
  podUploaded('pod_uploaded'),
  disputed('disputed'),
  completed('completed'),
  cancelled('cancelled');

  const TripStage(this.databaseValue);

  final String databaseValue;

  static TripStage? fromDatabase(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    for (final stage in TripStage.values) {
      if (stage.databaseValue == normalized) {
        return stage;
      }
    }
    return null;
  }

  String toDatabaseValue() => databaseValue;
}

enum LoadStatus {
  active('active'),
  assignedPartial('assigned_partial'),
  assignedFull('assigned_full'),
  // NOTE: 'open' is a legacy value that is no longer used in the codebase.
  // New loads use 'active' instead. Kept for backward compatibility with existing data.
  // ignore: unused_field
  open('open'),
  partiallyBooked('partially_booked'),
  booked('booked'),
  inTransit('in_transit'),
  delivered('delivered'),
  proofSubmitted('proof_submitted'),
  completed('completed'),
  cancelled('cancelled'),
  closedFilledOutside('closed_filled_outside');

  const LoadStatus(this.databaseValue);

  final String databaseValue;

  static LoadStatus? fromDatabase(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    for (final status in LoadStatus.values) {
      if (status.databaseValue == normalized) {
        return status;
      }
    }
    return null;
  }

  String toDatabaseValue() => databaseValue;
}

enum BookingStatus {
  submitted('submitted'),
  accepted('accepted'),
  rejected('rejected'),
  cancelled('cancelled'),
  completed('completed');

  const BookingStatus(this.databaseValue);

  final String databaseValue;

  static BookingStatus? fromDatabase(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    for (final status in BookingStatus.values) {
      if (status.databaseValue == normalized) {
        return status;
      }
    }
    return null;
  }

  String toDatabaseValue() => databaseValue;
}
