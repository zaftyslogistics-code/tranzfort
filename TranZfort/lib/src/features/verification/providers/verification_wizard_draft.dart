import '../data/verification_repository.dart';

/// Draft data holder for verification wizard state
class VerificationDraft {
  final String? profilePhotoPath;
  final String? aadhaarNumber;
  final String? aadhaarFrontPath;
  final String? aadhaarBackPath;
  final String? panNumber;
  final String? panDocumentPath;
  final TruckDraft? truck;
  final String? companyName;
  final String? businessLicenseNumber;
  final String? businessLicensePath;
  final String? gstNumber;
  final String? gstCertificatePath;
  final WizardLocation? location;

  const VerificationDraft({
    this.profilePhotoPath,
    this.aadhaarNumber,
    this.aadhaarFrontPath,
    this.aadhaarBackPath,
    this.panNumber,
    this.panDocumentPath,
    this.truck,
    this.companyName,
    this.businessLicenseNumber,
    this.businessLicensePath,
    this.gstNumber,
    this.gstCertificatePath,
    this.location,
  });

  bool get isEmpty =>
      profilePhotoPath == null &&
      aadhaarNumber == null &&
      aadhaarFrontPath == null &&
      aadhaarBackPath == null &&
      panNumber == null &&
      panDocumentPath == null &&
      truck == null &&
      companyName == null &&
      businessLicenseNumber == null &&
      businessLicensePath == null &&
      gstNumber == null &&
      gstCertificatePath == null &&
      location == null;

  factory VerificationDraft.fromDetail(VerificationDetail detail) {
    return VerificationDraft(
      profilePhotoPath: detail.profilePhotoDocumentPath,
      aadhaarNumber: detail.aadhaarNumber,
      aadhaarFrontPath: detail.aadhaarFrontDocumentPath,
      aadhaarBackPath: detail.aadhaarBackDocumentPath,
      panNumber: detail.panNumber,
      panDocumentPath: detail.panDocumentPath,
      companyName: detail.companyName,
      businessLicenseNumber: detail.businessLicenceNumber,
      businessLicensePath: detail.businessLicenceDocumentPath,
      gstNumber: detail.gstNumber,
      gstCertificatePath: detail.gstCertificateDocumentPath,
      location: detail.hasVerificationLocation
          ? WizardLocation(
              city: detail.verificationLocationCity ?? '',
              state: detail.verificationLocationState,
              latitude: detail.verificationLatitude ?? 0,
              longitude: detail.verificationLongitude ?? 0,
              source: 'existing',
            )
          : null,
    );
  }

  // Validation getters
  bool get hasProfilePhoto => profilePhotoPath?.isNotEmpty ?? false;
  
  bool get hasIdentityComplete {
    return (aadhaarNumber?.length == 12) &&
        (panNumber?.isNotEmpty ?? false) &&
        (aadhaarFrontPath?.isNotEmpty ?? false) &&
        (aadhaarBackPath?.isNotEmpty ?? false) &&
        (panDocumentPath?.isNotEmpty ?? false);
  }
  
  bool get hasTruckComplete {
    final t = truck;
    return t != null &&
        t.truckNumber.isNotEmpty &&
        t.capacityTonnes > 0 &&
        (t.rcDocumentPath?.isNotEmpty ?? false);
  }
  
  bool get hasBusinessComplete {
    return (companyName?.isNotEmpty ?? false) &&
        (businessLicenseNumber?.isNotEmpty ?? false) &&
        (businessLicensePath?.isNotEmpty ?? false) &&
        location != null;
  }

  VerificationDraft mergeMissingFrom(VerificationDraft other) {
    return VerificationDraft(
      profilePhotoPath: profilePhotoPath ?? other.profilePhotoPath,
      aadhaarNumber: aadhaarNumber ?? other.aadhaarNumber,
      aadhaarFrontPath: aadhaarFrontPath ?? other.aadhaarFrontPath,
      aadhaarBackPath: aadhaarBackPath ?? other.aadhaarBackPath,
      panNumber: panNumber ?? other.panNumber,
      panDocumentPath: panDocumentPath ?? other.panDocumentPath,
      truck: truck ?? other.truck,
      companyName: companyName ?? other.companyName,
      businessLicenseNumber: businessLicenseNumber ?? other.businessLicenseNumber,
      businessLicensePath: businessLicensePath ?? other.businessLicensePath,
      gstNumber: gstNumber ?? other.gstNumber,
      gstCertificatePath: gstCertificatePath ?? other.gstCertificatePath,
      location: location ?? other.location,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'profilePhotoPath': profilePhotoPath,
      'aadhaarNumber': aadhaarNumber,
      'aadhaarFrontPath': aadhaarFrontPath,
      'aadhaarBackPath': aadhaarBackPath,
      'panNumber': panNumber,
      'panDocumentPath': panDocumentPath,
      'truck': truck?.toJson(),
      'companyName': companyName,
      'businessLicenseNumber': businessLicenseNumber,
      'businessLicensePath': businessLicensePath,
      'gstNumber': gstNumber,
      'gstCertificatePath': gstCertificatePath,
      'location': location?.toJson(),
    };
  }

  factory VerificationDraft.fromJson(Map<String, dynamic> json) {
    final rawTruck = json['truck'];
    final rawLocation = json['location'];
    return VerificationDraft(
      profilePhotoPath: json['profilePhotoPath']?.toString(),
      aadhaarNumber: json['aadhaarNumber']?.toString(),
      aadhaarFrontPath: json['aadhaarFrontPath']?.toString(),
      aadhaarBackPath: json['aadhaarBackPath']?.toString(),
      panNumber: json['panNumber']?.toString(),
      panDocumentPath: json['panDocumentPath']?.toString(),
      truck: rawTruck is Map<String, dynamic>
          ? TruckDraft.fromJson(rawTruck)
          : rawTruck is Map
              ? TruckDraft.fromJson(rawTruck.map((key, value) => MapEntry(key.toString(), value)))
              : null,
      companyName: json['companyName']?.toString(),
      businessLicenseNumber: json['businessLicenseNumber']?.toString(),
      businessLicensePath: json['businessLicensePath']?.toString(),
      gstNumber: json['gstNumber']?.toString(),
      gstCertificatePath: json['gstCertificatePath']?.toString(),
      location: rawLocation is Map<String, dynamic>
          ? WizardLocation.fromJson(rawLocation)
          : rawLocation is Map
              ? WizardLocation.fromJson(rawLocation.map((key, value) => MapEntry(key.toString(), value)))
              : null,
    );
  }

  VerificationDraft copyWith({
    String? profilePhotoPath,
    String? aadhaarNumber,
    String? aadhaarFrontPath,
    String? aadhaarBackPath,
    String? panNumber,
    String? panDocumentPath,
    TruckDraft? truck,
    String? companyName,
    String? businessLicenseNumber,
    String? businessLicensePath,
    String? gstNumber,
    String? gstCertificatePath,
    WizardLocation? location,
    bool clearProfilePhoto = false,
    bool clearAadhaarNumber = false,
    bool clearAadhaarFront = false,
    bool clearAadhaarBack = false,
    bool clearPanNumber = false,
    bool clearPanDocument = false,
    bool clearTruck = false,
    bool clearCompanyName = false,
    bool clearBusinessLicenseNumber = false,
    bool clearBusinessLicense = false,
    bool clearGstNumber = false,
    bool clearGstCertificate = false,
    bool clearLocation = false,
  }) {
    return VerificationDraft(
      profilePhotoPath: clearProfilePhoto ? null : (profilePhotoPath ?? this.profilePhotoPath),
      aadhaarNumber: clearAadhaarNumber ? null : (aadhaarNumber ?? this.aadhaarNumber),
      aadhaarFrontPath: clearAadhaarFront ? null : (aadhaarFrontPath ?? this.aadhaarFrontPath),
      aadhaarBackPath: clearAadhaarBack ? null : (aadhaarBackPath ?? this.aadhaarBackPath),
      panNumber: clearPanNumber ? null : (panNumber ?? this.panNumber),
      panDocumentPath: clearPanDocument ? null : (panDocumentPath ?? this.panDocumentPath),
      truck: clearTruck ? null : (truck ?? this.truck),
      companyName: clearCompanyName ? null : (companyName ?? this.companyName),
      businessLicenseNumber:
          clearBusinessLicenseNumber ? null : (businessLicenseNumber ?? this.businessLicenseNumber),
      businessLicensePath: clearBusinessLicense ? null : (businessLicensePath ?? this.businessLicensePath),
      gstNumber: clearGstNumber ? null : (gstNumber ?? this.gstNumber),
      gstCertificatePath: clearGstCertificate ? null : (gstCertificatePath ?? this.gstCertificatePath),
      location: clearLocation ? null : (location ?? this.location),
    );
  }
}

class TruckDraft {
  final String truckNumber;
  final String bodyType;
  final int tyres;
  final double capacityTonnes;
  final String? rcDocumentPath;
  final String? truckPhotoPath;

  const TruckDraft({
    this.truckNumber = '',
    this.bodyType = 'open',
    this.tyres = 10,
    this.capacityTonnes = 0,
    this.rcDocumentPath,
    this.truckPhotoPath,
  });

  TruckDraft copyWith({
    String? truckNumber,
    String? bodyType,
    int? tyres,
    double? capacityTonnes,
    String? rcDocumentPath,
    String? truckPhotoPath,
    bool clearRcDocument = false,
    bool clearTruckPhoto = false,
  }) {
    return TruckDraft(
      truckNumber: truckNumber ?? this.truckNumber,
      bodyType: bodyType ?? this.bodyType,
      tyres: tyres ?? this.tyres,
      capacityTonnes: capacityTonnes ?? this.capacityTonnes,
      rcDocumentPath: clearRcDocument ? null : (rcDocumentPath ?? this.rcDocumentPath),
      truckPhotoPath: clearTruckPhoto ? null : (truckPhotoPath ?? this.truckPhotoPath),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'truckNumber': truckNumber,
      'bodyType': bodyType,
      'tyres': tyres,
      'capacityTonnes': capacityTonnes,
      'rcDocumentPath': rcDocumentPath,
      'truckPhotoPath': truckPhotoPath,
    };
  }

  factory TruckDraft.fromJson(Map<String, dynamic> json) {
    return TruckDraft(
      truckNumber: json['truckNumber']?.toString() ?? '',
      bodyType: json['bodyType']?.toString() ?? 'open',
      tyres: (json['tyres'] as num?)?.toInt() ?? 10,
      capacityTonnes: (json['capacityTonnes'] as num?)?.toDouble() ?? 0,
      rcDocumentPath: json['rcDocumentPath']?.toString(),
      truckPhotoPath: json['truckPhotoPath']?.toString(),
    );
  }
}

class WizardLocation {
  final String city;
  final String? state;
  final double latitude;
  final double longitude;
  final String source;

  const WizardLocation({
    required this.city,
    this.state,
    required this.latitude,
    required this.longitude,
    required this.source,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'source': source,
    };
  }

  factory WizardLocation.fromJson(Map<String, dynamic> json) {
    return WizardLocation(
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      source: json['source']?.toString() ?? 'manual',
    );
  }
}
