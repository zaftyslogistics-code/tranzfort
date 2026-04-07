import 'dart:io';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class DocumentUploadRow extends StatelessWidget {
  final String label;
  final File? file;
  final String? existingUrl;
  final VoidCallback onTap;
  final String? ttsGuidance;

  const DocumentUploadRow({
    super.key,
    required this.label,
    this.file,
    this.existingUrl,
    required this.onTap,
    this.ttsGuidance,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final existing = existingUrl;
    final hasExisting = existing != null && existing.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(
            color: file != null || hasExisting
                ? AppColors.primary
                : AppColors.neutralLight,
            width: file != null || hasExisting ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              file != null || hasExisting
                  ? Icons.check_circle
                  : Icons.upload_file_outlined,
              color: file != null || hasExisting
                  ? AppColors.primary
                  : AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            if (file != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(
                    file!,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else if (hasExisting)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    existingUrl!,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 24,
                        height: 24,
                        color: AppColors.neutralLight,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                      );
                    },
                  ),
                ),
              ),
            Expanded(
              child: Text(
                file != null
                    ? file!.path.split('/').last
                    : label,
                style: TextStyle(
                  color: file != null || hasExisting
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: file != null || hasExisting
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
            ),
            if (file != null || hasExisting)
              IconButton(
                onPressed: onTap,
                icon: const Icon(Icons.edit_outlined),
                iconSize: 18,
                color: AppColors.primary,
                tooltip: l10n.editAction,
              ),
          ],
        ),
      ),
    );
  }
}
