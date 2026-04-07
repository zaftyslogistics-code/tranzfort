import 'package:flutter/material.dart';

import '../../core/theme/admin_colors.dart';

class AdminBrandHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const AdminBrandHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.admin_panel_settings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AdminColors.tranzfortGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AdminColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AdminColors.brandTealLightMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AdminColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
