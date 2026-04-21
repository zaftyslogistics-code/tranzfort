import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/tts_state_provider.dart';
import 'feedback_components.dart';

class TtsActionButton extends ConsumerWidget {
  const TtsActionButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMuted = ref.watch(ttsMutedProvider);

    return IconButton(
      tooltip: isMuted ? 'Unmute voice assistant' : 'Mute voice assistant',
      onPressed: () async {
        await ref.read(ttsMutedProvider.notifier).toggleMuted();
        if (context.mounted) {
          final newMutedState = ref.read(ttsMutedProvider);
          AppSnackbar.show(
            context: context,
            message: newMutedState ? 'Voice muted' : 'Voice unmuted',
            variant: AppSnackbarVariant.info,
          );
        }
      },
      icon: Stack(
        children: [
          Icon(
            Icons.volume_up_outlined,
            size: 24,
          ),
          if (isMuted)
            Positioned.fill(
              child: Icon(
                Icons.close,
                size: 12,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
