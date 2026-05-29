import '../../trucker/data/trucker_fleet_repository.dart';
import 'verification_wizard_draft.dart';

/// True when [trucks] already has a non-archived truck matching [draft] with RC + capacity.
bool fleetHasReadyTruckForDraft({
  required Iterable<TruckerFleetTruck> trucks,
  required TruckDraft draft,
}) {
  final normalizedNumber = draft.truckNumber.trim().toUpperCase();
  return trucks.any(
    (t) =>
        t.status != TruckerFleetTruckStatus.archived &&
        t.truckNumber.trim().toUpperCase() == normalizedNumber &&
        (t.rcDocumentPath ?? '').trim().isNotEmpty &&
        t.capacityTonnes > 0,
  );
}
