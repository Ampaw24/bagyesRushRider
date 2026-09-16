import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_phone_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/otp_input_field.dart';

enum _PhoneChangeStep { confirmSend, verifyOtp, enterNewPhone }

/// Three-step sheet for changing the signed-in rider's phone number:
/// send an OTP to the current phone → verify it → enter and save the new
/// one. The OTP step re-uses the same `/phone/send-code` + `/phone/verify`
/// endpoints signup uses (proving ownership works the same way regardless
/// of which phone is being verified); saving the new number goes through
/// the existing `PUT /rider/me` profile update rather than a dedicated
/// endpoint, since this backend doesn't have one.
class PhoneChangeFlowSheet extends ConsumerStatefulWidget {
  final String oldPhone;

  const PhoneChangeFlowSheet({super.key, required this.oldPhone});

  static Future<void> show(BuildContext context, {required String oldPhone}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PhoneChangeFlowSheet(oldPhone: oldPhone),
    );
  }

  @override
  ConsumerState<PhoneChangeFlowSheet> createState() =>
      _PhoneChangeFlowSheetState();
}

class _PhoneChangeFlowSheetState extends ConsumerState<PhoneChangeFlowSheet> {
  _PhoneChangeStep _step = _PhoneChangeStep.confirmSend;
  bool _loading = false;
  String? _errorMessage;
  String _newPhone = '';

  static const _resendCooldown = 60;
  int _secondsRemaining = _resendCooldown;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        t.cancel();
        setState(() => _secondsRemaining = 0);
      }
    });
  }

  Future<void> _handleSendOtp() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final ok = await ref
        .read(riderAuthProvider.notifier)
        .sendPhoneCode(widget.oldPhone);

    if (!mounted) return;
    setState(() => _loading = false);

    if (!ok) {
      setState(() =>
          _errorMessage = ref.read(riderAuthProvider).errorMessage);
      ref.read(riderAuthProvider.notifier).clearError();
      return;
    }

    setState(() => _step = _PhoneChangeStep.verifyOtp);
    _startResendTimer();
  }

  Future<void> _handleVerifyOtp(String code) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final ok = await ref
        .read(riderAuthProvider.notifier)
        .verifyPhoneOwnership(phone: widget.oldPhone, code: code);

    if (!mounted) return;
    setState(() => _loading = false);

    if (!ok) {
      setState(() =>
          _errorMessage = ref.read(riderAuthProvider).errorMessage);
      ref.read(riderAuthProvider.notifier).clearError();
      return;
    }

    _timer?.cancel();
    setState(() => _step = _PhoneChangeStep.enterNewPhone);
  }

  Future<void> _handleUpdatePhone() async {
    if (_newPhone.isEmpty) {
      setState(() => _errorMessage = 'Please enter your new phone number');
      return;
    }
    if (_newPhone == widget.oldPhone) {
      setState(() => _errorMessage =
          'New phone number must be different from your current one');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final ok = await ref
        .read(riderMeProfileProvider.notifier)
        .updateProfile({'phone': _newPhone});

    if (!mounted) return;
    setState(() => _loading = false);

    if (!ok) {
      setState(() => _errorMessage =
          ref.read(riderMeProfileProvider).actionMessage ?? 'Update failed');
      return;
    }

    // Keep the cached session in sync — settings and other screens read
    // the phone from here, not from riderMeProfileProvider.
    await sl<UserSessionManager>().updateUser({'phone': _newPhone});

    if (!mounted) return;
    Navigator.of(context).pop();
    Fluttertoast.showToast(msg: 'Phone number updated successfully');
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        w * 0.05,
        w * 0.035,
        w * 0.05,
        bottomInset + w * 0.05,
      ),
      decoration: BoxDecoration(
        color: AppColors.scaffold,
        borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.06)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: w * 0.1,
              height: w * 0.01,
              margin: EdgeInsets.only(bottom: w * 0.04),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Text(
                _stepTitle,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: (w * 0.045).clamp(16.0, 20.0),
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Container(
                  padding: EdgeInsets.all(w * 0.015),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    HugeIcons.strokeRoundedCancel01,
                    size: w * 0.045,
                    color: AppColors.textSecondary,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          SizedBox(height: w * 0.03),
          if (_errorMessage != null) ...[
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.03,
                vertical: w * 0.025,
              ),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    HugeIcons.strokeRoundedAlert02,
                    color: AppColors.error,
                    size: w * 0.045,
                  ),
                  SizedBox(width: w * 0.02),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: AppColors.error,
                        fontSize: (w * 0.033).clamp(11.0, 14.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: w * 0.04),
          ],
          if (_step == _PhoneChangeStep.confirmSend)
            _ConfirmSendStep(
              oldPhone: widget.oldPhone,
              loading: _loading,
              onSend: _handleSendOtp,
            )
          else if (_step == _PhoneChangeStep.verifyOtp)
            _VerifyOtpStep(
              oldPhone: widget.oldPhone,
              loading: _loading,
              secondsRemaining: _secondsRemaining,
              onVerify: _handleVerifyOtp,
              onResend: _handleSendOtp,
            )
          else
            _EnterNewPhoneStep(
              loading: _loading,
              onChanged: (v) => _newPhone = v,
              onSubmit: _handleUpdatePhone,
            ),
        ],
      ),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case _PhoneChangeStep.confirmSend:
        return 'Verify Current Phone';
      case _PhoneChangeStep.verifyOtp:
        return 'Enter Verification Code';
      case _PhoneChangeStep.enterNewPhone:
        return 'New Phone Number';
    }
  }
}

class _ConfirmSendStep extends StatelessWidget {
  final String oldPhone;
  final bool loading;
  final VoidCallback onSend;

  const _ConfirmSendStep({
    required this.oldPhone,
    required this.loading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Column(
      children: [
        Container(
          width: w * 0.16,
          height: w * 0.16,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              HugeIcons.strokeRoundedShieldKey,
              color: AppColors.primary,
              size: w * 0.08,
            ),
          ),
        ),
        SizedBox(height: w * 0.04),
        Text(
          'To protect your account, we\'ll send a verification code to your current phone number:',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: (w * 0.034).clamp(12.0, 15.0),
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: w * 0.03),
        Container(
          padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.025),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                HugeIcons.strokeRoundedSmartPhone01,
                color: AppColors.primary,
                size: w * 0.045,
              ),
              SizedBox(width: w * 0.02),
              Text(
                oldPhone,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: (w * 0.042).clamp(15.0, 18.0),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: w * 0.06),
        SizedBox(
          width: double.infinity,
          height: (w * 0.135).clamp(46.0, 56.0),
          child: ElevatedButton(
            onPressed: loading ? null : onSend,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: loading
                ? SizedBox(
                    width: w * 0.055,
                    height: w * 0.055,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Send Verification Code',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: (w * 0.04).clamp(14.0, 17.0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _VerifyOtpStep extends StatelessWidget {
  final String oldPhone;
  final bool loading;
  final int secondsRemaining;
  final ValueChanged<String> onVerify;
  final VoidCallback onResend;

  const _VerifyOtpStep({
    required this.oldPhone,
    required this.loading,
    required this.secondsRemaining,
    required this.onVerify,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter the 6-digit code sent to $oldPhone:',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: (w * 0.034).clamp(12.0, 15.0),
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: w * 0.05),
        OtpInputField(
          digitCount: 6,
          enabled: !loading,
          onCompleted: onVerify,
        ),
        SizedBox(height: w * 0.05),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive it? ",
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: (w * 0.033).clamp(11.0, 14.0),
                color: AppColors.textHint,
              ),
            ),
            if (secondsRemaining > 0)
              Text(
                'Resend in ${secondsRemaining}s',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: (w * 0.033).clamp(11.0, 14.0),
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              )
            else
              GestureDetector(
                onTap: loading ? null : onResend,
                child: Text(
                  'Resend Code',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: (w * 0.033).clamp(11.0, 14.0),
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
        if (loading) ...[
          SizedBox(height: w * 0.05),
          const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        ],
      ],
    );
  }
}

class _EnterNewPhoneStep extends StatefulWidget {
  final bool loading;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  const _EnterNewPhoneStep({
    required this.loading,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  State<_EnterNewPhoneStep> createState() => _EnterNewPhoneStepState();
}

class _EnterNewPhoneStepState extends State<_EnterNewPhoneStep> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your current phone number has been verified. Enter your new one below:',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: (w * 0.034).clamp(12.0, 15.0),
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: w * 0.04),
          AppPhoneField(onChanged: widget.onChanged),
          SizedBox(height: w * 0.06),
          SizedBox(
            height: (w * 0.135).clamp(46.0, 56.0),
            child: ElevatedButton(
              onPressed: widget.loading
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        widget.onSubmit();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: widget.loading
                  ? SizedBox(
                      width: w * 0.055,
                      height: w * 0.055,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Update Phone Number',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: (w * 0.04).clamp(14.0, 17.0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
