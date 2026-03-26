import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/kyc/viewmodels/kyc_viewmodel.dart';
import 'package:delivery_boy/features/rider/shared_widgets/animated_stepper.dart';
import 'kyc_step1_identity_view.dart';
import 'kyc_step2_licence_view.dart';
import 'kyc_step3_vehicle_view.dart';
import 'kyc_step4_documents_view.dart';
import 'kyc_step5_review_view.dart';

class KycScreen extends ConsumerWidget {
  const KycScreen({super.key});

  static const _stepLabels = [
    'Identity',
    'Licence',
    'Vehicle',
    'Documents',
    'Review',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kycProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () {
            if (state.currentStep > 0) {
              ref.read(kycProvider.notifier).goToStep(state.currentStep - 1);
            } else {
              context.pop();
            }
          },
        ),
        title: const Text(
          'Identity Verification',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          AnimatedStepper(
            stepCount: 5,
            currentStep: state.currentStep,
            stepLabels: _stepLabels,
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          Expanded(
            child: IndexedStack(
              index: state.currentStep,
              children: const [
                KycStep1IdentityView(),
                KycStep2LicenceView(),
                KycStep3VehicleView(),
                KycStep4DocumentsView(),
                KycStep5ReviewView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
