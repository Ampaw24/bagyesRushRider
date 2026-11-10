import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:gopady_rider/constant/app_theme.dart';
import 'package:gopady_rider/core/widgets/app_status_animation.dart';
import 'package:gopady_rider/features/rider/kyc/views/widgets/kyc_hub_widgets.dart';
import 'package:gopady_rider/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:gopady_rider/features/rider/profile/providers/rider_me_profile_providers.dart';

/// Waits for `/rider/me` before building [builder], so forms can prefill
/// once in `initState`. Until then it shows a titled loading (or retryable
/// error) screen; later profile refreshes rebuild [builder] in place,
/// keeping whatever the rider has typed.
class KycProfileGate extends ConsumerStatefulWidget {
  const KycProfileGate({super.key, required this.title, required this.builder});

  /// App bar title while the profile loads.
  final String title;
  final Widget Function(BuildContext context, RiderMeProfileModel profile)
      builder;

  @override
  ConsumerState<KycProfileGate> createState() => _KycProfileGateState();
}

class _KycProfileGateState extends ConsumerState<KycProfileGate> {
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
    if (profile != null) return widget.builder(context, profile);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(HugeIcons.strokeRoundedArrowLeft01),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(widget.title),
      ),
      body: state.status == RiderMeProfileStatus.error
          ? KycLoadError(
              message: state.errorMessage,
              onRetry: () => ref.read(riderMeProfileProvider.notifier).load(),
            )
          : const AppLoader(),
    );
  }
}
