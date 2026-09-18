import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_password_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/password_strength_validator.dart';

/// Forgot-password step 3: choose a new password.
///
/// [code] was already confirmed on the OTP screen, but `/password/reset`
/// re-validates it, so it is submitted again with the new password.
class RiderResetPasswordScreen extends ConsumerStatefulWidget {
  const RiderResetPasswordScreen({
    super.key,
    required this.phone,
    required this.code,
  });

  final String phone;
  final String code;

  @override
  ConsumerState<RiderResetPasswordScreen> createState() =>
      _RiderResetPasswordScreenState();
}

class _RiderResetPasswordScreenState
    extends ConsumerState<RiderResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _password = '';
  String _confirm = '';
  bool _submitting = false;

  /// Same gate as signup and change-password: a weak password would also
  /// fail the backend's `min:8`.
  bool get _canSubmit =>
      !_submitting &&
      evaluatePasswordStrength(_password) != PasswordStrength.weak &&
      _confirm.isNotEmpty;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final notifier = ref.read(riderAuthProvider.notifier);
    final ok = await notifier.resetPassword(
      phone: widget.phone,
      code: widget.code,
      password: _passwordCtrl.text,
      confirmPassword: _confirmCtrl.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!ok) {
      final message = ref.read(riderAuthProvider).errorMessage ??
          'Your password could not be reset. Please try again.';
      notifier.clearError();
      CustomDialog.showError(
        context: context,
        title: 'Password Not Reset',
        subtitle: message,
      );
      return;
    }

    HapticFeedback.lightImpact();
    await CustomDialog.showSuccess(
      context: context,
      title: 'Password Reset Successful',
      subtitle:
          'Your password has been updated. Sign in with your new password.',
      confirmText: 'Go to Login',
    );
    if (mounted) context.go(AppRoutes.login);
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
        child: Form(
          key: _formKey,
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
                SizedBox(height: h * 0.045),
                AppPasswordField(
                  label: 'New Password',
                  hint: 'Enter a new password',
                  controller: _passwordCtrl,
                  onChanged: (v) => setState(() => _password = v),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a new password';
                    if (evaluatePasswordStrength(v) == PasswordStrength.weak) {
                      return 'Password is too weak';
                    }
                    return null;
                  },
                ),
                PasswordStrengthValidator(password: _password),
                SizedBox(height: h * 0.022),
                AppPasswordField(
                  label: 'Confirm Password',
                  hint: 'Re-enter the new password',
                  controller: _confirmCtrl,
                  textInputAction: TextInputAction.done,
                  onChanged: (v) => setState(() => _confirm = v),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Confirm your new password';
                    }
                    if (v != _passwordCtrl.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: h * 0.045),
                AppGradientButton(
                  label: 'Reset Password',
                  isLoading: _submitting,
                  height: (h * 0.058).clamp(46.0, 54.0),
                  onPressed: _canSubmit ? _submit : null,
                ),
              ],
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
          'Reset Password',
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
            text: 'Create a new password for ',
            children: [
              TextSpan(
                text: phone,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const TextSpan(text: ". Make sure it's secure."),
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
