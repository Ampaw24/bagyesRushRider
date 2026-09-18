import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_section.dart';
import 'package:delivery_boy/features/rider/kyc/views/sections/emergency_contact_section.dart';
import 'package:delivery_boy/features/rider/kyc/views/sections/identity_section.dart';
import 'package:delivery_boy/features/rider/kyc/views/sections/insurance_section.dart';
import 'package:delivery_boy/features/rider/kyc/views/sections/licence_section.dart';
import 'package:delivery_boy/features/rider/kyc/views/sections/other_requirements_section.dart';
import 'package:delivery_boy/features/rider/kyc/views/sections/payout_section.dart';
import 'package:delivery_boy/features/rider/kyc/views/sections/personal_section.dart';
import 'package:delivery_boy/features/rider/kyc/views/sections/photo_section.dart';
import 'package:delivery_boy/features/rider/kyc/views/sections/vehicle_section.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_hub_widgets.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';

/// Route target for `/dashboard/kyc/:section`.
///
/// Waits for `/rider/me` before building the form, so each form can prefill
/// its fields once in `initState`. Later profile refreshes (after an upload
/// or save) reach the same form state, keeping what the rider has typed.
class KycSectionScreen extends ConsumerStatefulWidget {
  const KycSectionScreen({super.key, required this.section});

  final KycSection section;

  @override
  ConsumerState<KycSectionScreen> createState() => _KycSectionScreenState();
}

class _KycSectionScreenState extends ConsumerState<KycSectionScreen> {
  @override
  void initState() {
    super.initState();
    if (ref.read(riderMeProfileProvider).profile == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(riderMeProfileProvider.notifier).load(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riderMeProfileProvider);
    final profile = state.profile;

    if (profile == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(HugeIcons.strokeRoundedArrowLeft01),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(widget.section.title),
        ),
        body: state.status == RiderMeProfileStatus.error
            ? KycLoadError(
                message: state.errorMessage,
                onRetry: () => ref.read(riderMeProfileProvider.notifier).load(),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }

    return switch (widget.section) {
      KycSection.photo => const PhotoSection(),
      KycSection.personal => PersonalSection(profile: profile),
      KycSection.identity => IdentitySection(profile: profile),
      KycSection.licence => LicenceSection(profile: profile),
      KycSection.vehicle => VehicleSection(profile: profile),
      KycSection.insurance => InsuranceSection(profile: profile),
      KycSection.emergencyContact => EmergencyContactSection(profile: profile),
      KycSection.payout => PayoutSection(profile: profile),
      KycSection.other => const OtherRequirementsSection(),
    };
  }
}
