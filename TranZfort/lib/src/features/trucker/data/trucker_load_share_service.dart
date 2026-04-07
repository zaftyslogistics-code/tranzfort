import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/navigation/app_routes.dart';
import 'trucker_load_detail_repository.dart';

class TruckerLoadSharePayload {
  final String subject;
  final String text;
  final Uri whatsappUri;

  const TruckerLoadSharePayload({
    required this.subject,
    required this.text,
    required this.whatsappUri,
  });
}

class TruckerLoadShareService {
  final Future<bool> Function(Uri uri) _canLaunchUrl;
  final Future<bool> Function(Uri uri) _launchUrl;
  final Future<void> Function(String text, String subject) _shareSystemText;

  TruckerLoadShareService({
    Future<bool> Function(Uri uri)? canLaunchUrlFn,
    Future<bool> Function(Uri uri)? launchUrlFn,
    Future<void> Function(String text, String subject)? shareSystemTextFn,
  })  : _canLaunchUrl = canLaunchUrlFn ?? canLaunchUrl,
        _launchUrl = launchUrlFn ?? ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication)),
        _shareSystemText = shareSystemTextFn ?? _defaultSystemShare;

  TruckerLoadSharePayload buildPayload(
    AppLocalizations l10n,
    String localizedPickupDate,
    TruckerLoadDetail detail,
  ) {
    final routeSummary = '${detail.summary.originCity} > ${detail.summary.destinationCity}';
    final requirement = _localizedBodyType(l10n, detail.summary.requiredBodyType);
    final tyreSummary = detail.summary.requiredTyres.isEmpty
        ? l10n.chatTruckTyresLabel(l10n.truckerLoadDetailAnyOption)
        : l10n.chatTruckTyresLabel(detail.summary.requiredTyres.join('/'));
    final superLoadLine = detail.summary.isSuperLoad ? 'Super Load - Payment Guarantee' : null;
    final appLink = '${AppRoutes.loadDetailPath}/${detail.summary.id}';
    final text = [
      'TranZfort load: $routeSummary',
      'Material: ${detail.summary.material}',
      'Weight: ${_tonnes(detail.summary.weightTonnes)} tonnes',
      l10n.supplierLoadCardPickupDate(localizedPickupDate),
      'Truck: $requirement - $tyreSummary',
      l10n.truckerLoadDetailPriceLabel(
        detail.summary.priceAmount.toStringAsFixed(0),
        _localizedPriceType(l10n, detail.summary.priceType),
      ),
      ?superLoadLine,
      'Load reference: ${detail.summary.id}',
      'In app: $appLink',
    ].join('\n');
    return TruckerLoadSharePayload(
      subject: 'TranZfort Load ${detail.summary.id}',
      text: text,
      whatsappUri: Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}'),
    );
  }

  Future<void> shareSystem(TruckerLoadSharePayload payload) {
    return _shareSystemText(payload.text, payload.subject);
  }

  Future<bool> shareToWhatsApp(TruckerLoadSharePayload payload) async {
    if (!await _canLaunchUrl(payload.whatsappUri)) {
      return false;
    }
    return _launchUrl(payload.whatsappUri);
  }

  static Future<void> _defaultSystemShare(String text, String subject) async {
    await Share.share(text, subject: subject);
  }

  static String _localizedBodyType(AppLocalizations l10n, String? value) {
    final normalized = (value ?? '').trim();
    switch (normalized.toLowerCase()) {
      case 'open':
        return l10n.truckerFindLoadsBodyTypeOpen;
      case 'trailer':
        return l10n.truckerFindLoadsBodyTypeTrailer;
      case 'container':
        return l10n.truckerFindLoadsBodyTypeContainer;
      case 'tanker':
        return l10n.truckerFindLoadsBodyTypeTanker;
      default:
        return normalized.isEmpty ? l10n.truckerFindLoadsAnyBodyFallback : normalized;
    }
  }

  static String _localizedPriceType(AppLocalizations l10n, String value) {
    switch (value.trim().toLowerCase()) {
      case 'fixed':
        return l10n.supplierPostLoadPriceTypeFixed;
      case 'per_ton':
      case 'negotiable':
        return l10n.supplierPostLoadPriceTypeNegotiable;
      default:
        return value.trim();
    }
  }

  static String _tonnes(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }
}

final truckerLoadShareServiceProvider = Provider<TruckerLoadShareService>((ref) {
  return TruckerLoadShareService();
});
