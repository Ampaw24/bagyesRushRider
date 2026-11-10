import 'package:flutter/material.dart';

import 'package:gopady_rider/features/rider/kyc/models/kyc_section.dart';
import 'package:gopady_rider/features/rider/kyc/views/sections/emergency_contact_section.dart';
import 'package:gopady_rider/features/rider/kyc/views/sections/identity_section.dart';
import 'package:gopady_rider/features/rider/kyc/views/sections/insurance_section.dart';
import 'package:gopady_rider/features/rider/kyc/views/sections/licence_section.dart';
import 'package:gopady_rider/features/rider/kyc/views/sections/other_requirements_section.dart';
import 'package:gopady_rider/features/rider/kyc/views/sections/payout_section.dart';
import 'package:gopady_rider/features/rider/kyc/views/sections/personal_section.dart';
import 'package:gopady_rider/features/rider/kyc/views/sections/photo_section.dart';
import 'package:gopady_rider/features/rider/kyc/views/sections/vehicle_section.dart';
import 'package:gopady_rider/features/rider/kyc/views/widgets/kyc_profile_gate.dart';

/// Route target for `/dashboard/kyc/:section`.
///
/// Waits for `/rider/me` before building the form, so each form can prefill
/// its fields once in `initState`. Later profile refreshes (after an upload
/// or save) reach the same form state, keeping what the rider has typed.
class KycSectionScreen extends StatelessWidget {
  const KycSectionScreen({super.key, required this.section});

  final KycSection section;

  @override
  Widget build(BuildContext context) {
    return KycProfileGate(
      title: section.title,
      builder: (context, profile) => switch (section) {
        KycSection.photo => const PhotoSection(),
        KycSection.personal => PersonalSection(profile: profile),
        KycSection.identity => IdentitySection(profile: profile),
        KycSection.licence => LicenceSection(profile: profile),
        KycSection.vehicle => VehicleSection(profile: profile),
        KycSection.insurance => InsuranceSection(profile: profile),
        KycSection.emergencyContact =>
          EmergencyContactSection(profile: profile),
        KycSection.payout => PayoutSection(profile: profile),
        KycSection.other => const OtherRequirementsSection(),
      },
    );
  }
}
