import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_phone_field.dart';
import 'package:hugeicons/hugeicons.dart';

enum _ForgotStep { enterPhone, enterOtpAndPassword }

class RiderForgotPasswordScreen extends ConsumerStatefulWidget {
  const RiderForgotPasswordScreen({super.key});

  @override
  ConsumerState<RiderForgotPasswordScreen> createState() =>
      _RiderForgotPasswordScreenState();
}

class _RiderForgotPasswordScreenState
    extends ConsumerState<RiderForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  _ForgotStep _step = _ForgotStep.enterPhone;
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _phone = '';

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(riderAuthProvider, (_, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
      // Step 1 success: OTP was sent
      if (_step == _ForgotStep.enterPhone && next.codeSent) {
        setState(() {
          _step = _ForgotStep.enterOtpAndPassword;
          _animCtrl.reset();
          _animCtrl.forward();
        });
      }
    });

    final authState = ref.watch(riderAuthProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(HugeIcons.strokeRoundedArrowLeft01,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _step == _ForgotStep.enterPhone
                  ? _buildPhoneStep(isLoading)
                  : _buildOtpStep(isLoading),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(HugeIcons.strokeRoundedLockPassword,
              color: AppColors.primary, size: 30),
        ),
        const SizedBox(height: 24),
        const Text(
          'Forgot Password?',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Enter your registered phone number and we'll send you an OTP.",
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Phone Number',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        // Same widget as login/signup so the number is submitted in the
        // identical E.164 form — a local-format number would silently
        // target a non-existent account.
        AppPhoneField(
          digitController: _phoneCtrl,
          onChanged: (full) => _phone = full,
        ),
        const SizedBox(height: 28),
        AppGradientButton(
          label: 'Send OTP',
          isLoading: isLoading,
          onPressed: isLoading ? null : _sendOtp,
        ),
      ],
    );
  }

  Widget _buildOtpStep(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(HugeIcons.strokeRoundedCheckmarkBadge01,
              color: Colors.green, size: 30),
        ),
        const SizedBox(height: 24),
        const Text(
          'Verify & Reset',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the OTP sent to $_phone and your new password.',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        _buildField(
          controller: _otpCtrl,
          label: 'OTP Code',
          hint: 'Enter OTP',
          keyboardType: TextInputType.number,
          prefixIcon: HugeIcons.strokeRoundedLockKey,
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: _passwordCtrl,
          label: 'New Password',
          hint: 'Enter new password',
          obscure: _obscurePassword,
          prefixIcon: HugeIcons.strokeRoundedLock,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? HugeIcons.strokeRoundedViewOff : HugeIcons.strokeRoundedEye,
              color: Colors.grey.shade500,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: _confirmCtrl,
          label: 'Confirm Password',
          hint: 'Confirm new password',
          obscure: _obscureConfirm,
          prefixIcon: HugeIcons.strokeRoundedLock,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm ? HugeIcons.strokeRoundedViewOff : HugeIcons.strokeRoundedEye,
              color: Colors.grey.shade500,
              size: 20,
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        const SizedBox(height: 28),
        AppGradientButton(
          label: 'Reset Password',
          isLoading: isLoading,
          onPressed: isLoading ? null : _resetPassword,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              // Clear the sent flag, or the listener immediately re-advances.
              ref.read(riderAuthProvider.notifier).clearCodeSent();
              setState(() {
                _step = _ForgotStep.enterPhone;
                _animCtrl.reset();
                _animCtrl.forward();
              });
            },
            child: const Text(
              'Change phone number',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure,
            inputFormatters: keyboardType == TextInputType.phone
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                fontFamily: 'Roboto',
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: Colors.grey.shade500, size: 20)
                  : null,
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.trim().length < 9) {
      Fluttertoast.showToast(msg: 'Enter a valid phone number');
      return;
    }
    // Dedicated forgot-password endpoint — not the phone-verification one.
    await ref.read(riderAuthProvider.notifier).sendForgotPasswordCode(_phone);
  }

  Future<void> _resetPassword() async {
    final otp = _otpCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (otp.length < 4) {
      Fluttertoast.showToast(msg: 'Enter the OTP');
      return;
    }
    if (password.length < 6) {
      Fluttertoast.showToast(msg: 'Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      Fluttertoast.showToast(msg: 'Passwords do not match');
      return;
    }

    // The code MUST be submitted — the backend re-validates it here. Without
    // it any digits would reset the password of any account.
    final ok = await ref.read(riderAuthProvider.notifier).resetPassword(
          phone: _phone,
          code: otp,
          password: password,
          confirmPassword: confirm,
        );

    if (ok && mounted) {
      HapticFeedback.lightImpact();
      Fluttertoast.showToast(
        msg: 'Password reset successfully!',
        backgroundColor: Colors.green,
      );
      context.go(AppRoutes.login);
    }
  }
}
