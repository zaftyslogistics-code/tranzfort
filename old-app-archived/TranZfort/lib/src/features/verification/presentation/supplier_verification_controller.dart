import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/image_picker_util.dart';
import '../providers/verification_providers.dart';

class SupplierVerificationController {
  final WidgetRef ref;
  final BuildContext context;
  final void Function(VoidCallback) setState;
  final void Function(String) setTtsFieldGuidance;

  SupplierVerificationController({
    required this.ref,
    required this.context,
    required this.setState,
    required this.setTtsFieldGuidance,
  });

  Future<void> showImageSourceSheet(void Function(File) onPicked) async {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(l10n.verificationUseCamera),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final file = await ImagePickerUtil.pickAndCompressImage(
                    context: context,
                    source: ImageSource.camera,
                    quality: 85,
                  );
                  if (file != null) {
                    onPicked(file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.verificationUseGallery),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final file = await ImagePickerUtil.pickAndCompressImage(
                    context: context,
                    source: ImageSource.gallery,
                    quality: 85,
                  );
                  if (file != null) {
                    onPicked(file);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> submitForm({
    required GlobalKey<FormState> formKey,
    required String companyName,
    required String aadhaarNumber,
    required String panNumber,
    required String tanNumber,
    required String gstNumber,
    required String businessLicenceNumber,
    required File? aadhaarFront,
    required File? aadhaarBack,
    required File? panPhoto,
    required File? tanPhoto,
    required File? gstPhoto,
    required File? businessLicenceDoc,
    required bool isEditMode,
  }) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(supplierVerificationProvider.notifier)
        .submitVerification(
          companyName: companyName,
          aadhaarNumber: aadhaarNumber,
          panNumber: panNumber,
          tanNumber: tanNumber,
          gstNumber: gstNumber,
          businessLicenceNumber: businessLicenceNumber,
          aadhaarFront: aadhaarFront,
          aadhaarBack: aadhaarBack,
          panPhoto: panPhoto,
          tanPhoto: tanPhoto,
          gstPhoto: gstPhoto,
          businessLicenceDoc: businessLicenceDoc,
        );

    final verificationState = ref.read(supplierVerificationProvider);
    final success = !verificationState.hasError;

    if (!context.mounted) return;

    final l10n = AppLocalizations.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? l10n.verificationSubmitSuccess
              : l10n.verificationLoadError,
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void handleDocumentTap({
    required File? currentFile,
    required void Function(File) onFilePicked,
    String? ttsGuidance,
  }) {
    if (ttsGuidance != null && ttsGuidance.isNotEmpty) {
      setTtsFieldGuidance(ttsGuidance);
    }
    showImageSourceSheet(onFilePicked);
  }
}
