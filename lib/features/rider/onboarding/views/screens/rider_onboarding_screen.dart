import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_profile_providers.dart';

class RiderOnboardingScreen extends ConsumerStatefulWidget {
  const RiderOnboardingScreen({super.key});

  @override
  ConsumerState<RiderOnboardingScreen> createState() =>
      _RiderOnboardingScreenState();
}

class _RiderOnboardingScreenState extends ConsumerState<RiderOnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isComplete =
        ref.watch(riderProfileProvider).user?.isProfileComplete ?? false;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 32),

                // ── Header ─────────────────────────────────────────────────
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFFCA445D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.delivery_dining,
                      color: Colors.white, size: 42),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Almost there!',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete your profile setup to start receiving delivery orders.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),

                // ── Stepper ────────────────────────────────────────────────
                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                            primary: AppColors.primary,
                          ),
                    ),
                    child: Stepper(
                      currentStep: _currentStep,
                      physics: const NeverScrollableScrollPhysics(),
                      controlsBuilder: (_, details) =>
                          const SizedBox.shrink(),
                      steps: [
                        Step(
                          title: const Text(
                            'Complete Your Profile',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          isActive: _currentStep >= 0,
                          state: _currentStep > 0
                              ? StepState.complete
                              : StepState.indexed,
                          content: _buildStepContent(
                            icon: Icons.person_outline,
                            description:
                                'Add your name, email address and vehicle number plate.',
                            buttonLabel: 'Edit Profile',
                            onTap: () {
                              context.push(AppRoutes.editProfile);
                              setState(() => _currentStep = 1);
                            },
                          ),
                        ),
                        Step(
                          title: const Text(
                            'Upload Documents',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          isActive: _currentStep >= 1,
                          state: isComplete
                              ? StepState.complete
                              : StepState.indexed,
                          content: _buildStepContent(
                            icon: Icons.upload_file_outlined,
                            description:
                                'Upload your selfie, driver\'s licence, motor insurance and roadworthy certificate.',
                            buttonLabel: 'Upload Documents',
                            onTap: () =>
                                context.push(AppRoutes.documentUpload),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Bottom button ──────────────────────────────────────────
                AppGradientButton(
                  label: isComplete
                      ? 'Go to Dashboard'
                      : 'Complete setup to continue',
                  onPressed: isComplete
                      ? () {
                          HapticFeedback.lightImpact();
                          context.go(AppRoutes.dashboard);
                        }
                      : null,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent({
    required IconData icon,
    required String description,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(icon,
                    color: AppColors.primary.withValues(alpha: 0.8), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    buttonLabel,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: AppColors.primary, size: 13),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
