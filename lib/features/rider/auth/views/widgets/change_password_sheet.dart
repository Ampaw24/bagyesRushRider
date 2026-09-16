import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:delivery_boy/features/rider/shared_widgets/password_strength_validator.dart';

/// Modal sheet for changing the signed-in rider's password.
///
/// Distinct from the OTP-based forgot-password flow (`AppRoutes.forgotPassword`):
/// this one keeps the rider signed in and just needs their current password.
class ChangePasswordSheet extends ConsumerStatefulWidget {
  const ChangePasswordSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChangePasswordSheet(),
    );
  }

  @override
  ConsumerState<ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  String _newPassword = '';

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final ok = await ref.read(riderAuthProvider.notifier).changePassword(
          currentPassword: _currentController.text,
          newPassword: _newController.text,
          confirmPassword: _confirmController.text,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: 'Password updated successfully');
    } else {
      final message =
          ref.read(riderAuthProvider).errorMessage ?? 'Update failed';
      Fluttertoast.showToast(
        msg: message,
        backgroundColor: AppColors.error,
      );
      ref.read(riderAuthProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.035, w * 0.05, w * 0.06),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: w * 0.1,
                  height: w * 0.01,
                  margin: EdgeInsets.only(bottom: w * 0.05),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(w * 0.022),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      HugeIcons.strokeRoundedLockPassword,
                      color: AppColors.primary,
                      size: w * 0.05,
                    ),
                  ),
                  SizedBox(width: w * 0.03),
                  Text(
                    'Change Password',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: (w * 0.045).clamp(16.0, 20.0),
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: w * 0.06),
              _PasswordField(
                label: 'Current Password',
                controller: _currentController,
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Enter your current password'
                    : null,
              ),
              SizedBox(height: w * 0.035),
              _PasswordField(
                label: 'New Password',
                controller: _newController,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                onChanged: (v) => setState(() => _newPassword = v),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter a new password';
                  if (evaluatePasswordStrength(v) == PasswordStrength.weak) {
                    return 'Password is too weak';
                  }
                  return null;
                },
              ),
              PasswordStrengthValidator(password: _newPassword),
              SizedBox(height: w * 0.035),
              _PasswordField(
                label: 'Confirm New Password',
                controller: _confirmController,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Confirm your new password';
                  }
                  if (v != _newController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: w * 0.07),
              _SubmitButton(
                submitting: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool submitting;
  final VoidCallback onPressed;

  const _SubmitButton({required this.submitting, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: double.infinity,
      height: (w * 0.14).clamp(48.0, 58.0),
      child: ElevatedButton(
        onPressed: submitting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: submitting
            ? SizedBox(
                width: w * 0.055,
                height: w * 0.055,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'Update Password',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: (w * 0.04).clamp(14.0, 17.0),
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?) validator;
  final ValueChanged<String>? onChanged;

  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    required this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: (w * 0.03).clamp(11.0, 13.0),
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: w * 0.015),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          onChanged: onChanged,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: (w * 0.038).clamp(13.0, 16.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: EdgeInsets.symmetric(
              horizontal: w * 0.04,
              vertical: w * 0.032,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.6),
            ),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                obscure
                    ? HugeIcons.strokeRoundedView
                    : HugeIcons.strokeRoundedViewOffSlash,
                color: AppColors.textHint,
                size: w * 0.045,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
