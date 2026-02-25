import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/image_picker_util.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/dashboard_verification_banner.dart';
import '../providers/verification_providers.dart';

class SupplierVerificationScreen extends ConsumerStatefulWidget {
  const SupplierVerificationScreen({super.key});

  @override
  ConsumerState<SupplierVerificationScreen> createState() =>
      _SupplierVerificationScreenState();
}

class _SupplierVerificationScreenState
    extends ConsumerState<SupplierVerificationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();
  final _gstController = TextEditingController();
  final _businessLicenceController = TextEditingController();

  File? _aadhaarFront;
  File? _aadhaarBack;
  File? _panPhoto;
  File? _gstPhoto;
  File? _businessLicenceDoc;

  String? _existingAadhaarFrontUrl;
  String? _existingAadhaarBackUrl;
  String? _existingPanPhotoUrl;
  String? _existingGstPhotoUrl;
  String? _existingBusinessLicenceUrl;
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
    _companyNameController.dispose();
    _aadhaarController.dispose();
    _panController.dispose();
    _gstController.dispose();
    _businessLicenceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(void Function(File) onPicked) async {
    final file = await ImagePickerUtil.pickAndCompressImage(
      context: context,
      source: ImageSource.gallery,
    );
    if (file != null) {
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
    final hasGst = _gstPhoto != null || _existingGstPhotoUrl != null;

    if (!hasAadhaarFront || !hasAadhaarBack || !hasPan || !hasGst) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all mandatory documents.')),
      );
      return;
    }

    await ref
        .read(supplierVerificationProvider.notifier)
        .submitVerification(
          companyName: _companyNameController.text.trim(),
          aadhaarNumber: _aadhaarController.text.trim(),
          aadhaarFront: _aadhaarFront,
          aadhaarBack: _aadhaarBack,
          panNumber: _panController.text.trim(),
          panPhoto: _panPhoto,
          gstNumber: _gstController.text.trim(),
          gstPhoto: _gstPhoto,
          businessLicenceNumber: _businessLicenceController.text.trim(),
          businessLicenceDoc: _businessLicenceDoc,
        );

    if (mounted && !ref.read(supplierVerificationProvider).hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification submitted successfully!')),
      );
      // Let GoRouter redirect based on the updated profile state
    }
  }

  @override
  Widget build(BuildContext context) {
    final verificationState = ref.watch(supplierVerificationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Supplier Verification')),
      body: verificationState.when(
        data: (_) => _buildForm(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Could not load verification details. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(supplierVerificationProvider),
                child: const Text('Retry'),
              ),
            ],
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
      padding: const EdgeInsets.all(24.0),
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
              'Company Details',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: 'Company Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gstController,
              decoration: const InputDecoration(
                labelText: 'GST Number',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildImagePickerRow(
              label: 'Upload GST Certificate',
              file: _gstPhoto,
              existingUrl: _existingGstPhotoUrl,
              onPicked: (f) => _gstPhoto = f,
            ),
            const SizedBox(height: 32),

            Text(
              'Personal Details (Authorized Signatory)',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _panController,
              decoration: const InputDecoration(
                labelText: 'PAN Number',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildImagePickerRow(
              label: 'Upload PAN Card',
              file: _panPhoto,
              existingUrl: _existingPanPhotoUrl,
              onPicked: (f) => _panPhoto = f,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _aadhaarController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Aadhaar Number',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.length != 12 ? 'Must be 12 digits' : null,
            ),
            const SizedBox(height: 16),
            _buildImagePickerRow(
              label: 'Upload Aadhaar Front',
              file: _aadhaarFront,
              existingUrl: _existingAadhaarFrontUrl,
              onPicked: (f) => _aadhaarFront = f,
            ),
            const SizedBox(height: 16),
            _buildImagePickerRow(
              label: 'Upload Aadhaar Back',
              file: _aadhaarBack,
              existingUrl: _existingAadhaarBackUrl,
              onPicked: (f) => _aadhaarBack = f,
            ),

            const SizedBox(height: 32),
            Text(
              'Optional Details',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessLicenceController,
              decoration: const InputDecoration(
                labelText: 'Business Licence Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _buildImagePickerRow(
              label: 'Upload Business Licence',
              file: _businessLicenceDoc,
              existingUrl: _existingBusinessLicenceUrl,
              onPicked: (f) => _businessLicenceDoc = f,
            ),

            const SizedBox(height: 48),
            PrimaryButton(label: 'Submit for Verification', onPressed: _submit),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerRow({
    required String label,
    required File? file,
    required void Function(File) onPicked,
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
          .read(supplierVerificationProvider.notifier)
          .loadExistingData();
      final profile =
          data['profile'] as Map<String, dynamic>? ?? const <String, dynamic>{};
      final supplier =
          data['supplier'] as Map<String, dynamic>? ??
          const <String, dynamic>{};

      if (!mounted) return;

      setState(() {
        _companyNameController.text = (supplier['company_name'] ?? '')
            .toString();
        _aadhaarController.text = (profile['aadhaar_number'] ?? '').toString();
        _panController.text = (profile['pan_number'] ?? '').toString();
        _gstController.text = (supplier['gst_number'] ?? '').toString();
        _businessLicenceController.text =
            (supplier['business_licence_number'] ?? '').toString();

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
        _existingGstPhotoUrl =
            (supplier['gst_photo_url'] as String?)?.trim().isEmpty == true
            ? null
            : supplier['gst_photo_url']?.toString();
        _existingBusinessLicenceUrl =
            (supplier['business_licence_doc_url'] as String?)?.trim().isEmpty ==
                true
            ? null
            : supplier['business_licence_doc_url']?.toString();

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
