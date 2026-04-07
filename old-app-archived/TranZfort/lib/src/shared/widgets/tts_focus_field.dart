import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/tts_service.dart';

class TtsFocusField extends ConsumerStatefulWidget {
  final String labelToSpeak;
  final String? errorText;
  final Widget child;

  const TtsFocusField({
    super.key,
    required this.labelToSpeak,
    this.errorText,
    required this.child,
  });

  @override
  ConsumerState<TtsFocusField> createState() => _TtsFocusFieldState();
}

class _TtsFocusFieldState extends ConsumerState<TtsFocusField> {
  final FocusNode _focusNode = FocusNode();
  String? _lastSpokenError;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TtsFocusField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final error = widget.errorText?.trim();
    final oldError = oldWidget.errorText?.trim();
    if (error != null && error.isNotEmpty && error != oldError && error != _lastSpokenError) {
      _lastSpokenError = error;
      unawaited(ref.read(ttsServiceProvider).speak(error));
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      unawaited(ref.read(ttsServiceProvider).speak(widget.labelToSpeak));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: widget.child,
    );
  }
}
