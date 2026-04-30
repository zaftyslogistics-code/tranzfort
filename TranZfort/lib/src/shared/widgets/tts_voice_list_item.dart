import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/tts_voice_model.dart';

/// Widget for displaying a TTS voice option in a list.
class TtsVoiceListItem extends ConsumerWidget {
  final TtsVoice voice;
  final bool isSelected;
  final VoidCallback onTap;

  const TtsVoiceListItem({
    super.key,
    required this.voice,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      leading: _buildLeadingIcon(theme),
      title: Text(
        voice.name,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        voice.locale,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: _buildTrailing(theme),
    );
  }

  Widget _buildLeadingIcon(ThemeData theme) {
    return Radio<bool>(
      value: true,
      groupValue: isSelected,
      onChanged: (_) => onTap(),
      activeColor: theme.colorScheme.primary,
    );
  }

  Widget _buildTrailing(ThemeData theme) {
    if (voice.isOffline) {
      return Chip(
        label: Text(
          'Offline',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        visualDensity: VisualDensity.compact,
      );
    }
    return const SizedBox.shrink();
  }
}
