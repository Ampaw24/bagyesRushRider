// ── Doc key constants ──────────────────────────────────────────────────────
abstract final class KycDocKey {
  static const idFront = 'identity_id_front';
  static const idBack = 'identity_id_back';
  static const selfie = 'identity_selfie';
  static const licensePhoto = 'license_photo';
  static const vehicleRegDoc = 'vehicle_reg_doc';
  static const vehicleInsurance = 'vehicle_insurance';

  static const List<String> all = [
    idFront, idBack, selfie, licensePhoto, vehicleRegDoc, vehicleInsurance,
  ];

  static const List<String> required = [
    idFront, idBack, selfie, licensePhoto, vehicleRegDoc,
  ];
}

// ── Sub-models ─────────────────────────────────────────────────────────────

class KycIdentityData {
  final String nationalId;
  final DateTime? dateOfBirth;
  final String address;

  const KycIdentityData({
    this.nationalId = '',
    this.dateOfBirth,
    this.address = '',
  });

  KycIdentityData copyWith({
    String? nationalId,
    DateTime? dateOfBirth,
    String? address,
  }) =>
      KycIdentityData(
        nationalId: nationalId ?? this.nationalId,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        address: address ?? this.address,
      );

  bool get isValid =>
      nationalId.trim().length >= 4 &&
      dateOfBirth != null &&
      address.trim().length >= 5;
}

class KycLicenseData {
  final String licenseNumber;
  final DateTime? expiryDate;

  const KycLicenseData({
    this.licenseNumber = '',
    this.expiryDate,
  });

  KycLicenseData copyWith({
    String? licenseNumber,
    DateTime? expiryDate,
  }) =>
      KycLicenseData(
        licenseNumber: licenseNumber ?? this.licenseNumber,
        expiryDate: expiryDate ?? this.expiryDate,
      );

  bool get isValid =>
      licenseNumber.trim().length >= 4 && expiryDate != null;
}

class KycVehicleData {
  final String vehicleType;
  final String brand;
  final String model;
  final String plateNumber;
  final String color;

  const KycVehicleData({
    this.vehicleType = '',
    this.brand = '',
    this.model = '',
    this.plateNumber = '',
    this.color = '',
  });

  KycVehicleData copyWith({
    String? vehicleType,
    String? brand,
    String? model,
    String? plateNumber,
    String? color,
  }) =>
      KycVehicleData(
        vehicleType: vehicleType ?? this.vehicleType,
        brand: brand ?? this.brand,
        model: model ?? this.model,
        plateNumber: plateNumber ?? this.plateNumber,
        color: color ?? this.color,
      );

  bool get isValid =>
      vehicleType.isNotEmpty &&
      brand.trim().isNotEmpty &&
      model.trim().isNotEmpty &&
      plateNumber.trim().isNotEmpty &&
      color.trim().isNotEmpty;
}

// ── Top-level aggregate ────────────────────────────────────────────────────

class KycFormData {
  final KycIdentityData identity;
  final KycLicenseData license;
  final KycVehicleData vehicle;

  const KycFormData({
    this.identity = const KycIdentityData(),
    this.license = const KycLicenseData(),
    this.vehicle = const KycVehicleData(),
  });

  KycFormData copyWith({
    KycIdentityData? identity,
    KycLicenseData? license,
    KycVehicleData? vehicle,
  }) =>
      KycFormData(
        identity: identity ?? this.identity,
        license: license ?? this.license,
        vehicle: vehicle ?? this.vehicle,
      );
}
