import 'package:flutter/material.dart';

import '../../core/theme/admin_colors.dart';
import '../../core/theme/admin_design_tokens.dart';

class AdminStatCard extends StatelessWidget {
  final String label;
  final num value;
  final IconData icon;
  final Color color;

  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AdminDesignTokens.sectionGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 600),
              builder: (context, animatedValue, _) {
                return Row(
                  children: [
                    Text(
                      animatedValue.round().toString(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AdminColors.onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.trending_up,
                      size: 14,
                      color: AdminColors.textTertiary,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AdminColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
