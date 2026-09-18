import 'package:equatable/equatable.dart';

import 'package:delivery_boy/core/utils/json_utils.dart';

/// Upload state of one verification document, from `/rider/me`'s
/// `documents` map. [required] is decided server-side and can change with
/// other answers — e.g. `vehicle_authorisation` once ownership is
/// "authorised".
class RiderDocumentState extends Equatable {
  final bool uploaded;
  final bool required;

  const RiderDocumentState({this.uploaded = false, this.required = false});

  factory RiderDocumentState.fromJson(Object? json) {
    if (json is! Map) return const RiderDocumentState();
    return RiderDocumentState(
      uploaded: json['uploaded'] == true,
      required: json['required'] == true,
    );
  }

  @override
  List<Object?> get props => [uploaded, required];
}

/// Payout destination from `/rider/me`'s `payout` object. Account numbers
/// only ever come back masked (last 4 digits).
class RiderPayoutInfo extends Equatable {
  final String? bankName;
  final int? payoutProviderId;
  final String? accountName;
  final String? accountNumberLast4;
  final String? momoProviderName;
  final int? momoProviderId;
  final String? mobileMoneyNumberLast4;
  final bool isConfigured;

  const RiderPayoutInfo({
    this.bankName,
    this.payoutProviderId,
    this.accountName,
    this.accountNumberLast4,
    this.momoProviderName,
    this.momoProviderId,
    this.mobileMoneyNumberLast4,
    this.isConfigured = false,
  });

  bool get isMobileMoney => momoProviderId != null;

  factory RiderPayoutInfo.fromJson(Object? json) {
    if (json is! Map) return const RiderPayoutInfo();
    return RiderPayoutInfo(
      bankName: _nameOf(json['bank']),
      payoutProviderId: _int(json['payout_provider_id']),
      accountName: nonEmptyString(json['account_name']),
      accountNumberLast4: nonEmptyString(json['account_number_last4']),
      momoProviderName: _nameOf(json['momo_provider']),
      momoProviderId: _int(json['momo_provider_id']),
      mobileMoneyNumberLast4:
          nonEmptyString(json['mobile_money_number_last4']),
      isConfigured: json['is_configured'] == true,
    );
  }

  @override
  List<Object?> get props => [
        payoutProviderId,
        accountNumberLast4,
        momoProviderId,
        mobileMoneyNumberLast4,
        isConfigured,
      ];
}

/// The rider's full profile from `GET /rider/me`.
///
/// The API nests related fields (`identity`, `vehicle`, `licence`,
/// `insurance`, `availability`, `emergency_contact`, `payout`); this model
/// flattens them. Completeness is the server's call — see
/// [isProfileComplete], [missingProfileFields] and [documents] — and
/// [canGoOnline] is its gate for going online.
class RiderMeProfileModel extends Equatable {
  final int? id;
  final String? riderCode;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? dateOfBirth;
  final String? residentialAddress;
  final String? city;

  /// `profile_photo_url` (or the older `photo_url`); null when not set.
  final String? photoUrl;

  final String? idType; // ghana_card | passport
  final String? idNumber;

  final int? vehicleTypeId;
  final String? vehicleType;
  final String? vehicleTypeLabel;
  final String? plateNumber;
  final int? vehicleMakeId;
  final String? vehicleMake;
  final int? vehicleModelId;
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

  /// Credential keys (e.g. `licence`) the server reports as expired or
  /// expiring soon.
  final List<String> expiredCredentials;
  final List<String> expiringCredentials;

  final List<String> operatingAreas;
  final List<String> operatingDays;
  final String? shiftStartTime;
  final String? shiftEndTime;

  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;

  /// A newer rider agreement than the one accepted is in force.
  final bool agreementNeedsReacceptance;

  final String? status; // e.g. pending_review
  final String? statusLabel;
  final String? rejectionReason;
  final bool isActive;
  final bool isProfileComplete;

  /// Server field keys still outstanding, e.g. `licence_number`,
  /// `payout_details`.
  final List<String> missingProfileFields;
  final String? approvedAt;

  final bool? isOnline;
  final bool canGoOnline;
  final num? maxDeliveryRadiusKm;

  /// Keyed by document slug, e.g. `drivers_licence_front`.
  final Map<String, RiderDocumentState> documents;
  final String? documentsStatus;
  final String? documentsReviewedAt;

  final RiderPayoutInfo payout;

  const RiderMeProfileModel({
    this.id,
    this.riderCode,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.dateOfBirth,
    this.residentialAddress,
    this.city,
    this.photoUrl,
    this.idType,
    this.idNumber,
    this.vehicleTypeId,
    this.vehicleType,
    this.vehicleTypeLabel,
    this.plateNumber,
    this.vehicleMakeId,
    this.vehicleMake,
    this.vehicleModelId,
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
    this.expiredCredentials = const [],
    this.expiringCredentials = const [],
    this.operatingAreas = const [],
    this.operatingDays = const [],
    this.shiftStartTime,
    this.shiftEndTime,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,
    this.agreementNeedsReacceptance = false,
    this.status,
    this.statusLabel,
    this.rejectionReason,
    this.isActive = false,
    this.isProfileComplete = false,
    this.missingProfileFields = const [],
    this.approvedAt,
    this.isOnline,
    this.canGoOnline = false,
    this.maxDeliveryRadiusKm,
    this.documents = const {},
    this.documentsStatus,
    this.documentsReviewedAt,
    this.payout = const RiderPayoutInfo(),
  });

  String get fullName => [firstName, lastName]
      .where((e) => e != null && e.isNotEmpty)
      .join(' ');

  factory RiderMeProfileModel.fromJson(Map<String, dynamic> json) {
    final identity = _map(json['identity']);
    final vehicle = _map(json['vehicle']);
    final licence = _map(json['licence']);
    final insurance = _map(json['insurance']);
    final credentials = _map(json['credentials']);
    final availability = _map(json['availability']);
    final consent = _map(json['consent']);
    final emergency = _map(json['emergency_contact']);
    final documents = _map(json['documents']);

    return RiderMeProfileModel(
      id: _int(json['id']),
      riderCode: nonEmptyString(json['rider_code']),
      firstName: nonEmptyString(json['first_name']),
      lastName: nonEmptyString(json['last_name']),
      email: nonEmptyString(json['email']),
      phone: nonEmptyString(json['phone']),
      dateOfBirth: nonEmptyString(json['date_of_birth']),
      residentialAddress: nonEmptyString(json['residential_address']),
      city: nonEmptyString(json['city']),
      photoUrl: nonEmptyString(json['profile_photo_url']) ??
          nonEmptyString(json['photo_url']),
      idType: nonEmptyString(identity['type']),
      idNumber: nonEmptyString(identity['number']),
      vehicleTypeId: _int(vehicle['type_id']),
      vehicleType: nonEmptyString(vehicle['type']),
      vehicleTypeLabel: nonEmptyString(vehicle['type_label']),
      plateNumber: nonEmptyString(vehicle['plate_number']),
      vehicleMakeId: _int(vehicle['make_id']),
      vehicleMake: _nameOf(vehicle['make']),
      vehicleModelId: _int(vehicle['model_id']),
      vehicleModel: _nameOf(vehicle['model']),
      vehicleColour: nonEmptyString(vehicle['colour']),
      vehicleYear: _int(vehicle['year']),
      vehicleOwnership: nonEmptyString(vehicle['ownership']),
      licenceNumber: nonEmptyString(licence['number']),
      licenceClass: nonEmptyString(licence['class']),
      licenceExpiresAt: nonEmptyString(licence['expires_at']),
      riderPermitNumber: nonEmptyString(licence['permit_number']),
      riderPermitExpiresAt: nonEmptyString(licence['permit_expires_at']),
      insuranceProvider: nonEmptyString(insurance['provider']),
      insurancePolicyNumber: nonEmptyString(insurance['policy_number']),
      insuranceExpiresAt: nonEmptyString(insurance['expires_at']),
      roadworthyExpiresAt: nonEmptyString(insurance['roadworthy_expires_at']),
      expiredCredentials: _strings(credentials['expired']),
      expiringCredentials: _strings(credentials['expiring_soon']),
      operatingAreas: _strings(availability['operating_areas']),
      operatingDays: _strings(availability['operating_days']),
      shiftStartTime: nonEmptyString(availability['shift_start_time']),
      shiftEndTime: nonEmptyString(availability['shift_end_time']),
      emergencyContactName: nonEmptyString(emergency['name']),
      emergencyContactPhone: nonEmptyString(emergency['phone']),
      emergencyContactRelationship: nonEmptyString(emergency['relationship']),
      agreementNeedsReacceptance: consent['needs_reacceptance'] == true,
      status: nonEmptyString(json['status']),
      statusLabel: nonEmptyString(json['status_label']),
      rejectionReason: nonEmptyString(json['rejection_reason']),
      isActive: json['is_active'] == true,
      isProfileComplete: json['is_profile_complete'] == true,
      missingProfileFields: _strings(json['missing_profile_fields']),
      approvedAt: nonEmptyString(json['approved_at']),
      isOnline: json['is_online'] as bool?,
      canGoOnline: json['can_go_online'] == true,
      maxDeliveryRadiusKm: json['max_delivery_radius_km'] as num?,
      documents: {
        for (final entry in documents.entries)
          entry.key: RiderDocumentState.fromJson(entry.value),
      },
      documentsStatus: nonEmptyString(json['documents_status']),
      documentsReviewedAt: nonEmptyString(json['documents_reviewed_at']),
      payout: RiderPayoutInfo.fromJson(json['payout']),
    );
  }

  /// Only the fields the app patches locally after a successful action;
  /// everything else is refreshed from `GET /rider/me`.
  RiderMeProfileModel copyWith({String? photoUrl, bool? isOnline}) {
    return RiderMeProfileModel(
      id: id,
      riderCode: riderCode,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      dateOfBirth: dateOfBirth,
      residentialAddress: residentialAddress,
      city: city,
      photoUrl: photoUrl ?? this.photoUrl,
      idType: idType,
      idNumber: idNumber,
      vehicleTypeId: vehicleTypeId,
      vehicleType: vehicleType,
      vehicleTypeLabel: vehicleTypeLabel,
      plateNumber: plateNumber,
      vehicleMakeId: vehicleMakeId,
      vehicleMake: vehicleMake,
      vehicleModelId: vehicleModelId,
      vehicleModel: vehicleModel,
      vehicleColour: vehicleColour,
      vehicleYear: vehicleYear,
      vehicleOwnership: vehicleOwnership,
      licenceNumber: licenceNumber,
      licenceClass: licenceClass,
      licenceExpiresAt: licenceExpiresAt,
      riderPermitNumber: riderPermitNumber,
      riderPermitExpiresAt: riderPermitExpiresAt,
      insuranceProvider: insuranceProvider,
      insurancePolicyNumber: insurancePolicyNumber,
      insuranceExpiresAt: insuranceExpiresAt,
      roadworthyExpiresAt: roadworthyExpiresAt,
      expiredCredentials: expiredCredentials,
      expiringCredentials: expiringCredentials,
      operatingAreas: operatingAreas,
      operatingDays: operatingDays,
      shiftStartTime: shiftStartTime,
      shiftEndTime: shiftEndTime,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      emergencyContactRelationship: emergencyContactRelationship,
      agreementNeedsReacceptance: agreementNeedsReacceptance,
      status: status,
      statusLabel: statusLabel,
      rejectionReason: rejectionReason,
      isActive: isActive,
      isProfileComplete: isProfileComplete,
      missingProfileFields: missingProfileFields,
      approvedAt: approvedAt,
      isOnline: isOnline ?? this.isOnline,
      canGoOnline: canGoOnline,
      maxDeliveryRadiusKm: maxDeliveryRadiusKm,
      documents: documents,
      documentsStatus: documentsStatus,
      documentsReviewedAt: documentsReviewedAt,
      payout: payout,
    );
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        photoUrl,
        plateNumber,
        status,
        isOnline,
        canGoOnline,
        isProfileComplete,
        missingProfileFields,
        documents,
        payout,
      ];
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? value.cast<String, dynamic>() : const {};

int? _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('${value ?? ''}');

List<String> _strings(Object? value) =>
    value is List ? value.map((e) => e.toString()).toList() : const [];

/// A reference that may arrive as a plain name or as `{id, name}`.
String? _nameOf(Object? value) =>
    value is Map ? nonEmptyString(value['name']) : nonEmptyString(value);

/// A single buffered position ping for `POST /rider/me/location/batch`.
///
/// `heading` is omitted from [toJson] when null — platform location APIs
/// return -1/NaN for an unknown heading, and sending that literally 422s
/// against the `between:0,360` rule. `accuracyM` is rounded because the
/// field is `integer` server-side.
class RiderMeLocationPing extends Equatable {
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speedKph;
  final double? accuracyM;
  final DateTime recordedAt;

  const RiderMeLocationPing({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speedKph,
    this.accuracyM,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (heading != null) 'heading': heading,
        if (speedKph != null) 'speed_kph': speedKph,
        if (accuracyM != null) 'accuracy_m': accuracyM!.round(),
        'recorded_at': recordedAt.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [latitude, longitude, heading, speedKph, accuracyM, recordedAt];
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
