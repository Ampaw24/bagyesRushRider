import 'package:flutter/widgets.dart';
import 'package:hugeicons/hugeicons.dart';

/// One verification document tracked under `/rider/me/documents/:type`.
///
/// `key` doubles as the `:type` slug (selfie is the exception — it goes
/// through `POST rider/me/photo` instead).
class RiderDocumentType {
  final String key;
  final String label;
  final IconData icon;
  const RiderDocumentType(this.key, this.label, this.icon);
}

const riderDocumentTypes = [
  RiderDocumentType('selfie', 'Profile Selfie', HugeIcons.strokeRoundedFaceId),
  RiderDocumentType('ghana_card_front', 'Ghana Card — Front',
      HugeIcons.strokeRoundedIdentityCard),
  RiderDocumentType('ghana_card_back', 'Ghana Card — Back',
      HugeIcons.strokeRoundedIdentityCard),
  RiderDocumentType('drivers_licence_front', "Driver's Licence — Front",
      HugeIcons.strokeRoundedCreditCard),
  RiderDocumentType('drivers_licence_back', "Driver's Licence — Back",
      HugeIcons.strokeRoundedCreditCardNotAccept),
  RiderDocumentType(
      'vehicle_registration', 'Vehicle Registration', HugeIcons.strokeRoundedCar01),
  RiderDocumentType('insurance_certificate', 'Insurance Certificate',
      HugeIcons.strokeRoundedShield01),
  RiderDocumentType('roadworthy_certificate', 'Roadworthy Certificate',
      HugeIcons.strokeRoundedCheckmarkBadge01),
];
