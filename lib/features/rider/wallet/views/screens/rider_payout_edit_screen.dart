import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gopady_rider/core/widgets/app_toast.dart';
import 'package:gopady_rider/features/rider/kyc/models/kyc_section.dart';
import 'package:gopady_rider/features/rider/kyc/views/sections/payout_section.dart';
import 'package:gopady_rider/features/rider/kyc/views/widgets/kyc_profile_gate.dart';

/// Adds or changes the payout account outside the verification checklist —
/// the same password-confirmed form as the checklist step, but saving
/// returns to wherever the rider came from (payout details, withdrawals)
/// instead of moving on to the next step.
class RiderPayoutEditScreen extends StatelessWidget {
  const RiderPayoutEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KycProfileGate(
      title: KycSection.payout.title,
      builder: (context, profile) => PayoutSection(
        profile: profile,
        onSaved: () => _onSaved(context),
      ),
    );
  }

  void _onSaved(BuildContext context) {
    AppToast.show(
      context,
      isSuccess: true,
      title: 'Payout account saved',
      subtitle: 'Your withdrawals will be sent to this account.',
    );
    context.pop();
  }
}
