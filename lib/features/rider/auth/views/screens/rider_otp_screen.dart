import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:delivery_boy/features/rider/shared_widgets/otp_input_field.dart';
import 'package:hugeicons/hugeicons.dart';

/// Phone verification. Reached from two paths:
///  - signup: carries the vehicle fields collected on the previous screens,
///    which are submitted to `PUT /rider/me` once verification yields a token;
///  - login of an unverified account: `mode == 'verify'`, no vehicle data.
class RiderOtpScreen extends ConsumerStatefulWidget {
  /// Passed via GoRouter extra: `{phone, email, password, mode?,
  /// vehicle_type?, plate_number?, vehicle_make?, vehicle_model?,
  /// vehicle_colour?, vehicle_year?}`
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

    await _submitVehicleProfile();
    if (mounted) context.go(AppRoutes.dashboard);
  }

  /// Submits the vehicle fields gathered during signup. A failure here must
  /// not block entry — the rider has verified their phone and can correct
  /// these later from the profile screen.
  Future<void> _submitVehicleProfile() async {
    final c = widget.credentials;
    if (c['vehicle_type'] == null) return; // login-verify path

    // Only the fields /register does NOT accept. vehicle_type and
    // plate_number were set atomically at registration; re-sending the plate
    // would re-run `unique:riders,plate_number` against the rider's own row.
    const keys = [
      'vehicle_make',
      'vehicle_model',
      'vehicle_colour',
      'vehicle_year',
    ];
    final body = {
      for (final k in keys)
        if (c[k] != null) k: c[k],
    };

    final ok = await ref
        .read(riderMeProfileProvider.notifier)
        .updateProfile(body);

    if (!ok && mounted) {
      Fluttertoast.showToast(
        msg: 'Vehicle details need re-entering in your profile',
        backgroundColor: AppColors.warning,
      );
    }
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
                            onTap: isLoading ? null : _sendCode,
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
