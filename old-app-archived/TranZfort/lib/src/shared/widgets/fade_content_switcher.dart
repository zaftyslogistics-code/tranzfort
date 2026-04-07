import 'package:flutter/material.dart';

/// Wrapper that adds a subtle fade transition when the child changes.
/// Used for smooth content swaps when data loads.
class FadeContentSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const FadeContentSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: child,
    );
  }
}
