import 'dart:math';

class ColorPair {
  const ColorPair(this.name, this.foreground, this.background, this.isLargeText);

  final String name;
  final int foreground;
  final int background;
  final bool isLargeText;
}

void main() {
  const pairs = <ColorPair>[
    ColorPair('textPrimary on surface', 0xFF1A1A2E, 0xFFFFFFFF, false),
    ColorPair('textSecondary on surface', 0xFF5A6178, 0xFFFFFFFF, false),
    ColorPair('textSecondary on gray50', 0xFF5A6178, 0xFFF9FAFB, false),
    ColorPair('textSecondary on gray100', 0xFF5A6178, 0xFFF3F4F6, false),
    ColorPair('primary on brandTealLight', 0xFF0F6F69, 0xFFE6F5F3, false),
    ColorPair('white on primary', 0xFFFFFFFF, 0xFF0F6F69, false),
    ColorPair('white on brandOrange', 0xFFFFFFFF, 0xFFB45309, false),
    ColorPair('error on errorLight', 0xFFB91C1C, 0xFFFEF2F2, false),
    ColorPair('success on successLight', 0xFF047857, 0xFFECFDF5, false),
    ColorPair('info on infoLight', 0xFF2563EB, 0xFFEFF6FF, false),
  ];

  var allPass = true;
  for (final pair in pairs) {
    final ratio = _contrastRatio(pair.foreground, pair.background);
    final aaThreshold = pair.isLargeText ? 3.0 : 4.5;
    final pass = ratio >= aaThreshold;
    if (!pass) allPass = false;
    print(
      '${pair.name.padRight(30)} | ratio=${ratio.toStringAsFixed(2)} | '
      'AA>=${aaThreshold.toStringAsFixed(1)} | ${pass ? 'PASS' : 'FAIL'}',
    );
  }

  print('');
  print(allPass
      ? 'WCAG AA check: PASS for all sampled palette pairs.'
      : 'WCAG AA check: FAIL for one or more sampled palette pairs.');
}

double _contrastRatio(int fg, int bg) {
  final l1 = _luminance(fg);
  final l2 = _luminance(bg);
  final lighter = max(l1, l2);
  final darker = min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

double _luminance(int color) {
  final r = _linear(((color >> 16) & 0xFF) / 255.0);
  final g = _linear(((color >> 8) & 0xFF) / 255.0);
  final b = _linear((color & 0xFF) / 255.0);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _linear(double c) {
  return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
}
