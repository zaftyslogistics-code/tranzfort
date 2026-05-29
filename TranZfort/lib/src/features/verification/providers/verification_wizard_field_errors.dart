part of 'verification_wizard_provider.dart';

Map<String, String> mapRepositoryFailureToWizardFields(
  AppFailure failure, {
  required String wizardFieldKey,
}) {
  if (failure is ValidationFailure) {
    final mapped = <String, String>{};
    for (final entry in failure.fieldErrors?.entries ?? const <MapEntry<String, String>>[]) {
      final key = mapRepositoryFieldKeyToWizard(entry.key);
      if (key != null && entry.value.trim().isNotEmpty) {
        mapped[key] = entry.value.trim();
      }
    }
    if (mapped.isEmpty && failure.message.trim().isNotEmpty) {
      mapped[wizardFieldKey] = failure.message.trim();
    }
    return mapped;
  }

  if (failure.message.trim().isNotEmpty) {
    return {wizardFieldKey: failure.message.trim()};
  }
  return const {};
}

String? mapRepositoryFieldKeyToWizard(String key) {
  return switch (key) {
    'profile_photo_document_path' || 'profilePhoto' => 'profilePhoto',
    'aadhaar_front_document_path' || 'aadhaarFront' => 'aadhaarFront',
    'aadhaar_back_document_path' || 'aadhaarBack' => 'aadhaarBack',
    'pan_document_path' || 'panDocument' => 'panDocument',
    'business_licence_document_path' || 'businessLicense' => 'businessLicense',
    'gst_certificate_document_path' || 'gstCertificate' => 'gstCertificate',
    'truck_rc_document_path' || 'rc_document_path' || 'rcDocument' => 'rcDocument',
    'truck_photo_document_path' || 'truckPhoto' => 'truckPhoto',
    'aadhaar_number' || 'aadhaarNumber' => 'aadhaarNumber',
    'pan_number' || 'panNumber' => 'panNumber',
    'company_name' || 'companyName' => 'companyName',
    'business_licence_number' || 'businessLicenseNumber' => 'businessLicenseNumber',
    'truck_number' || 'truckNumber' => 'truckNumber',
    'capacity_tonnes' || 'capacityTonnes' => 'capacityTonnes',
    _ => null,
  };
}
