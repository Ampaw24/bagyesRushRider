import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:delivery_boy/features/rider/shared_widgets/otp_code_input.dart';

const int _kCodeLength = 6;
const int _kResendCooldownSeconds = 60;

/// Consecutive wrong codes before verification locks until a new code is
/// requested.
const int _kMaxAttempts = 5;

/// Pulls a "wait N seconds" cooldown out of a rate-limit message (e.g.
/// "Please wait 28 seconds before requesting another code.") so the resend
/// countdown matches the server instead of re-enabling into the same error.
int? _cooldownFrom(String message) {
  final match = RegExp(r'(\d+)\s*second').firstMatch(message);
  return match == null ? null : int.tryParse(match.group(1)!);
}

/// Forgot-password step 2: confirm the code `/password/forgot` sent.
///
/// Same flow as the customer/vendor app: the code is checked here
/// (`/otp/verify`, purpose `account_recovery`) so a wrong code surfaces
/// before the rider picks a new password, then handed on to
/// `RiderResetPasswordScreen`, since `/password/reset` re-validates it.
class RiderPasswordResetOtpScreen extends ConsumerStatefulWidget {
  const RiderPasswordResetOtpScreen({super.key, required this.phone});

  /// Full E.164 number the code was sent to.
  final String phone;

  @override
  ConsumerState<RiderPasswordResetOtpScreen> createState() =>
      _RiderPasswordResetOtpScreenState();
}

class _RiderPasswordResetOtpScreenState
    extends ConsumerState<RiderPasswordResetOtpScreen>
    with SingleTickerProviderStateMixin {
  final _inputKey = GlobalKey<OtpCodeInputState>();

  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  String _code = '';
  String? _errorMessage;
  bool _verifying = false;
  bool _resending = false;
  bool _isSuccess = false;
  bool _locked = false;
  int _failedAttempts = 0;

  Timer? _resendTimer;
  int _secondsLeft = 0;

  bool get _canInput => !_verifying && !_locked && !_isSuccess;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    // The sheet that opened this screen has just sent the first code.
    _startResendCountdown(_kResendCooldownSeconds);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _startResendCountdown(int seconds) {
    _resendTimer?.cancel();
    _secondsLeft = seconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  void _onCodeChanged(String code) {
    _code = code;
    setState(() => _errorMessage = null);
  }

  Future<void> _verify() async {
    if (!_canInput || _code.length < _kCodeLength) return;

    final code = _code;
    setState(() => _verifying = true);

    final notifier = ref.read(riderAuthProvider.notifier);
    final ok =
        await notifier.verifyPasswordResetCode(phone: widget.phone, code: code);
    if (!mounted) return;

    if (!ok) {
      final message = ref.read(riderAuthProvider).errorMessage ??
          'That code is not valid. Please try again.';
      notifier.clearError();
      _onVerifyFailed(message);
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _verifying = false;
      _isSuccess = true;
    });
    await Future<void>.delayed(OtpCodeInput.successDuration);
    if (!mounted) return;

    // Replaced rather than stacked: the code is spent, so backing out of
    // the next screen should return to login, not to this one.
    context.pushReplacement(
      AppRoutes.resetPassword,
      extra: {'phone': widget.phone, 'code': code},
    );
  }

  void _onVerifyFailed(String message) {
    _failedAttempts++;
    final locked = _failedAttempts >= _kMaxAttempts;

    setState(() {
      _verifying = false;
      _locked = locked;
      _errorMessage = locked
          ? 'Too many incorrect attempts. Request a new code to continue.'
          : message;
    });
    _inputKey.currentState
      ?..clear()
      ..shake();
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0 || _resending) return;
    setState(() {
      _resending = true;
      _errorMessage = null;
    });

    final notifier = ref.read(riderAuthProvider.notifier);
    final ok = await notifier.sendForgotPasswordCode(widget.phone);
    if (!mounted) return;

    if (ok) {
      setState(() {
        _resending = false;
        _locked = false;
        _failedAttempts = 0;
        _startResendCountdown(_kResendCooldownSeconds);
      });
      _inputKey.currentState?.clear();
      Fluttertoast.showToast(msg: 'A new code has been sent');
      return;
    }

    // A failed resend isn't a wrong code — it leaves the input and the
    // attempt count alone.
    final message = ref.read(riderAuthProvider).errorMessage ??
        'Could not send a new code. Please try again.';
    notifier.clearError();
    setState(() {
      _resending = false;
      _errorMessage = message;
      final wait = _cooldownFrom(message);
      if (wait != null && wait > 0) _startResendCountdown(wait);
    });
  }

  void _back() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            HugeIcons.strokeRoundedArrowLeft01,
            color: AppColors.textPrimary,
          ),
          onPressed: _back,
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                w * 0.062,
                h * 0.02,
                w * 0.062,
                h * 0.03,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(phone: widget.phone),
                  SizedBox(height: h * 0.05),
                  OtpCodeInput(
                    key: _inputKey,
                    length: _kCodeLength,
                    enabled: _canInput,
                    hasError: _errorMessage != null,
                    isSuccess: _isSuccess,
                    onChanged: _onCodeChanged,
                    onCompleted: (_) => _verify(),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: _errorMessage == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: EdgeInsets.only(top: h * 0.018),
                            child: _ErrorBanner(message: _errorMessage!),
                          ),
                  ),
                  SizedBox(height: h * 0.038),
                  AppGradientButton(
                    label: 'Verify & Continue',
                    isLoading: _verifying,
                    height: (h * 0.058).clamp(46.0, 54.0),
                    onPressed: _canInput && _code.length == _kCodeLength
                        ? _verify
                        : null,
                  ),
                  SizedBox(height: h * 0.025),
                  _ResendRow(
                    secondsLeft: _secondsLeft,
                    resending: _resending,
                    enabled: !_verifying && !_isSuccess,
                    onResend: _resend,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify your\nphone number',
          style: TextStyle(
            fontFamily: 'Mukta',
            fontSize: (w * 0.072).clamp(24.0, 34.0),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.22,
          ),
        ),
        SizedBox(height: size.height * 0.008),
        Text.rich(
          TextSpan(
            text: 'Enter the 6-digit code sent to ',
            children: [
              TextSpan(
                text: phone,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          style: TextStyle(
            fontFamily: 'Mukta',
            fontSize: (w * 0.038).clamp(13.0, 17.0),
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final fontSize = (w * 0.034).clamp(12.0, 15.0);

    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            HugeIcons.strokeRoundedAlertCircle,
            color: AppColors.error,
            size: fontSize * 1.25,
          ),
          SizedBox(width: w * 0.016),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: fontSize,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResendRow extends StatelessWidget {
  const _ResendRow({
    required this.secondsLeft,
    required this.resending,
    required this.enabled,
    required this.onResend,
  });

  final int secondsLeft;
  final bool resending;
  final bool enabled;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final fontSize = (w * 0.036).clamp(12.0, 16.0);
    final promptStyle = TextStyle(
      fontFamily: 'Mukta',
      fontSize: fontSize,
      color: AppColors.textSecondary,
    );
    final actionStyle = promptStyle.copyWith(fontWeight: FontWeight.w600);

    final Widget action;
    if (resending) {
      action = SizedBox.square(
        dimension: fontSize,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      );
    } else if (secondsLeft > 0) {
      action = Text(
        'Resend in ${secondsLeft}s',
        style: actionStyle.copyWith(color: AppColors.textHint),
      );
    } else {
      action = TextButton(
        onPressed: enabled ? onResend : null,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: EdgeInsets.symmetric(horizontal: w * 0.02),
        ),
        child: Text('Resend', style: actionStyle),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: w * 0.012,
      children: [
        Text("Didn't receive a code?", style: promptStyle),
        action,
      ],
    );
  }
}
