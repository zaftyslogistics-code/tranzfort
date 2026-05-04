import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/connectivity_provider.dart';

/// A button widget that is aware of offline state.
/// When offline, the button is disabled and shows a message when tapped.
class OfflineAwareButton extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? offlineMessage;
  final ButtonStyle? style;
  final bool enabled;

  const OfflineAwareButton({
    super.key,
    required this.child,
    this.onPressed,
    this.offlineMessage,
    this.style,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider).value ?? true;

    final isDisabled = !enabled || !isOnline;

    return ElevatedButton(
      onPressed: isDisabled
          ? () {
              if (!isOnline) {
                _showOfflineMessage(context);
              }
            }
          : onPressed,
      style: style?.copyWith(
            backgroundColor: WidgetStateProperty.all(
              isDisabled
                  ? Theme.of(context).disabledColor
                  : null,
            ),
          ),
      child: child,
    );
  }

  void _showOfflineMessage(BuildContext context) {
    final message = offlineMessage ?? 'You are offline. Please check your internet connection.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// A text button variant of OfflineAwareButton.
class OfflineAwareTextButton extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? offlineMessage;
  final bool enabled;

  const OfflineAwareTextButton({
    super.key,
    required this.child,
    this.onPressed,
    this.offlineMessage,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider).value ?? true;

    final isDisabled = !enabled || !isOnline;

    return TextButton(
      onPressed: isDisabled
          ? () {
              if (!isOnline) {
                _showOfflineMessage(context);
              }
            }
          : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: isDisabled
            ? Theme.of(context).disabledColor
            : null,
      ),
      child: child,
    );
  }

  void _showOfflineMessage(BuildContext context) {
    final message = offlineMessage ?? 'You are offline. Please check your internet connection.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// An icon button variant of OfflineAwareButton.
class OfflineAwareIconButton extends ConsumerWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final String? offlineMessage;
  final bool enabled;
  final String? tooltip;

  const OfflineAwareIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.offlineMessage,
    this.enabled = true,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider).value ?? true;

    final isDisabled = !enabled || !isOnline;

    return IconButton(
      icon: icon,
      onPressed: isDisabled
          ? () {
              if (!isOnline) {
                _showOfflineMessage(context);
              }
            }
          : onPressed,
      tooltip: tooltip,
      color: isDisabled ? Theme.of(context).disabledColor : null,
    );
  }

  void _showOfflineMessage(BuildContext context) {
    final message = offlineMessage ?? 'You are offline. Please check your internet connection.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
