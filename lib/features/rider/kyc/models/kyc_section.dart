import 'package:flutter/widgets.dart';
import 'package:hugeicons/hugeicons.dart';

/// One step of the rider's profile checklist. Order here is the order the
/// guided flow walks through.
///
/// Which sections are outstanding is decided by the server (see
/// `KycProgress`); this only groups its field keys and document slugs into
/// steps a rider can complete in one sitting.
enum KycSection {
  photo(
    prompt: 'Add a clear profile photo',
    title: 'Profile photo',
    description: 'A clear selfie so customers and our team can recognise you.',
    icon: HugeIcons.strokeRoundedFaceId,
    fields: {'photo', 'profile_photo', 'profile_photo_url', 'selfie'},
  ),
  personal(
    prompt: 'Add your date of birth and address',
    title: 'Personal details',
    description: 'Your date of birth and home address.',
    icon: HugeIcons.strokeRoundedUser,
    fields: {
      'first_name',
      'last_name',
      'date_of_birth',
      'residential_address',
      'city',
    },
  ),
  identity(
    prompt: 'Verify your identity',
    title: 'Identity',
    description: 'Your Ghana Card or passport, with photos of it.',
    icon: HugeIcons.strokeRoundedIdentityCard,
    fields: {'id_type', 'id_number'},
    documents: {'ghana_card_front', 'ghana_card_back', 'passport_bio_page'},
  ),
  licence(
    prompt: "Add your driver's licence",
    title: "Driver's licence",
    description: 'Licence details and photos of both sides.',
    icon: HugeIcons.strokeRoundedCreditCard,
    fields: {
      'licence_number',
      'licence_class',
      'licence_expires_at',
      'rider_permit_number',
      'rider_permit_expires_at',
    },
    documents: {'drivers_licence_front', 'drivers_licence_back', 'rider_permit'},
  ),
  vehicle(
    prompt: "Add your vehicle's make and model",
    title: 'Vehicle',
    description: 'Make, model and registration of the vehicle you ride.',
    icon: HugeIcons.strokeRoundedMotorbike01,
    fields: {
      'vehicle_type',
      'vehicle_type_id',
      'plate_number',
      'vehicle_make',
      'vehicle_make_id',
      'vehicle_model',
      'vehicle_model_id',
      'vehicle_colour',
      'vehicle_year',
      'vehicle_ownership',
    },
    documents: {'vehicle_registration', 'vehicle_authorisation'},
  ),
  insurance(
    prompt: 'Add your insurance and roadworthy',
    title: 'Insurance & roadworthiness',
    description: 'Your motor insurance and roadworthy certificate.',
    icon: HugeIcons.strokeRoundedShield01,
    fields: {
      'insurance_provider',
      'insurance_policy_number',
      'insurance_expires_at',
      'roadworthy_expires_at',
    },
    documents: {'insurance_certificate', 'roadworthy_certificate'},
  ),
  emergencyContact(
    prompt: 'Add an emergency contact',
    title: 'Emergency contact',
    description: 'Someone we can reach if something happens on a delivery.',
    icon: HugeIcons.strokeRoundedCall,
    fields: {
      'emergency_contact_name',
      'emergency_contact_phone',
      'emergency_contact_relationship',
    },
  ),
  payout(
    prompt: 'Set up where you get paid',
    title: 'Payout account',
    description: 'Where your earnings are paid — mobile money or bank.',
    icon: HugeIcons.strokeRoundedWallet01,
    fields: {
      'payout_details',
      'payout_provider_id',
      'momo_provider_id',
      'account_number',
      'account_name',
      'mobile_money_number',
    },
  ),

  /// Anything the server asks for that the app doesn't recognise yet, so a
  /// new backend requirement is still visible without an app update.
  other(
    prompt: 'Finish the remaining requirements',
    title: 'Other requirements',
    description: 'Additional items our team needs from you.',
    icon: HugeIcons.strokeRoundedTask01,
  );

  const KycSection({
    required this.prompt,
    required this.title,
    required this.description,
    required this.icon,
    this.fields = const {},
    this.documents = const {},
  });

  /// Call to action for the home screen's setup card.
  final String prompt;
  final String title;
  final String description;
  final IconData icon;

  /// Server field keys (as they appear in `missing_profile_fields`).
  final Set<String> fields;

  /// Document slugs (as they appear in the `documents` map).
  final Set<String> documents;

  /// Path segment for `/dashboard/kyc/:section`.
  String get slug => name;

  static KycSection? fromSlug(String? slug) {
    for (final section in values) {
      if (section.slug == slug) return section;
    }
    return null;
  }

  /// The section a server field key belongs to. Falls back on prefixes so a
  /// new field in a known group (say `licence_issued_at`) still lands in the
  /// right place.
  static KycSection forField(String field) {
    for (final section in values) {
      if (section.fields.contains(field)) return section;
    }
    return _byPrefix(field);
  }

  /// The section a document slug belongs to, with the same prefix fallback.
  static KycSection forDocument(String slug) {
    for (final section in values) {
      if (section.documents.contains(slug)) return section;
    }
    return _byPrefix(slug);
  }

  static KycSection _byPrefix(String key) {
    const prefixes = {
      'ghana_card': identity,
      'passport': identity,
      'id_': identity,
      'drivers_licence': licence,
      'licence': licence,
      'rider_permit': licence,
      'vehicle': vehicle,
      'insurance': insurance,
      'roadworthy': insurance,
      'emergency_contact': emergencyContact,
      'payout': payout,
      'momo': payout,
    };
    for (final entry in prefixes.entries) {
      if (key.startsWith(entry.key)) return entry.value;
    }
    return other;
  }
}

/// Human labels for server keys, used wherever the app lists what's
/// outstanding. Unknown keys fall back to [humanizeKey].
const kycLabels = {
  'date_of_birth': 'Date of birth',
  'residential_address': 'Home address',
  'id_type': 'ID type',
  'id_number': 'ID number',
  'licence_number': 'Licence number',
  'licence_class': 'Licence class',
  'licence_expires_at': 'Licence expiry date',
  'rider_permit_number': 'Rider permit number',
  'rider_permit_expires_at': 'Rider permit expiry date',
  'vehicle_make_id': 'Vehicle make',
  'vehicle_model_id': 'Vehicle model',
  'vehicle_colour': 'Vehicle colour',
  'vehicle_year': 'Vehicle year',
  'vehicle_ownership': 'Vehicle ownership',
  'insurance_provider': 'Insurance provider',
  'insurance_policy_number': 'Policy number',
  'insurance_expires_at': 'Insurance expiry date',
  'roadworthy_expires_at': 'Roadworthy expiry date',
  'emergency_contact_name': 'Contact name',
  'emergency_contact_phone': 'Contact phone',
  'emergency_contact_relationship': 'Relationship',
  'payout_details': 'Payout account',
  'ghana_card_front': 'Ghana Card — front',
  'ghana_card_back': 'Ghana Card — back',
  'passport_bio_page': 'Passport photo page',
  'drivers_licence_front': "Driver's licence — front",
  'drivers_licence_back': "Driver's licence — back",
  'rider_permit': 'Rider permit',
  'vehicle_registration': 'Vehicle registration',
  'vehicle_authorisation': "Owner's authorisation letter",
  'insurance_certificate': 'Insurance certificate',
  'roadworthy_certificate': 'Roadworthy certificate',
};

String kycLabel(String key) => kycLabels[key] ?? humanizeKey(key);

/// `vehicle_make_id` → `Vehicle make id`.
String humanizeKey(String key) {
  final words = key.split('_').where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return key;
  final sentence = words.join(' ');
  return '${sentence[0].toUpperCase()}${sentence.substring(1)}';
}
