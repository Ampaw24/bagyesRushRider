import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_me_order_providers.dart';
import 'package:delivery_boy/features/rider/report/models/rider_report_flow_args.dart';
import 'package:delivery_boy/features/rider/report/providers/rider_report_form_providers.dart';
import 'package:delivery_boy/features/rider/report/views/widgets/rider_report_details_step.dart';
import 'package:delivery_boy/features/rider/report/views/widgets/rider_report_order_link_step.dart';
import 'package:delivery_boy/features/rider/report/views/widgets/rider_report_reason_step.dart';
import 'package:delivery_boy/features/rider/report/views/widgets/rider_report_target_type_step.dart';
import 'package:delivery_boy/features/rider/shared/rider_me_action_status.dart';

/// The "Report a Problem" wizard. A fresh instance of
/// [riderReportFormProvider] is created for [args] on entry and disposed
/// on exit (see `RiderReportFormNotifier`).
class RiderReportFlowScreen extends ConsumerStatefulWidget {
  final RiderReportFlowArgs args;

  const RiderReportFlowScreen({super.key, required this.args});

  @override
  ConsumerState<RiderReportFlowScreen> createState() =>
      _RiderReportFlowScreenState();
}

class _RiderReportFlowScreenState extends ConsumerState<RiderReportFlowScreen> {
  bool _isPickingPhotos = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final history = ref.read(riderMeOrderHistoryProvider);
      if (history.orders.isEmpty &&
          history.status != RiderMeOrdersStatus.loading) {
        ref.read(riderMeOrderHistoryProvider.notifier).load();
      }
    });
  }

  Future<void> _pickPhotos(int currentCount) async {
    final remaining = 5 - currentCount;
    if (remaining <= 0 || _isPickingPhotos) return;
    setState(() => _isPickingPhotos = true);
    try {
      final picked = await ImagePicker().pickMultiImage(
        maxWidth: 1600,
        imageQuality: 85,
        limit: remaining,
      );
      if (picked.isEmpty) return;
      ref
          .read(riderReportFormProvider(widget.args).notifier)
          .addPhotos(picked.map((x) => File(x.path)).toList());
    } finally {
      if (mounted) setState(() => _isPickingPhotos = false);
    }
  }

  Future<void> _submit() async {
    final notifier = ref.read(riderReportFormProvider(widget.args).notifier);
    final ok = await notifier.submit();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      final state = ref.read(riderReportFormProvider(widget.args));
      CustomDialog.showError(
        context: context,
        title: 'Submission failed',
        subtitle:
            state.errorMessage ?? 'Something went wrong. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final state = ref.watch(riderReportFormProvider(widget.args));
    final notifier = ref.read(riderReportFormProvider(widget.args).notifier);
    final orderHistory = ref.watch(riderMeOrderHistoryProvider);

    return PopScope(
      canPop: state.isFirstStep,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) notifier.goBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: SafeArea(
          child: Column(
            children: [
              _FlowHeader(
                progress: state.progress,
                onBack: () {
                  if (state.isFirstStep) {
                    Navigator.of(context).maybePop();
                  } else {
                    notifier.goBack();
                  }
                },
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0.04, 0), end: Offset.zero)
                          .animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(state.currentStep),
                    child: switch (state.currentStep) {
                      RiderReportWizardStep.targetType =>
                        RiderReportTargetTypeStep(
                            onSelect: notifier.selectTargetType),
                      RiderReportWizardStep.orderLink =>
                        RiderReportOrderLinkStep(
                          targetType: state.targetType!,
                          orders: orderHistory.orders,
                          isLoading: orderHistory.status ==
                              RiderMeOrdersStatus.loading,
                          errorMessage:
                              orderHistory.status == RiderMeOrdersStatus.error
                                  ? orderHistory.errorMessage
                                  : null,
                          onRetry: () => ref
                              .read(riderMeOrderHistoryProvider.notifier)
                              .load(),
                          onSelect: (target) => notifier.selectOrderLink(
                            orderId: target.orderId,
                            targetName: target.name,
                            targetPhone: target.phone,
                          ),
                          onSkip: notifier.goNext,
                        ),
                      RiderReportWizardStep.reason => RiderReportReasonStep(
                          reasons: state.currentReasons,
                          selectedCode: state.reasonCode,
                          isLoading: state.reasonsLoading,
                          errorMessage: state.reasonsError,
                          onRetry: notifier.loadReasons,
                          onSelect: (r) => notifier.selectReason(
                              code: r.code, label: r.label),
                        ),
                      RiderReportWizardStep.details => RiderReportDetailsStep(
                          targetName: state.targetName ?? '',
                          targetSubtitle: state.orderId != null
                              ? 'Order #${state.orderId}'
                              : '',
                          description: state.description,
                          onDescriptionChanged: notifier.updateDescription,
                          photos: state.photos,
                          isPickingPhotos: _isPickingPhotos,
                          onAddPhotos: () => _pickPhotos(state.photos.length),
                          onRemovePhoto: notifier.removePhoto,
                        ),
                    },
                  ),
                ),
              ),
              if (state.currentStep == RiderReportWizardStep.reason ||
                  state.currentStep == RiderReportWizardStep.details)
                _BottomActionBar(
                  w: w,
                  isDetails: state.currentStep == RiderReportWizardStep.details,
                  enabled: state.currentStep == RiderReportWizardStep.reason
                      ? state.hasReason
                      : state.canSubmit,
                  isSubmitting:
                      state.submitStatus == RiderMeActionStatus.inProgress,
                  onTap: () {
                    if (state.currentStep == RiderReportWizardStep.reason) {
                      notifier.goNext();
                    } else {
                      _submit();
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowHeader extends StatelessWidget {
  final double progress;
  final VoidCallback onBack;

  const _FlowHeader({required this.progress, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  padding: EdgeInsets.all(w * 0.022),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(w * 0.03),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowLeft02,
                    color: AppColors.textPrimary,
                    size: w * 0.055,
                  ),
                ),
              ),
              SizedBox(width: w * 0.035),
              Text(
                'Report a Problem',
                style: TextStyle(
                  fontSize: w * 0.048,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.035),
          ClipRRect(
            borderRadius: BorderRadius.circular(w * 0.01),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: w * 0.012,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final double w;
  final bool isDetails;
  final bool enabled;
  final bool isSubmitting;
  final VoidCallback onTap;

  const _BottomActionBar({
    required this.w,
    required this.isDetails,
    required this.enabled,
    required this.isSubmitting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        w * 0.05,
        w * 0.03,
        w * 0.05,
        w * 0.03 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: w * 0.13,
        child: ElevatedButton(
          onPressed: enabled && !isSubmitting ? onTap : null,
          child: isSubmitting
              ? SizedBox(
                  width: w * 0.05,
                  height: w * 0.05,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  isDetails ? 'Submit Report' : 'Continue',
                  style: TextStyle(
                      fontSize: w * 0.04, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}
