import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/contextual_tts_service.dart';

/// A widget wrapper that announces field labels when focused
/// and validation errors when they appear.
///
/// This widget wraps any form field and provides TTS accessibility:
/// - Speaks the label when the field gains focus
/// - Speaks validation errors when they appear
/// - Prevents duplicate error announcements
///
/// API:
/// ```dart
/// TtsFocusField(
///   labelToSpeak: 'Full Name',
///   errorText: fieldError,
///   child: TextFormField(...),
/// )
/// ```
class TtsFocusField extends ConsumerStatefulWidget {
  /// The label to speak when the field gains focus
  final String labelToSpeak;

  /// Error text to speak when validation fails (optional)
  final String? errorText;

  /// The actual form field widget to wrap
  final Widget child;

  /// Language code for TTS (e.g., 'en', 'hi'). If null, uses app locale.
  final String? languageCode;

  const TtsFocusField({
    super.key,
    required this.labelToSpeak,
    this.errorText,
    required this.child,
    this.languageCode,
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
    if (error != null &&
        error.isNotEmpty &&
        error != oldError &&
        error != _lastSpokenError) {
      _lastSpokenError = error;
      _speak(error);
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _speak(widget.labelToSpeak);
    }
  }

  void _speak(String message) {
    final resolvedLanguageCode = widget.languageCode ??
        Localizations.localeOf(context).languageCode;

    unawaited(
      ref.read(contextualTtsServiceProvider).speakSummary(
        languageCode: resolvedLanguageCode,
        message: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: widget.child,
    );
  }
}
