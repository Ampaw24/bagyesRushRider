import 'package:equatable/equatable.dart';

/// The account returned by `/register`, `/login` and `/profile`.
///
/// Role-agnostic — the same shape serves customer, vendor and rider
/// accounts. The rider's *operational* profile (vehicle, licence,
/// availability, verification) is a separate resource: `GET /rider/me`
/// → `RiderMeProfileModel`.
class AuthUserModel extends Equatable {
  final String id;
  final String? email;
  final String? phone;
  final String? role;
  final String? status;
  final bool phoneVerified;

  /// Role-specific payload, kept raw on purpose: its rider-side shape is
  /// undocumented, and an unexpected one must not be able to fail a login.
  final Map<String, dynamic>? profile;

  const AuthUserModel({
    required this.id,
    this.email,
    this.phone,
    this.role,
    this.status,
    this.phoneVerified = false,
    this.profile,
  });

  String? get firstName => profile?['first_name'] as String?;
  String? get lastName => profile?['last_name'] as String?;

  String get fullName => [firstName, lastName]
      .whereType<String>()
      .where((e) => e.trim().isNotEmpty)
      .join(' ');

  bool get isRider => role == 'rider';

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    return AuthUserModel(
      // Laravel serialises numeric PKs inconsistently — never cast to String.
      id: json['id']?.toString() ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String?,
      status: json['status'] as String?,
      phoneVerified: json['phone_verified'] == true,
      profile: profile is Map ? profile.cast<String, dynamic>() : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'phone': phone,
        'role': role,
        'status': status,
        'phone_verified': phoneVerified,
        'profile': profile,
      };

  AuthUserModel copyWith({
    String? id,
    String? email,
    String? phone,
    String? role,
    String? status,
    bool? phoneVerified,
    Map<String, dynamic>? profile,
  }) {
    return AuthUserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      profile: profile ?? this.profile,
    );
  }

  @override
  List<Object?> get props => [id, email, phone, role, status, phoneVerified];
}
