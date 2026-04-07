import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class ScrollToTopFab extends StatefulWidget {
  final ScrollController controller;

  const ScrollToTopFab({super.key, required this.controller});

  @override
  State<ScrollToTopFab> createState() => _ScrollToTopFabState();
}

class _ScrollToTopFabState extends State<ScrollToTopFab> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant ScrollToTopFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
      _onScroll();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final shouldShow =
        widget.controller.hasClients && widget.controller.offset > 200;
    if (shouldShow != _visible && mounted) {
      setState(() => _visible = shouldShow);
    }
  }

  Future<void> _scrollToTop() async {
    if (!widget.controller.hasClients) {
      return;
    }
    await widget.controller.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !_visible,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton.small(
          heroTag: '${widget.hashCode}-scroll-to-top',
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          onPressed: _scrollToTop,
          tooltip: 'Scroll to top',
          child: const Icon(Icons.arrow_upward, size: AppSpacing.iconMd),
        ),
      ),
    );
  }
}
