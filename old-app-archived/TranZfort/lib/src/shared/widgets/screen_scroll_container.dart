import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Standardized scroll-safe wrapper for screens with bottom overlays.
/// Handles bottom safe inset, avoids nested scroll conflicts, and provides
/// consistent padding and scroll physics for long forms/lists.
class ScreenScrollContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool scrollable;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final ScrollController? controller;

  const ScreenScrollContainer({
    super.key,
    required this.child,
    this.padding,
    this.scrollable = true,
    this.physics,
    this.shrinkWrap = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final effectivePadding = padding ??
        const EdgeInsets.fromLTRB(
          AppSpacing.screenPaddingH,
          AppSpacing.screenPaddingV,
          AppSpacing.screenPaddingH,
          AppSpacing.screenPaddingV,
        );

    final adjustedPadding = effectivePadding.copyWith(
      bottom: effectivePadding.bottom + bottomPadding,
    );

    if (!scrollable) {
      return Padding(padding: adjustedPadding, child: child);
    }

    if (shrinkWrap) {
      return SingleChildScrollView(
        controller: controller,
        physics: physics,
        padding: adjustedPadding,
        child: child,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: controller,
          physics: physics,
          padding: adjustedPadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - adjustedPadding.vertical,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
