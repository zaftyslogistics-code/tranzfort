import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/settings/providers/settings_provider.dart';
import '../../features/notifications/providers/notifications_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';

class AppBarUtilityActions extends ConsumerStatefulWidget {
  final String ttsPreviewText;
  final bool compact;

  const AppBarUtilityActions({
    super.key,
    required this.ttsPreviewText,
    this.compact = false,
  });

  @override
  ConsumerState<AppBarUtilityActions> createState() =>
      _AppBarUtilityActionsState();
}

class _AppBarUtilityActionsState extends ConsumerState<AppBarUtilityActions> {
  Future<void> _toggleTts({required bool currentlyMuted}) async {
    final updatedMuted = !currentlyMuted;
    await ref.read(settingsProvider.notifier).toggleTts(updatedMuted);
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updatedMuted ? l10n.appBarTtsMutedSnack : l10n.appBarTtsEnabledSnack,
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _toggleLanguage({required String currentLanguage}) async {
    final updated = currentLanguage == 'hi' ? 'en' : 'hi';
    await ref.read(settingsProvider.notifier).setLanguage(updated);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated == 'hi'
              ? l10n.appBarLanguageChangedHindi
              : l10n.appBarLanguageChangedEnglish,
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);
    final unreadCount = unreadCountAsync.valueOrNull ?? 0;
    final settings = ref.watch(settingsProvider);
    final ttsEnabled = !settings.ttsMuted;
    final minTarget = widget.compact ? 40.0 : AppSpacing.minTouchTarget;
    final iconSize = widget.compact ? AppSpacing.iconLg : null;
    final visualDensity = widget.compact
        ? const VisualDensity(horizontal: -2, vertical: -2)
        : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _toggleTts(currentlyMuted: settings.ttsMuted),
          icon: Icon(
            ttsEnabled ? Icons.volume_up_outlined : Icons.volume_off_rounded,
            color: ttsEnabled ? AppColors.primary : AppColors.textSecondary,
            size: iconSize,
          ),
          tooltip: ttsEnabled
              ? l10n.appBarTtsTooltipMute(widget.ttsPreviewText)
              : l10n.appBarTtsTooltipEnable,
          visualDensity: visualDensity,
          constraints: BoxConstraints(
            minWidth: minTarget,
            minHeight: minTarget,
          ),
        ),
        IconButton(
          onPressed: () => _toggleLanguage(currentLanguage: settings.language),
          icon: Text(
            settings.language == 'hi' ? 'A' : 'अ',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          tooltip: l10n.appBarLanguageToggleTooltip,
          visualDensity: visualDensity,
          constraints: BoxConstraints(
            minWidth: minTarget,
            minHeight: minTarget,
          ),
        ),
        IconButton(
          onPressed: () => context.push('/notifications'),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_outlined, size: iconSize),
              if (unreadCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          tooltip: l10n.appBarNotificationsTooltip,
          visualDensity: visualDensity,
          constraints: BoxConstraints(
            minWidth: minTarget,
            minHeight: minTarget,
          ),
        ),
      ],
    );
  }
}
