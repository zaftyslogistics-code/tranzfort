import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_picker_util.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/dashboard_verification_banner.dart';
import '../providers/verification_providers.dart';

class TruckerVerificationScreen extends ConsumerStatefulWidget {
  const TruckerVerificationScreen({super.key});

  @override
  ConsumerState<TruckerVerificationScreen> createState() =>
      _TruckerVerificationScreenState();
}

class _TruckerVerificationScreenState
    extends ConsumerState<TruckerVerificationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();
  final _dlController = TextEditingController();

  File? _aadhaarFront;
  File? _aadhaarBack;
  File? _panPhoto;
  File? _dlFrontPhoto;
  File? _dlBackPhoto;

  String? _existingAadhaarFrontUrl;
  String? _existingAadhaarBackUrl;
  String? _existingPanPhotoUrl;
  String? _existingDlFrontUrl;
  String? _existingDlBackUrl;
  String _verificationStatus = 'unverified';
  String? _verificationRejectionReason;
  bool _prefillLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
    });
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    _panController.dispose();
    _dlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(void Function(File file) onPicked) async {
    final file = await ImagePickerUtil.pickAndCompressImage(
      context: context,
      source: ImageSource.gallery,
    );
    if (file != null && mounted) {
      setState(() => onPicked(file));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final hasAadhaarFront =
        _aadhaarFront != null || _existingAadhaarFrontUrl != null;
    final hasAadhaarBack =
        _aadhaarBack != null || _existingAadhaarBackUrl != null;
    final hasPan = _panPhoto != null || _existingPanPhotoUrl != null;
    final hasDlFront = _dlFrontPhoto != null || _existingDlFrontUrl != null;
    final hasDlBack = _dlBackPhoto != null || _existingDlBackUrl != null;

    if (!hasAadhaarFront ||
        !hasAadhaarBack ||
        !hasPan ||
        !hasDlFront ||
        !hasDlBack) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all mandatory documents.')),
      );
      return;
    }

    await ref
        .read(truckerVerificationProvider.notifier)
        .submitVerification(
          aadhaarNumber: _aadhaarController.text.trim(),
          aadhaarFront: _aadhaarFront,
          aadhaarBack: _aadhaarBack,
          panNumber: _panController.text.trim(),
          panPhoto: _panPhoto,
          dlNumber: _dlController.text.trim(),
          dlFrontPhoto: _dlFrontPhoto,
          dlBackPhoto: _dlBackPhoto,
        );

    if (mounted && !ref.read(truckerVerificationProvider).hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification submitted successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final verificationState = ref.watch(truckerVerificationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trucker Verification')),
      body: verificationState.when(
        data: (_) => _buildForm(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Could not load verification details. Please try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(truckerVerificationProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    if (!_prefillLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardVerificationBanner(
              status: _verificationStatus,
              rejectionReason: _verificationRejectionReason,
            ),
            const SizedBox(height: 24),
            Text(
              'Identity Details',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _aadhaarController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Aadhaar Number',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.length != 12)
                  ? 'Aadhaar must be 12 digits'
                  : null,
            ),
            const SizedBox(height: 12),
            _buildImagePickerRow(
              label: 'Upload Aadhaar Front',
              file: _aadhaarFront,
              existingUrl: _existingAadhaarFrontUrl,
              onPicked: (f) => _aadhaarFront = f,
            ),
            const SizedBox(height: 12),
            _buildImagePickerRow(
              label: 'Upload Aadhaar Back',
              file: _aadhaarBack,
              existingUrl: _existingAadhaarBackUrl,
              onPicked: (f) => _aadhaarBack = f,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _panController,
              decoration: const InputDecoration(
                labelText: 'PAN Number',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'PAN is required' : null,
            ),
            const SizedBox(height: 12),
            _buildImagePickerRow(
              label: 'Upload PAN Card',
              file: _panPhoto,
              existingUrl: _existingPanPhotoUrl,
              onPicked: (f) => _panPhoto = f,
            ),
            const SizedBox(height: 24),
            Text(
              'Driving License',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dlController,
              decoration: const InputDecoration(
                labelText: 'DL Number',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'DL number is required' : null,
            ),
            const SizedBox(height: 12),
            _buildImagePickerRow(
              label: 'Upload DL Front',
              file: _dlFrontPhoto,
              existingUrl: _existingDlFrontUrl,
              onPicked: (f) => _dlFrontPhoto = f,
            ),
            const SizedBox(height: 12),
            _buildImagePickerRow(
              label: 'Upload DL Back',
              file: _dlBackPhoto,
              existingUrl: _existingDlBackUrl,
              onPicked: (f) => _dlBackPhoto = f,
            ),
            const SizedBox(height: 36),
            PrimaryButton(label: 'Submit for Verification', onPressed: _submit),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerRow({
    required String label,
    required File? file,
    required void Function(File file) onPicked,
    String? existingUrl,
  }) {
    final hasExisting = existingUrl != null && existingUrl.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        if (file != null || hasExisting)
          const Icon(Icons.check_circle, color: AppColors.success),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => _pickImage(onPicked),
          icon: const Icon(Icons.upload_file),
          label: Text((file != null || hasExisting) ? 'Retake' : 'Upload'),
        ),
      ],
    );
  }

  Future<void> _loadExistingData() async {
    try {
      final data = await ref
          .read(truckerVerificationProvider.notifier)
          .loadExistingData();
      final profile =
          data['profile'] as Map<String, dynamic>? ?? const <String, dynamic>{};
      final trucker =
          data['trucker'] as Map<String, dynamic>? ?? const <String, dynamic>{};

      if (!mounted) return;

      setState(() {
        _aadhaarController.text = (profile['aadhaar_number'] ?? '').toString();
        _panController.text = (profile['pan_number'] ?? '').toString();
        _dlController.text = (trucker['dl_number'] ?? '').toString();

        _existingAadhaarFrontUrl =
            (profile['aadhaar_front_photo_url'] as String?)?.trim().isEmpty ==
                true
            ? null
            : profile['aadhaar_front_photo_url']?.toString();
        _existingAadhaarBackUrl =
            (profile['aadhaar_back_photo_url'] as String?)?.trim().isEmpty ==
                true
            ? null
            : profile['aadhaar_back_photo_url']?.toString();
        _existingPanPhotoUrl =
            (profile['pan_photo_url'] as String?)?.trim().isEmpty == true
            ? null
            : profile['pan_photo_url']?.toString();
        _existingDlFrontUrl =
            (trucker['dl_front_photo_url'] as String?)?.trim().isEmpty == true
            ? null
            : trucker['dl_front_photo_url']?.toString();
        _existingDlBackUrl =
            (trucker['dl_back_photo_url'] as String?)?.trim().isEmpty == true
            ? null
            : trucker['dl_back_photo_url']?.toString();

        _verificationStatus = (profile['verification_status'] ?? 'unverified')
            .toString();
        _verificationRejectionReason = profile['verification_rejection_reason']
            ?.toString();
        _prefillLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _prefillLoaded = true;
      });
    }
  }
}
