import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/shared_widgets/otp_input_field.dart';

// TODO: Re-integrate API calls (sendOtp, signup) once backend is ready.

class RiderOtpScreen extends StatefulWidget {
  /// Passed via GoRouter extra:
  /// {'name': String, 'phone': String, 'email': String?, 'password': String}
  final Map<String, dynamic> credentials;

  const RiderOtpScreen({super.key, required this.credentials});

  @override
  State<RiderOtpScreen> createState() => _RiderOtpScreenState();
}

class _RiderOtpScreenState extends State<RiderOtpScreen>
    with SingleTickerProviderStateMixin {
  final _otpKey = GlobalKey<OtpInputFieldState>();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  int _secondsLeft = 60;
  Timer? _countdownTimer;
  String _otp = '';

  String get _phone => widget.credentials['phone'] as String? ?? '';

  bool get _isComplete => _otp.length == 6;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCountdown());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsLeft = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
        }
      });
    });
  }

  void _submit() {
    if (!_isComplete) return;
    HapticFeedback.mediumImpact();
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.go(
            AppRoutes.vehicleDetails,
            extra: widget.credentials,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                const Text(
                  'Verify Phone',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    children: [
                      const TextSpan(text: 'Enter the 6-digit code sent to '),
                      TextSpan(
                        text: _phone,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 44),

                OtpInputField(
                  key: _otpKey,
                  digitCount: 6,
                  enabled: true,
                  onCompleted: (otp) {
                    setState(() => _otp = otp);
                    _submit();
                  },
                ),

                const SizedBox(height: 40),

                // Countdown / Resend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive a code? ",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    _secondsLeft > 0
                        ? Text(
                            'Resend in ${_secondsLeft}s',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade400,
                            ),
                          )
                        : GestureDetector(
                            onTap: _startCountdown,
                            child: const Text(
                              'Resend',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                  ],
                ),

                const SizedBox(height: 40),

                AppGradientButton(
                  label: 'Verify & Continue',
                  onPressed: _isComplete ? _submit : null,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
