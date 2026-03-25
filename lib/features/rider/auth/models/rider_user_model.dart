import 'package:equatable/equatable.dart';

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
      id: json['_id'] as String,
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
      ];
}
