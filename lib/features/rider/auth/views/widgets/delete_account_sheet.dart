import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';

/// Modal sheet that performs permanent account deletion
/// (`POST /account/delete`). Requires the rider's current password to
/// confirm intent; `reason` is optional feedback sent to support.
///
/// Reached from the settings screen's "Delete Account" tile, after the
/// rider has already dismissed a warning confirmation — the password field
/// here is the final gate before the request fires.
class DeleteAccountSheet extends ConsumerStatefulWidget {
  const DeleteAccountSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DeleteAccountSheet(),
    );
  }

  @override
  ConsumerState<DeleteAccountSheet> createState() =>
      _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<DeleteAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _reasonController = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final reason = _reasonController.text.trim();
    final ok = await ref.read(riderAuthProvider.notifier).deleteAccount(
          password: _passwordController.text,
          reason: reason.isEmpty ? null : reason,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: 'Your account has been deleted');
      context.go(AppRoutes.login);
    } else {
      final message =
          ref.read(riderAuthProvider).errorMessage ?? 'Deletion failed';
      ref.read(riderAuthProvider.notifier).clearError();
      CustomDialog.showError(
        context: context,
        title: 'Account Not Deleted',
        subtitle: message,
      );
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
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      HugeIcons.strokeRoundedDelete01,
                      color: AppColors.error,
                      size: w * 0.05,
                    ),
                  ),
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: Text(
                      'Delete Account',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: (w * 0.045).clamp(16.0, 20.0),
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: w * 0.03),
              Text(
                'This permanently deletes your account and all associated '
                'data. This action cannot be undone.',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: (w * 0.033).clamp(12.0, 14.0),
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: w * 0.06),
              _PasswordField(
                controller: _passwordController,
                obscure: _obscurePassword,
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              SizedBox(height: w * 0.035),
              _ReasonField(controller: _reasonController),
              SizedBox(height: w * 0.07),
              _SubmitButton(submitting: _submitting, onPressed: _submit),
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
          backgroundColor: AppColors.error,
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
                'Delete My Account',
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
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
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
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Enter your password to confirm' : null,
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

class _ReasonField extends StatelessWidget {
  final TextEditingController controller;

  const _ReasonField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reason (optional)',
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
          maxLines: 3,
          maxLength: 500,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: (w * 0.038).clamp(13.0, 16.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Tell us why you\'re leaving',
            hintStyle: TextStyle(
              fontFamily: 'Roboto',
              color: AppColors.textHint,
              fontWeight: FontWeight.w500,
            ),
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
          ),
        ),
      ],
    );
  }
}
