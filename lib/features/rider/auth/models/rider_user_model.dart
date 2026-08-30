import 'package:equatable/equatable.dart';

enum KycStatus { notStarted, pendingReview, approved, rejected }

KycStatus _kycStatusFromJson(String? value) {
  switch (value) {
    case 'pendingReview':
      return KycStatus.pendingReview;
    case 'approved':
      return KycStatus.approved;
    case 'rejected':
      return KycStatus.rejected;
    default:
      return KycStatus.notStarted;
  }
}

class RiderUserModel extends Equatable {
  final String id;
  final String? name;
  final String? phone;
  final String? email;
  final String? selfie;
  final String? licenceFront;
  final String? licenceBack;
  // Note: 'motorIssurance' is a typo in the API — preserved intentionally
  final String? motorInsurance;
  final String? roadWorthy;
  final String? numberPlate;
  final bool queue;
  final KycStatus kycStatus;

  const RiderUserModel({
    required this.id,
    this.name,
    this.phone,
    this.email,
    this.selfie,
    this.licenceFront,
    this.licenceBack,
    this.motorInsurance,
    this.roadWorthy,
    this.numberPlate,
    this.queue = false,
    this.kycStatus = KycStatus.notStarted,
  });

  bool get isProfileComplete =>
      name != null &&
      email != null &&
      selfie != null &&
      licenceFront != null &&
      licenceBack != null &&
      motorInsurance != null &&
      roadWorthy != null &&
      numberPlate != null;

  factory RiderUserModel.fromJson(Map<String, dynamic> json) {
    return RiderUserModel(
      // Tolerant of both the legacy `_id` and the Laravel `id`, and never
      // throws on a missing key — this is parsed inside GoRouter's redirect,
      // where an exception is unrecoverable.
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      selfie: json['selfie'] as String?,
      licenceFront: json['licenceFront'] as String?,
      licenceBack: json['licenceBack'] as String?,
      motorInsurance: json['motorIssurance'] as String?, // typo in API
      roadWorthy: json['roadWorthy'] as String?,
      numberPlate: json['numberPlate'] as String?,
      queue: json['queue'] as bool? ?? false,
      kycStatus: _kycStatusFromJson(json['kycStatus'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'selfie': selfie,
        'licenceFront': licenceFront,
        'licenceBack': licenceBack,
        'motorIssurance': motorInsurance, // typo in API
        'roadWorthy': roadWorthy,
        'numberPlate': numberPlate,
        'queue': queue,
        'kycStatus': kycStatus.name,
      };

  RiderUserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? selfie,
    String? licenceFront,
    String? licenceBack,
    String? motorInsurance,
    String? roadWorthy,
    String? numberPlate,
    bool? queue,
    KycStatus? kycStatus,
  }) {
    return RiderUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      selfie: selfie ?? this.selfie,
      licenceFront: licenceFront ?? this.licenceFront,
      licenceBack: licenceBack ?? this.licenceBack,
      motorInsurance: motorInsurance ?? this.motorInsurance,
      roadWorthy: roadWorthy ?? this.roadWorthy,
      numberPlate: numberPlate ?? this.numberPlate,
      queue: queue ?? this.queue,
      kycStatus: kycStatus ?? this.kycStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        email,
        selfie,
        licenceFront,
        licenceBack,
        motorInsurance,
        roadWorthy,
        numberPlate,
        queue,
        kycStatus,
      ];
}
