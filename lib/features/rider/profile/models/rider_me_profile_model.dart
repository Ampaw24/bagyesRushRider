import 'package:equatable/equatable.dart';

/// Full rider onboarding profile from the `/rider/me` v1 API — identity,
/// vehicle, licence, permit, insurance, payout, operating preferences and
/// emergency contact. See the "v1 / rider" Postman collection (profile #1-2, #8).
class RiderMeProfileModel extends Equatable {
  final int? id;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;
  final String? idType; // ghana_card | passport
  final String? idNumber;
  final String? residentialAddress;
  final String? city;

  final String? vehicleType; // motorbike
  final String? plateNumber;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleColour;
  final int? vehicleYear;
  final String? vehicleOwnership; // owned | authorised

  final String? licenceNumber;
  final String? licenceClass;
  final String? licenceExpiresAt;

  final String? riderPermitNumber;
  final String? riderPermitExpiresAt;

  final String? insuranceProvider;
  final String? insurancePolicyNumber;
  final String? insuranceExpiresAt;

  final String? roadworthyExpiresAt;

  final num? maxDeliveryRadiusKm;
  final List<String> operatingAreas;
  final List<String> operatingDays;
  final String? shiftStartTime;
  final String? shiftEndTime;

  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;

  // Payout (PUT rider/me/payout)
  final int? payoutProviderId;
  final String? accountNumber;
  final String? accountName;
  final int? momoProviderId;
  final String? mobileMoneyNumber;

  // Derived / read-only state
  final bool? isOnline;
  final String? photoUrl;
  final String? verificationStatus;
  final String? submittedForReviewAt;

  const RiderMeProfileModel({
    this.id,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.idType,
    this.idNumber,
    this.residentialAddress,
    this.city,
    this.vehicleType,
    this.plateNumber,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleColour,
    this.vehicleYear,
    this.vehicleOwnership,
    this.licenceNumber,
    this.licenceClass,
    this.licenceExpiresAt,
    this.riderPermitNumber,
    this.riderPermitExpiresAt,
    this.insuranceProvider,
    this.insurancePolicyNumber,
    this.insuranceExpiresAt,
    this.roadworthyExpiresAt,
    this.maxDeliveryRadiusKm,
    this.operatingAreas = const [],
    this.operatingDays = const [],
    this.shiftStartTime,
    this.shiftEndTime,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,
    this.payoutProviderId,
    this.accountNumber,
    this.accountName,
    this.momoProviderId,
    this.mobileMoneyNumber,
    this.isOnline,
    this.photoUrl,
    this.verificationStatus,
    this.submittedForReviewAt,
  });

  String get fullName => [firstName, lastName]
      .where((e) => e != null && e.isNotEmpty)
      .join(' ');

  bool get hasPayoutMethod =>
      (payoutProviderId != null && accountNumber != null) ||
      (momoProviderId != null && mobileMoneyNumber != null);

  factory RiderMeProfileModel.fromJson(Map<String, dynamic> json) {
    List<String> stringList(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? const [];

    return RiderMeProfileModel(
      id: json['id'] as int?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      idType: json['id_type'] as String?,
      idNumber: json['id_number'] as String?,
      residentialAddress: json['residential_address'] as String?,
      city: json['city'] as String?,
      vehicleType: json['vehicle_type'] as String?,
      plateNumber: json['plate_number'] as String?,
      vehicleMake: json['vehicle_make'] as String?,
      vehicleModel: json['vehicle_model'] as String?,
      vehicleColour: json['vehicle_colour'] as String?,
      vehicleYear: json['vehicle_year'] as int?,
      vehicleOwnership: json['vehicle_ownership'] as String?,
      licenceNumber: json['licence_number'] as String?,
      licenceClass: json['licence_class'] as String?,
      licenceExpiresAt: json['licence_expires_at'] as String?,
      riderPermitNumber: json['rider_permit_number'] as String?,
      riderPermitExpiresAt: json['rider_permit_expires_at'] as String?,
      insuranceProvider: json['insurance_provider'] as String?,
      insurancePolicyNumber: json['insurance_policy_number'] as String?,
      insuranceExpiresAt: json['insurance_expires_at'] as String?,
      roadworthyExpiresAt: json['roadworthy_expires_at'] as String?,
      maxDeliveryRadiusKm: json['max_delivery_radius_km'] as num?,
      operatingAreas: stringList(json['operating_areas']),
      operatingDays: stringList(json['operating_days']),
      shiftStartTime: json['shift_start_time'] as String?,
      shiftEndTime: json['shift_end_time'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      emergencyContactRelationship:
          json['emergency_contact_relationship'] as String?,
      payoutProviderId: json['payout_provider_id'] as int?,
      accountNumber: json['account_number'] as String?,
      accountName: json['account_name'] as String?,
      momoProviderId: json['momo_provider_id'] as int?,
      mobileMoneyNumber: json['mobile_money_number'] as String?,
      isOnline: json['is_online'] as bool?,
      photoUrl: json['photo_url'] as String?,
      verificationStatus: json['verification_status'] as String?,
      submittedForReviewAt: json['submitted_for_review_at'] as String?,
    );
  }

  /// Full-object body matching the PUT `/rider/me` shape. For partial
  /// updates, build a raw `Map` instead and call
  /// `RiderMeProfileRepository.updateProfile` directly.
  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'date_of_birth': dateOfBirth,
        'id_type': idType,
        'id_number': idNumber,
        'residential_address': residentialAddress,
        'city': city,
        'vehicle_type': vehicleType,
        'plate_number': plateNumber,
        'vehicle_make': vehicleMake,
        'vehicle_model': vehicleModel,
        'vehicle_colour': vehicleColour,
        'vehicle_year': vehicleYear,
        'vehicle_ownership': vehicleOwnership,
        'licence_number': licenceNumber,
        'licence_class': licenceClass,
        'licence_expires_at': licenceExpiresAt,
        'rider_permit_number': riderPermitNumber,
        'rider_permit_expires_at': riderPermitExpiresAt,
        'insurance_provider': insuranceProvider,
        'insurance_policy_number': insurancePolicyNumber,
        'insurance_expires_at': insuranceExpiresAt,
        'roadworthy_expires_at': roadworthyExpiresAt,
        'max_delivery_radius_km': maxDeliveryRadiusKm,
        'operating_areas': operatingAreas,
        'operating_days': operatingDays,
        'shift_start_time': shiftStartTime,
        'shift_end_time': shiftEndTime,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'emergency_contact_relationship': emergencyContactRelationship,
      };

  RiderMeProfileModel copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? idType,
    String? idNumber,
    String? residentialAddress,
    String? city,
    String? vehicleType,
    String? plateNumber,
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleColour,
    int? vehicleYear,
    String? vehicleOwnership,
    String? licenceNumber,
    String? licenceClass,
    String? licenceExpiresAt,
    String? riderPermitNumber,
    String? riderPermitExpiresAt,
    String? insuranceProvider,
    String? insurancePolicyNumber,
    String? insuranceExpiresAt,
    String? roadworthyExpiresAt,
    num? maxDeliveryRadiusKm,
    List<String>? operatingAreas,
    List<String>? operatingDays,
    String? shiftStartTime,
    String? shiftEndTime,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
    int? payoutProviderId,
    String? accountNumber,
    String? accountName,
    int? momoProviderId,
    String? mobileMoneyNumber,
    bool? isOnline,
    String? photoUrl,
    String? verificationStatus,
    String? submittedForReviewAt,
  }) {
    return RiderMeProfileModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      residentialAddress: residentialAddress ?? this.residentialAddress,
      city: city ?? this.city,
      vehicleType: vehicleType ?? this.vehicleType,
      plateNumber: plateNumber ?? this.plateNumber,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColour: vehicleColour ?? this.vehicleColour,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      vehicleOwnership: vehicleOwnership ?? this.vehicleOwnership,
      licenceNumber: licenceNumber ?? this.licenceNumber,
      licenceClass: licenceClass ?? this.licenceClass,
      licenceExpiresAt: licenceExpiresAt ?? this.licenceExpiresAt,
      riderPermitNumber: riderPermitNumber ?? this.riderPermitNumber,
      riderPermitExpiresAt:
          riderPermitExpiresAt ?? this.riderPermitExpiresAt,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      insurancePolicyNumber:
          insurancePolicyNumber ?? this.insurancePolicyNumber,
      insuranceExpiresAt: insuranceExpiresAt ?? this.insuranceExpiresAt,
      roadworthyExpiresAt: roadworthyExpiresAt ?? this.roadworthyExpiresAt,
      maxDeliveryRadiusKm: maxDeliveryRadiusKm ?? this.maxDeliveryRadiusKm,
      operatingAreas: operatingAreas ?? this.operatingAreas,
      operatingDays: operatingDays ?? this.operatingDays,
      shiftStartTime: shiftStartTime ?? this.shiftStartTime,
      shiftEndTime: shiftEndTime ?? this.shiftEndTime,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelationship:
          emergencyContactRelationship ?? this.emergencyContactRelationship,
      payoutProviderId: payoutProviderId ?? this.payoutProviderId,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      momoProviderId: momoProviderId ?? this.momoProviderId,
      mobileMoneyNumber: mobileMoneyNumber ?? this.mobileMoneyNumber,
      isOnline: isOnline ?? this.isOnline,
      photoUrl: photoUrl ?? this.photoUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      submittedForReviewAt:
          submittedForReviewAt ?? this.submittedForReviewAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        vehicleType,
        plateNumber,
        isOnline,
        verificationStatus,
      ];
}

/// A single uploaded rider document (licence, permit, insurance, etc.)
/// from `POST|GET /rider/me/documents/:type`.
class RiderMeDocumentModel extends Equatable {
  final String type;
  final String? url;
  final String? status;
  final String? uploadedAt;

  const RiderMeDocumentModel({
    required this.type,
    this.url,
    this.status,
    this.uploadedAt,
  });

  factory RiderMeDocumentModel.fromJson(
    Map<String, dynamic> json, {
    String? fallbackType,
  }) {
    return RiderMeDocumentModel(
      type: json['type'] as String? ?? fallbackType ?? '',
      url: json['url'] as String?,
      status: json['status'] as String?,
      uploadedAt: json['uploaded_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [type, url, status, uploadedAt];
}
