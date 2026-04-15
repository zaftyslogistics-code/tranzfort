import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String? label;
  final String? hintText;
  final String? prefixText;
  final String? helperText;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.label,
    this.hintText,
    this.prefixText,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.onChanged,
    this.suffixIcon,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixText: prefixText,
        helperText: helperText,
        errorText: errorText,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class AppDropdown<T> extends StatelessWidget {
  final String? label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? helperText;

  const AppDropdown({
    super.key,
    this.label,
    this.value,
    required this.items,
    this.onChanged,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(AppRadius.input),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class AppDatePicker extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime>? onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const AppDatePicker({
    super.key,
    required this.label,
    this.value,
    this.onChanged,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = value == null
        ? 'Select date'
        : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}';

    return InkWell(
      onTap: onChanged == null
          ? null
          : () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: firstDate ?? DateTime(2020),
                lastDate: lastDate ?? DateTime(2100),
              );

              if (selected != null) {
                onChanged?.call(selected);
              }
            },
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayText,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: value == null ? AppColors.textMuted : AppColors.textPrimary,
                    ),
              ),
            ),
            const Icon(Icons.calendar_today_outlined, size: 18),
          ],
        ),
      ),
    );
  }
}

class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const AppSearchField({
    super.key,
    this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
      ),
    );
  }
}
