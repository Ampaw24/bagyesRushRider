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

  /// Maps each local doc key to the `:type` slug `POST/GET
  /// rider/me/documents/:type` expects. `selfie` maps to `null` because it
  /// goes through the dedicated `POST rider/me/photo` endpoint instead.
  ///
  /// The backend's accepted `:type` set is **not documented** anywhere in
  /// the "v1 / rider" Postman collection (the doc's own endpoint #5 note:
  /// "confirm the exact strings with the backend"). Only `licence` and
  /// `insurance` are directly implied by the `PUT rider/me` field list —
  /// `ghana_card`, `ghana_card_back` and `vehicle_registration` below are
  /// unconfirmed guesses. Verify against the real backend before relying on
  /// them; this map is the only place that needs to change once confirmed.
  static const Map<String, String?> riderMeTypeSlug = {
    idFront: 'ghana_card',
    idBack: 'ghana_card_back',
    selfie: null,
    licensePhoto: 'licence',
    vehicleRegDoc: 'vehicle_registration',
    vehicleInsurance: 'insurance',
  };
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
