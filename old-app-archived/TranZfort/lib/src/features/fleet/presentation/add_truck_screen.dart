import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/image_picker_util.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/solid_header.dart';
import '../providers/fleet_providers.dart';

class AddTruckScreen extends ConsumerStatefulWidget {
  const AddTruckScreen({super.key});

  @override
  ConsumerState<AddTruckScreen> createState() => _AddTruckScreenState();
}

class _AddTruckScreenState extends ConsumerState<AddTruckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _truckNumberController = TextEditingController();
  final _tyresController = TextEditingController(text: '6');
  final _capacityController = TextEditingController(text: '10');

  String? _selectedBodyType;
  String? _selectedModelId;
  File? _rcPhoto;
  DateTime? _rcExpiryDate;

  static const _bodyTypes = <String>[
    'open',
    'container',
    'trailer',
    'tanker',
    'refrigerated',
  ];

  @override
  void dispose() {
    _truckNumberController.dispose();
    _tyresController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickRcExpiryDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _rcExpiryDate ?? now,
      firstDate: now.subtract(const Duration(days: 3650)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (selected != null && mounted) {
      setState(() => _rcExpiryDate = selected);
    }
  }

  Future<void> _pickRcPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        final sheetL10n = AppLocalizations.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(sheetL10n.verificationChooseImageSourceTitle),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(sheetL10n.verificationUseCamera),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(sheetL10n.verificationUseGallery),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source == null || !mounted) return;

    final file = await ImagePickerUtil.pickAndCompressImage(
      context: context,
      source: source,
      crop: false,
    );
    if (file != null && mounted) {
      setState(() => _rcPhoto = file);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBodyType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addTruckSelectBodyTypeError)));
      return;
    }
    if (_rcPhoto == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addTruckRcRequired)));
      return;
    }

    await ref
        .read(addTruckProvider.notifier)
        .addTruck(
          truckNumber: _truckNumberController.text.trim(),
          bodyType: _selectedBodyType!,
          tyres: int.tryParse(_tyresController.text.trim()) ?? 6,
          capacityTonnes: double.tryParse(_capacityController.text.trim()) ?? 0,
          rcExpiryDate: _rcExpiryDate,
          truckModelId: _selectedModelId,
          rcPhotoFile: _rcPhoto,
        );

    final state = ref.read(addTruckProvider);
    if (mounted) {
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addTruckSaveFailed)),
        );
      } else {
        ref.invalidate(fleetProvider);
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final addState = ref.watch(addTruckProvider);
    final modelsAsync = ref.watch(truckCatalogProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addTruckTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPaddingH,
          AppSpacing.screenPaddingV,
          AppSpacing.screenPaddingH,
          AppSpacing.screenPaddingV,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SolidHeader(
                title: l10n.addTruckHeroTitle,
                subtitle: l10n.addTruckHeroSubtitle,
                icon: Icons.local_shipping_outlined,
              ),
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                title: l10n.addTruckIdentitySection,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _truckNumberController,
                      decoration: InputDecoration(
                        labelText: l10n.addTruckNumberLabel,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l10n.addTruckNumberRequired
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedBodyType,
                      items: _bodyTypes
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(_bodyTypeLabel(l10n, e)),
                            ),
                          )
                          .toList(),
                      decoration: InputDecoration(
                        labelText: l10n.addTruckBodyTypeLabel,
                      ),
                      onChanged: (v) => setState(() => _selectedBodyType = v),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    modelsAsync.when(
                      data: (models) {
                        return DropdownButtonFormField<String?>(
                          initialValue: _selectedModelId,
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(l10n.addTruckModelManualEntryOption),
                            ),
                            ...models.map(
                              (m) => DropdownMenuItem<String?>(
                                value: m['id']?.toString(),
                                child: Text('${m['make']} ${m['model']}'),
                              ),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: l10n.addTruckModelOptionalLabel,
                          ),
                          onChanged: (v) =>
                              setState(() => _selectedModelId = v),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text(
                        l10n.addTruckCatalogLoadError,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                title: l10n.addTruckSpecificationsSection,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tyresController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.addTruckTyresLabel,
                        ),
                        validator: (v) {
                          final tyres = int.tryParse(v ?? '');
                          if (tyres == null || tyres < 4 || tyres > 22) {
                            return l10n.addTruckTyresRangeError;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _capacityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.addTruckCapacityLabel,
                        ),
                        validator: (v) {
                          final cap = double.tryParse(v ?? '');
                          if (cap == null || cap <= 0) {
                            return l10n.addTruckCapacityInvalid;
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                title: l10n.addTruckDocumentsSection,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.addTruckRcExpiryDateLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    OutlinedButton.icon(
                      onPressed: _pickRcExpiryDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        _rcExpiryDate == null
                            ? l10n.addTruckSelectDateAction
                            : '${_rcExpiryDate!.day.toString().padLeft(2, '0')}/${_rcExpiryDate!.month.toString().padLeft(2, '0')}/${_rcExpiryDate!.year}',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    InkWell(
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                      onTap: _pickRcPhoto,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.buttonRadius,
                          ),
                          border: Border.all(
                            color: _rcPhoto == null
                                ? AppColors.neutralLight
                                : AppColors.success,
                            width: _rcPhoto == null ? 1 : 1.4,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _rcPhoto == null
                                  ? Icons.upload_file_outlined
                                  : Icons.check_circle,
                              color: _rcPhoto == null
                                  ? AppColors.primary
                                  : AppColors.success,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _rcPhoto == null
                                    ? l10n.addTruckUploadRcPhoto
                                    : l10n.addTruckRcUploadedReplace,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              _rcPhoto == null
                                  ? l10n.uploadAction
                                  : l10n.retakeAction,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.verificationImageQualityHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: l10n.addTruckSaveAction,
                isLoading: addState.isLoading,
                onPressed: addState.isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _bodyTypeLabel(AppLocalizations l10n, String bodyType) {
    return switch (bodyType.toLowerCase()) {
      'open' => l10n.postLoadTruckTypeOpen,
      'container' => l10n.postLoadTruckTypeContainer,
      'trailer' => l10n.postLoadTruckTypeTrailer,
      'tanker' => l10n.postLoadTruckTypeTanker,
      'refrigerated' => l10n.postLoadTruckTypeRefrigerated,
      _ => bodyType,
    };
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.neutralLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
