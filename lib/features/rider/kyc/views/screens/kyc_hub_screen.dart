import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_progress.dart';
import 'package:delivery_boy/features/rider/kyc/providers/kyc_providers.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_hub_widgets.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_metrics.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_section_layout.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';

/// The rider's verification checklist (`/dashboard/kyc`).
///
/// Every step is driven by `/rider/me`, which is re-fetched on open so the
/// list reflects the server's current view rather than a cached one. Steps
/// save independently, so a rider can leave and pick up where they stopped.
class KycHubScreen extends ConsumerStatefulWidget {
  const KycHubScreen({super.key});

  @override
  ConsumerState<KycHubScreen> createState() => _KycHubScreenState();
}

class _KycHubScreenState extends ConsumerState<KycHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() => ref.read(riderMeProfileProvider.notifier).load();

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    final profileState = ref.watch(riderMeProfileProvider);
    final progress = ref.watch(kycProgressProvider);
    final hasSubmitted =
        ref.watch(kycActionsProvider.select((s) => s.hasSubmitted));

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(HugeIcons.strokeRoundedArrowLeft01),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Verification'),
      ),
      body: progress == null
          ? (profileState.status == RiderMeProfileStatus.error
              ? KycLoadError(
                  message: profileState.errorMessage,
                  onRetry: _reload,
                )
              : const Center(child: CircularProgressIndicator()))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: m.gutter,
                  vertical: m.gap,
                ),
                children: [
                  KycContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        KycStatusHeader(
                          progress: progress,
                          hasSubmitted: hasSubmitted,
                        ),
                        SizedBox(height: m.gap * 1.25),
                        KycSectionList(
                          progress: progress,
                          onOpen: (s) =>
                              context.push(AppRoutes.kycSection(s.slug)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: progress == null
          ? null
          : _PrimaryAction(progress: progress, hasSubmitted: hasSubmitted),
    );
  }
}

/// One clear next step: continue the checklist, or submit it.
class _PrimaryAction extends ConsumerWidget {
  const _PrimaryAction({required this.progress, required this.hasSubmitted});

  final KycProgress progress;
  final bool hasSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = progress.nextSectionNeedingAction();
    final canSubmit = next == null && progress.canSubmitForReview && !hasSubmitted;
    if (next == null && !canSubmit) return const SizedBox.shrink();

    final m = KycMetrics.of(context);
    final isSubmitting =
        ref.watch(kycActionsProvider.select((s) => s.isSubmitting));

    return SafeArea(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(m.gutter, m.gap * 0.75, m.gutter, m.gap * 0.75),
          child: KycContentWidth(
            child: AppGradientButton(
              label: next != null ? 'Continue: ${next.title}' : 'Submit for review',
              isLoading: isSubmitting,
              onPressed: next != null
                  ? () => context.push(AppRoutes.kycSection(next.slug))
                  : () => _submit(context, ref),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final failure = await ref.read(kycActionsProvider.notifier).submitForReview();
    if (!context.mounted) return;
    if (failure != null) {
      CustomDialog.showError(
        context: context,
        title: "Couldn't Submit",
        subtitle: failure.message,
      );
      return;
    }
    HapticFeedback.mediumImpact();
    CustomDialog.showSuccess(
      context: context,
      title: 'Submitted for Review',
      subtitle: "We'll notify you as soon as your profile is approved.",
    );
  }
}
