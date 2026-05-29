part of 'chat_screen.dart';

class _ChatMessageContent extends StatelessWidget {
  final ChatMessage message;
  final String? loadId;

  const _ChatMessageContent({required this.message, required this.loadId});

  @override
  Widget build(BuildContext context) {
    return switch (message.type) {
      ChatMessageType.text => Text(
          message.textBody ?? '',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: message.isFromCurrentUser ? AppColors.primaryChipText : AppColors.textPrimary,
          ),
        ),
      ChatMessageType.voice => _VoiceMessageContent(message: message),
      ChatMessageType.location => _LocationMessageContent(message: message),
      ChatMessageType.document => _DocumentMessageContent(message: message),
      ChatMessageType.mapCard => _MapCardMessageContent(message: message, loadId: loadId),
      ChatMessageType.truckCard => _TruckCardMessageContent(message: message),
      ChatMessageType.system => const SizedBox.shrink(),
    };
  }
}

class _LocationMessageContent extends StatelessWidget {
  final ChatMessage message;

  const _LocationMessageContent({required this.message});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final payload = message.structuredPayload;
    final label = _payloadString(payload, const ['label', 'title', 'location_label']) ?? l10n.chatLocationSharedFallback;
    final uri = _locationUri(payload) ?? _externalUriFromPayload(payload, const ['google_maps_url', 'maps_url', 'url']);
    return _InfoMessageCard(
      icon: Icons.location_on_outlined,
      title: label,
      subtitle: uri == null ? l10n.chatMapPreviewUnavailable : uri.toString(),
      actionLabel: uri == null ? null : l10n.commonOpenInGoogleMapsAction,
      onAction: uri == null
          ? null
          : () async {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
    );
  }
}

class _DocumentMessageContent extends StatelessWidget {
  final ChatMessage message;

  const _DocumentMessageContent({required this.message});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final fileName = _fileNameFromPath(message.attachmentPath) ??
        _payloadString(message.structuredPayload, const ['file_name', 'filename', 'name']) ??
        l10n.chatDocumentSharedFallback;
    final uri = _externalUri(message.attachmentPath) ??
        _externalUriFromPayload(message.structuredPayload, const ['url', 'download_url']);
    return _InfoMessageCard(
      icon: Icons.attach_file,
      title: fileName,
      subtitle: uri == null ? l10n.chatAttachmentSavedSubtitle : uri.toString(),
      actionLabel: uri == null ? null : l10n.chatOpenDocumentAction,
      onAction: uri == null
          ? null
          : () async {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
    );
  }
}

class _MapCardMessageContent extends ConsumerWidget {
  final ChatMessage message;
  final String? loadId;

  const _MapCardMessageContent({required this.message, required this.loadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final payload = message.structuredPayload;
    final dieselPriceMap = ref.watch(dieselPriceMapProvider).valueOrNull ?? const <String, double>{};
    final tripCostingService = ref.watch(tripCostingServiceProvider);
    final route = _payloadString(payload, const ['route_label', 'route', 'title']) ?? message.textBody ?? l10n.chatRouteSummaryFallback;
    final material = _payloadString(payload, const ['material']);
    final weight = _payloadString(payload, const ['weight', 'weight_label']) ??
        (_payloadDouble(payload, const ['weight_tonnes']) == null ? null : _formatTonnesCompact(_payloadDouble(payload, const ['weight_tonnes'])!, l10n));
    final price = _payloadString(payload, const ['price', 'price_label']) ??
        (_payloadDouble(payload, const ['price_amount']) == null ? null : _formatCurrencyCompact(_payloadDouble(payload, const ['price_amount'])!, l10n));
    final distanceKm = _payloadDouble(payload, const ['route_distance_km', 'distance_km']);
    final weightTonnes = _payloadDouble(payload, const ['weight_tonnes']);
    final originState = _payloadString(payload, const ['origin_state']);
    final dieselPrice = DieselPriceRepository.estimateDieselPricePerLitre(dieselPriceMap, originState);
    final computedTripCost = tripCostingService.estimate(
      distanceKm: distanceKm,
      loadWeightTonnes: weightTonnes,
      dieselPricePerLitre: dieselPrice,
    );
    final tripCost = _payloadString(payload, const ['trip_cost', 'trip_cost_label', 'estimated_trip_cost']) ??
        (computedTripCost == null ? null : _formatCurrencyCompact(computedTripCost.totalCost, l10n));
    final resolvedLoadId = _payloadString(payload, const ['load_id']) ?? loadId;
    final uri = _externalUriFromPayload(payload, const ['route_url', 'google_maps_url', 'maps_url', 'url']);
    return _InfoMessageCard(
      icon: Icons.map_outlined,
      title: route,
      subtitle: [material, weight, price, tripCost].whereType<String>().where((value) => value.trim().isNotEmpty).join(' - '),
      actionLabel: (resolvedLoadId == null || resolvedLoadId.trim().isEmpty) && uri == null ? null : l10n.chatViewRouteAction,
      onAction: (resolvedLoadId == null || resolvedLoadId.trim().isEmpty) && uri == null
          ? null
          : () async {
              if (resolvedLoadId != null && resolvedLoadId.trim().isNotEmpty) {
                context.push('${AppRoutes.loadDetailPath}/${resolvedLoadId.trim()}');
                return;
              }
              await launchUrl(uri!, mode: LaunchMode.externalApplication);
            },
    );
  }
}

class _TruckCardMessageContent extends StatelessWidget {
  final ChatMessage message;

  const _TruckCardMessageContent({required this.message});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final payload = message.structuredPayload;
    final title = _payloadString(payload, const ['truck_display_label', 'truck_number', 'title']) ?? l10n.commonTruckDetailsLabel;
    final bodyType = _payloadString(payload, const ['body_type', 'bodyType']);
    final tyres = _payloadString(payload, const ['tyres', 'tyre_count']);
    final rcName = _payloadString(payload, const ['rc_file_name', 'rc_name']);
    return _InfoMessageCard(
      icon: Icons.local_shipping_outlined,
      title: title,
      subtitle: [bodyType, tyres == null ? null : l10n.chatTruckTyresLabel(tyres), rcName].whereType<String>().where((value) => value.trim().isNotEmpty).join(' - '),
    );
  }
}

class _InfoMessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const _InfoMessageCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  if ((subtitle ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
        ],
      ],
    );
  }
}
