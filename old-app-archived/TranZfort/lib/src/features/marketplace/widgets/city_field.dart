import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/city_search_service.dart';
import '../../../core/theme/app_spacing.dart';

class CityField extends ConsumerWidget {
  final String label;
  final TextEditingController controller;
  final String searchKey;
  final ValueChanged<CitySuggestion> onSelected;

  const CityField({
    super.key,
    required this.label,
    required this.controller,
    required this.searchKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Icon(Icons.location_city_outlined),
            ),
          ),
          onSubmitted: (value) {
            final trimmed = value.trim();
            if (trimmed.isEmpty) return;
            onSelected(CitySuggestion(city: trimmed, state: 'Unknown'));
          },
        ),
      ],
    );
  }
}
