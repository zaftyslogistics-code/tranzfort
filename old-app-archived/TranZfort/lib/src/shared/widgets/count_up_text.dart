import 'package:flutter/material.dart';

class CountUpText extends StatelessWidget {
  final num value;
  final Duration duration;
  final TextStyle? style;
  final int fractionDigits;
  final String prefix;
  final String suffix;

  const CountUpText({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 600),
    this.style,
    this.fractionDigits = 0,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final safeTarget = value is double ? value as double : value.toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: safeTarget),
      duration: duration,
      builder: (context, animatedValue, _) {
        final rendered = _formatValue(animatedValue);
        return Text('$prefix$rendered$suffix', style: style);
      },
    );
  }

  String _formatValue(double animatedValue) {
    if (fractionDigits > 0) {
      return animatedValue.toStringAsFixed(fractionDigits);
    }
    return animatedValue.round().toString();
  }
}
