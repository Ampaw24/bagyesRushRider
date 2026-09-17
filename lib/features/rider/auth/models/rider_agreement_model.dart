import 'package:equatable/equatable.dart';

/// Result of `POST /rider/me/agreement` — the rider's terms-of-service and
/// background-verification consent.
///
/// Bearer-authenticated, so it can only be reached once a session exists
/// (see `RiderAuthRepository.acceptAgreement`). The response body is
/// undocumented beyond an ack, so every field falls back to the request
/// values that produced it.
class RiderAgreementModel extends Equatable {
  final bool acceptTerms;
  final bool consentToVerification;
  final String? termsVersion;
  final DateTime? acceptedAt;

  const RiderAgreementModel({
    required this.acceptTerms,
    required this.consentToVerification,
    this.termsVersion,
    this.acceptedAt,
  });

  factory RiderAgreementModel.fromJson(
    Map<String, dynamic> json, {
    required bool fallbackAcceptTerms,
    required bool fallbackConsentToVerification,
    String? fallbackTermsVersion,
  }) {
    return RiderAgreementModel(
      acceptTerms: json['accept_terms'] as bool? ?? fallbackAcceptTerms,
      consentToVerification: json['consent_to_verification'] as bool? ??
          fallbackConsentToVerification,
      termsVersion: json['terms_version'] as String? ?? fallbackTermsVersion,
      acceptedAt: DateTime.tryParse(
        json['accepted_at']?.toString() ?? json['created_at']?.toString() ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'accept_terms': acceptTerms,
        'consent_to_verification': consentToVerification,
        if (termsVersion != null) 'terms_version': termsVersion,
      };

  @override
  List<Object?> get props =>
      [acceptTerms, consentToVerification, termsVersion, acceptedAt];
}
