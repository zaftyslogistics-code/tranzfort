import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class LegalConsentCheckboxRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final Widget label;

  const LegalConsentCheckboxRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: label,
          ),
        ),
      ],
    );
  }
}
