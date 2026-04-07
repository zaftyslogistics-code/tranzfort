import 'package:flutter/material.dart';
import '../../core/theme/admin_colors.dart';

enum SnackbarType { success, error, info, warning }

void showAppSnackBar(
  BuildContext context, {
  required String message,
  SnackbarType type = SnackbarType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final (backgroundColor, icon) = _snackBarStyle(type);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: duration,
    ),
  );
}

(Color backgroundColor, IconData icon) _snackBarStyle(SnackbarType type) {
  switch (type) {
    case SnackbarType.success:
      return (Colors.green.shade700, Icons.check_circle_outline);
    case SnackbarType.error:
      return (AdminColors.error, Icons.error_outline);
    case SnackbarType.warning:
      return (AdminColors.brandOrange, Icons.warning_amber_rounded);
    case SnackbarType.info:
      return (AdminColors.primary, Icons.info_outline);
  }
}
