import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/config/maps_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/primary_button.dart';

class MapMessageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double? lat;
  final double? lng;
  final VoidCallback? onOpenMap;
  final MapsConfig mapsConfig;

  const MapMessageCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.lat,
    this.lng,
    this.onOpenMap,
    required this.mapsConfig,
  });

  String? _buildStaticMapUrl() {
    if (lat == null || lng == null) {
      return null;
    }
    if (mapsConfig.hasApiKey) {
      return 'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=13&size=600x260&maptype=roadmap&markers=color:red%7C$lat,$lng&key=${mapsConfig.apiKey}';
    }
    return 'https://staticmap.openstreetmap.de/staticmap.php?center=$lat,$lng&zoom=11&size=600x260&markers=$lat,$lng,red-pushpin';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        border: Border.all(color: AppColors.neutralLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_buildStaticMapUrl() != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: Image.network(
                _buildStaticMapUrl()!,
                width: double.infinity,
                height: 130,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 130,
                    color: AppColors.gray100,
                    child: const Center(
                      child: Icon(Icons.map, color: AppColors.textTertiary),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: l10n.chatOpenMap,
              onPressed: onOpenMap,
            ),
          ),
        ],
      ),
    );
  }
}
