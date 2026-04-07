import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/action_buttons.dart';
import '../../data/verification_repository.dart';

class DocumentUploadBox extends StatelessWidget {
  final String? documentPath;
  final String label;
  final String? subtitle;
  final bool isRequired;
  final bool isUploading;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final List<QualityCheck> qualityChecks;

  const DocumentUploadBox({
    super.key,
    this.documentPath,
    required this.label,
    this.subtitle,
    this.isRequired = true,
    this.isUploading = false,
    this.icon = Icons.add_a_photo_outlined,
    required this.onTap,
    this.onClear,
    this.qualityChecks = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final hasDocument = documentPath?.isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '(${l10n.verificationDocumentStatusOptional})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: isUploading ? null : onTap,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: hasDocument ? AppColors.successBg : AppColors.neutralBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasDocument ? AppColors.success : AppColors.divider,
                width: hasDocument ? 2 : 1,
              ),
            ),
            child: isUploading
                ? const Center(child: CircularProgressIndicator())
                : hasDocument
                    ? _UploadedContent(
                        documentPath: documentPath!,
                        onClear: onClear,
                        qualityChecks: qualityChecks,
                      )
                    : _EmptyContent(icon: icon),
          ),
        ),
      ],
    );
  }
}

class _EmptyContent extends StatelessWidget {
  final IconData icon;

  const _EmptyContent({required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 48,
          color: AppColors.textMuted,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.verificationUploadDocumentAction,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${l10n.verificationTakePhotoAction} / ${l10n.verificationChooseFromGalleryAction}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _UploadedContent extends StatelessWidget {
  final String documentPath;
  final VoidCallback? onClear;
  final List<QualityCheck> qualityChecks;

  const _UploadedContent({
    required this.documentPath,
    this.onClear,
    required this.qualityChecks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isLocalFile = !documentPath.startsWith('http');

    return Stack(
      fit: StackFit.expand,
      children: [
        // Preview image
        ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: isLocalFile
              ? Image.file(
                  File(documentPath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _ErrorPlaceholder(),
                )
              : Image.network(
                  documentPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _ErrorPlaceholder(),
                ),
        ),
        
        // Quality checks overlay
        if (qualityChecks.isNotEmpty)
          Positioned(
            left: 8,
            bottom: 8,
            right: 8,
            child: _QualityChecksOverlay(checks: qualityChecks),
          ),
        
        // Success indicator
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        
        // Clear button
        if (onClear != null)
          Positioned(
            top: 8,
            left: 8,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _QualityChecksOverlay extends StatelessWidget {
  final List<QualityCheck> checks;

  const _QualityChecksOverlay({required this.checks});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: checks.map((check) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                check.passed ? Icons.check_circle : Icons.error,
                color: check.passed ? AppColors.success : AppColors.warning,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                check.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.neutralBg,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.textMuted,
          size: 48,
        ),
      ),
    );
  }
}

class QualityCheck {
  final String label;
  final bool passed;

  const QualityCheck({
    required this.label,
    required this.passed,
  });
}

class ImageSourcePicker extends StatelessWidget {
  final ValueChanged<ImageSource> onSelected;

  const ImageSourcePicker({
    super.key,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.camera_alt),
          title: Text(l10n.verificationTakePhotoAction),
          onTap: () {
            Navigator.pop(context);
            onSelected(ImageSource.camera);
          },
        ),
        ListTile(
          leading: const Icon(Icons.photo_library),
          title: Text(l10n.verificationChooseFromGalleryAction),
          onTap: () {
            Navigator.pop(context);
            onSelected(ImageSource.gallery);
          },
        ),
      ],
    );
  }
}
