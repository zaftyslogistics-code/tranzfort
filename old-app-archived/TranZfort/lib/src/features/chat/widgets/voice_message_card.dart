import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/outline_button.dart';

class VoiceMessageCard extends StatelessWidget {
  final bool isPlaying;
  final int durationSeconds;
  final VoidCallback onPressed;

  const VoiceMessageCard({
    super.key,
    required this.isPlaying,
    required this.durationSeconds,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final durationLabel =
        durationSeconds > 0 ? '${durationSeconds}s' : l10n.chatVoiceLabel;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        border: Border.all(color: AppColors.neutralLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          VoiceWaveformBars(isPlaying: isPlaying),
          const SizedBox(width: AppSpacing.xs),
          Text(durationLabel, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: AppSpacing.sm),
          OutlineButton(
            label: isPlaying ? l10n.chatStopAction : l10n.chatPlayAction,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class VoiceWaveformBars extends StatefulWidget {
  final bool isPlaying;

  const VoiceWaveformBars({super.key, required this.isPlaying});

  @override
  State<VoiceWaveformBars> createState() => _VoiceWaveformBarsState();
}

class _VoiceWaveformBarsState extends State<VoiceWaveformBars>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(5, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 300 + index * 50),
        vsync: this,
      );
    });
    _animations = _controllers.map((c) => Tween<double>(
      begin: 8.0,
      end: 24.0,
    ).animate(CurvedAnimation(
      parent: c,
      curve: Curves.easeInOut,
    ))).toList();

    if (widget.isPlaying) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(VoiceWaveformBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startAnimation();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _stopAnimation();
    }
  }

  void _startAnimation() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted && widget.isPlaying) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimation() {
    for (final controller in _controllers) {
      controller.stop();
      controller.reset();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                width: 3,
                height: _animations[index].value,
                decoration: BoxDecoration(
                  color: widget.isPlaying ? AppColors.primary : AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
