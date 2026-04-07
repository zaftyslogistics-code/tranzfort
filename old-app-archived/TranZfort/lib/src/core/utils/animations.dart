import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_spacing.dart';

CustomTransitionPage<void> fadeSlideTransitionPage({
  required Widget child,
  LocalKey? key,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: AppSpacing.normal,
    reverseTransitionDuration: AppSpacing.normal,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

extension StaggerListItemAnimation on Widget {
  Widget staggeredFadeSlide({
    required int index,
    Duration baseDelay = const Duration(milliseconds: 40),
  }) {
    return animate()
        .fadeIn(
          duration: AppSpacing.normal,
          delay: baseDelay * index,
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0.06,
          end: 0,
          duration: AppSpacing.normal,
          delay: baseDelay * index,
          curve: Curves.easeOut,
        );
  }
}
