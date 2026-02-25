import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class DashboardVerificationBanner extends StatelessWidget {
  const DashboardVerificationBanner({
    super.key,
    required this.status,
    this.rejectionReason,
  });

  final String status;
  final String? rejectionReason;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    final (
      Color bg,
      Color fg,
      IconData icon,
      String message,
    ) = switch (normalized) {
      'verified' => (
        Colors.green.withValues(alpha: 0.14),
        Colors.green.shade800,
        Icons.verified,
        'Your verification is approved.',
      ),
      'pending' => (
        Colors.orange.withValues(alpha: 0.14),
        Colors.orange.shade900,
        Icons.hourglass_top,
        'Your verification is under review.',
      ),
      'rejected' => (
        Colors.red.withValues(alpha: 0.12),
        Colors.red.shade800,
        Icons.error_outline,
        rejectionReason == null || rejectionReason!.isEmpty
            ? 'Verification was rejected. Please resubmit documents.'
            : 'Rejected: $rejectionReason',
      ),
      _ => (
        AppColors.neutralLight,
        AppColors.onSurface,
        Icons.info_outline,
        'Complete your verification to unlock full access.',
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
