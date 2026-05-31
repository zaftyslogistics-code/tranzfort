import '../../../l10n/app_localizations.dart';
import 'load_listing_duration.dart';

/// Phase C scaffold: clone repost request (P1-12).
///
/// Wire to `clone_load_for_repost` RPC in migration phase C.
class RepostLoadRequest {
  final String sourceLoadId;
  final DateTime pickupDate;
  final LoadListingDuration listingDuration;

  const RepostLoadRequest({
    required this.sourceLoadId,
    required this.pickupDate,
    this.listingDuration = LoadListingDuration.defaultDuration,
  });

  Map<String, dynamic> toRpcParams() => {
        'p_source_load_id': sourceLoadId,
        'p_pickup_date': pickupDate.toIso8601String().split('T').first,
        'p_listing_duration': listingDuration.rpcValue,
      };
}

/// Localized marketplace visibility label for supplier load surfaces.
String localizedLoadMarketplaceStatus(
  AppLocalizations l10n, {
  required bool isOnMarketplace,
  required int trucksBooked,
  required int trucksNeeded,
}) {
  if (isOnMarketplace) {
    return l10n.loadMarketplaceStatusOnFeed;
  }
  if (trucksBooked >= trucksNeeded) {
    return l10n.loadMarketplaceStatusFull;
  }
  return l10n.loadMarketplaceStatusHiddenTime;
}
