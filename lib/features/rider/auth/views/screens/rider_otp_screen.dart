import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:delivery_boy/features/rider/shared_widgets/otp_input_field.dart';

class RiderOtpScreen extends ConsumerStatefulWidget {
  /// Passed via GoRouter extra:
  /// {'name': String, 'phone': String, 'email': String?, 'password': String}
  final Map<String, dynamic> credentials;

  const RiderOtpScreen({super.key, required this.credentials});

  @override
  ConsumerState<RiderOtpScreen> createState() => _RiderOtpScreenState();
}

class _RiderOtpScreenState extends ConsumerState<RiderOtpScreen>
    with SingleTickerProviderStateMixin {
  final _otpKey = GlobalKey<OtpInputFieldState>();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  int _secondsLeft = 60;
  Timer? _countdownTimer;
  String _otp = '';

  String get _phone => widget.credentials['phone'] as String? ?? '';
  String get _name => widget.credentials['name'] as String? ?? '';
  String get _email => widget.credentials['email'] as String? ?? '';
  String get _password => widget.credentials['password'] as String? ?? '';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendOtp());
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

  Future<void> _sendOtp() async {
    if (_phone.isEmpty) {
      context.go(AppRoutes.signup);
      return;
    }
    await ref.read(riderAuthProvider.notifier).sendOtp(phone: _phone);
    _startCountdown();
  }

  Future<void> _submit() async {
    if (!_isComplete) return;
    HapticFeedback.lightImpact();

    final success = await ref.read(riderAuthProvider.notifier).signup(
          phone: _phone,
          password: _password,
          otp: _otp,
          name: _name,
          email: _email.isNotEmpty ? _email : null,
        );

    if (!mounted) return;
    if (success) {
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Welcome!',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: const Text(
            'Your account has been created successfully.',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go(AppRoutes.dashboard);
              },
              child: const Text(
                'Get Started',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(riderAuthProvider);
    final isLoading = authState.status == AuthStatus.loading;

    ref.listen<RiderAuthState>(riderAuthProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(riderAuthProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.go(AppRoutes.signup),
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
                      const TextSpan(
                          text: 'Enter the 6-digit code sent to '),
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

                // 6-digit OTP input
                OtpInputField(
                  key: _otpKey,
                  digitCount: 6,
                  enabled: !isLoading,
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
                            onTap: isLoading ? null : _sendOtp,
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
                  isLoading: isLoading,
                  onPressed: (_isComplete && !isLoading) ? _submit : null,
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
