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
  final bool enlarged;
  final EdgeInsets scrollPadding;

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
    this.enlarged = false,
    this.scrollPadding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final enlargedStyle = enlarged
        ? Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)
        : null;

    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      style: enlargedStyle,
      scrollPadding: scrollPadding,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixText: prefixText,
        helperText: helperText,
        errorText: errorText,
        suffixIcon: suffixIcon,
        contentPadding: enlarged
            ? const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg)
            : null,
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
  final bool onDarkSurface;

  const AppDropdown({
    super.key,
    this.label,
    this.value,
    required this.items,
    this.onChanged,
    this.helperText,
    this.onDarkSurface = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppRadius.input);
    final borderSide = onDarkSurface
        ? BorderSide(color: AppColors.inkBorder)
        : const BorderSide(color: AppColors.divider);
    final focusedBorderSide = onDarkSurface
        ? BorderSide(color: AppColors.primaryOnDark, width: 1.5)
        : const BorderSide(color: AppColors.primary, width: 1.5);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        labelStyle: onDarkSurface
            ? Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.inkTextSecondary)
            : null,
        helperStyle: onDarkSurface
            ? Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkTextMuted)
            : null,
        filled: onDarkSurface,
        fillColor: onDarkSurface ? AppColors.inkDeep : null,
        enabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: borderSide),
        focusedBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: focusedBorderSide),
        border: OutlineInputBorder(borderRadius: borderRadius, borderSide: borderSide),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(AppRadius.input),
          dropdownColor: onDarkSurface ? AppColors.inkMid : null,
          iconEnabledColor: onDarkSurface ? AppColors.primaryOnDark : null,
          style: onDarkSurface
              ? Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.inkTextPrimary)
              : null,
          items: onDarkSurface
              ? items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item.value,
                      child: DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: AppColors.inkTextPrimary,
                            ),
                        child: item.child,
                      ),
                    ),
                  )
                  .toList()
              : items,
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
  final bool onDarkSurface;

  const AppSearchField({
    super.key,
    this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onClear,
    this.onDarkSurface = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppRadius.input);
    final borderSide = onDarkSurface
        ? BorderSide(color: AppColors.inkBorder)
        : const BorderSide(color: AppColors.divider);
    final focusedBorderSide = onDarkSurface
        ? BorderSide(color: AppColors.primaryOnDark, width: 1.5)
        : const BorderSide(color: AppColors.primary, width: 1.5);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: onDarkSurface
          ? Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.inkTextPrimary)
          : null,
      cursorColor: onDarkSurface ? AppColors.primaryOnDark : null,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: onDarkSurface
            ? Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.inkTextSecondary)
            : null,
        filled: onDarkSurface,
        fillColor: onDarkSurface ? AppColors.inkDeep : null,
        prefixIcon: Icon(
          Icons.search,
          color: onDarkSurface ? AppColors.primaryOnDark : null,
        ),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                onPressed: onClear,
                icon: Icon(
                  Icons.close,
                  color: onDarkSurface ? AppColors.inkTextSecondary : null,
                ),
              ),
        enabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: borderSide),
        focusedBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: focusedBorderSide),
        border: OutlineInputBorder(borderRadius: borderRadius, borderSide: borderSide),
      ),
    );
  }
}
