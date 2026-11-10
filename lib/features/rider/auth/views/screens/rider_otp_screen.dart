import 'package:gopady_rider/constant/app_tokens.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gopady_rider/constant/app_theme.dart';
import 'package:gopady_rider/core/router/app_routes.dart';
import 'package:gopady_rider/core/widgets/app_gradient_button.dart';
import 'package:gopady_rider/core/widgets/custom_dialogs.dart';
import 'package:gopady_rider/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:gopady_rider/features/rider/shared_widgets/otp_input_field.dart';
import 'package:hugeicons/hugeicons.dart';

/// Phone verification. Reached from two paths:
///  - signup: the account already exists — `/register` took every signup
///    field; the remaining vehicle details are collected in KYC;
///  - login of an unverified account: `mode == 'verify'`.
class RiderOtpScreen extends ConsumerStatefulWidget {
  /// Passed via GoRouter extra: `{phone, email, password, mode?, ...}` —
  /// on the signup path, the rest of the signup fields ride along unused.
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

  /// Guards against the double-submit the completion callback and the
  /// button would otherwise cause together.
  bool _busy = false;

  String get _phone => widget.credentials['phone'] as String? ?? '';
  String? get _password => widget.credentials['password'] as String?;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  /// Requests a code, and only then starts the resend countdown.
  Future<void> _sendCode() async {
    final sent =
        await ref.read(riderAuthProvider.notifier).sendPhoneCode(_phone);
    if (!mounted) return;
    if (sent) _startCountdown();
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

  Future<void> _submit() async {
    if (!_isComplete || _busy) return;
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();

    final ok =
        await ref.read(riderAuthProvider.notifier).verifyPhoneAndEnsureSession(
              phone: _phone,
              code: _otp,
              password: _password,
            );

    if (!ok) {
      if (mounted) setState(() => _busy = false);
      return;
    }

    if (mounted) context.go(AppRoutes.dashboard);
  }

  /// Both paths exit to login rather than back into the signup form.
  ///
  /// By the time this screen is reached the account is already created, and
  /// `/register` can't amend it — so an editable form here would silently
  /// discard whatever the rider changed. They can sign in and finish
  /// verifying instead.
  void _goBack() => context.go(AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(riderAuthProvider).isLoading || _busy;

    ref.listen<RiderAuthState>(riderAuthProvider, (_, next) {
      if (!mounted) return;
      if (next.errorMessage != null) {
        CustomDialog.showError(
          context: context,
          title: 'Verification Failed',
          subtitle: next.errorMessage!,
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
          icon: const Icon(HugeIcons.strokeRoundedArrowLeft01,
              color: AppColors.textPrimary, size: 20),
          onPressed: _goBack,
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
                    fontFamily: AppFonts.body,
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
                      fontFamily: AppFonts.body,
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
                        fontFamily: AppFonts.body,
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    _secondsLeft > 0
                        ? Text(
                            'Resend in ${_secondsLeft}s',
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade400,
                            ),
                          )
                        : GestureDetector(
                            onTap: isLoading ? null : _sendCode,
                            child: const Text(
                              'Resend',
                              style: TextStyle(
                                fontFamily: AppFonts.body,
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
                  label: isLoading ? 'Verifying…' : 'Verify & Continue',
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
