import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_phone_field.dart';

/// Forgot-password step 1, opened from the login screen: request a reset
/// code (`/password/forgot`). As in the customer/vendor app this is a sheet
/// over login; on success it hands off to the OTP screen.
class ForgotPasswordSheet extends ConsumerStatefulWidget {
  const ForgotPasswordSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ForgotPasswordSheet(),
    );
  }

  @override
  ConsumerState<ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  String _phone = '';
  bool _sending = false;

  Future<void> _sendCode() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);
    final notifier = ref.read(riderAuthProvider.notifier);
    final ok = await notifier.sendForgotPasswordCode(_phone);
    if (!mounted) return;
    setState(() => _sending = false);

    if (!ok) {
      final message = ref.read(riderAuthProvider).errorMessage ??
          'We could not send a verification code. Please try again.';
      notifier.clearError();
      CustomDialog.showError(
        context: context,
        title: 'Code Not Sent',
        subtitle: message,
      );
      return;
    }

    // The router outlives this sheet, so grab it before closing.
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(AppRoutes.forgotPasswordOtp, extra: _phone);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding:
                EdgeInsets.fromLTRB(w * 0.06, h * 0.022, w * 0.06, h * 0.02),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SheetHeader(onClose: () => Navigator.of(context).pop()),
                  SizedBox(height: h * 0.01),
                  Text(
                    'Enter your registered phone number. We will send a '
                    '6-digit code to verify your identity and reset your '
                    'password.',
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: (w * 0.036).clamp(13.0, 16.0),
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: h * 0.024),
                  Text(
                    'Phone Number',
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: (w * 0.033).clamp(11.0, 14.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.1,
                    ),
                  ),
                  SizedBox(height: h * 0.006),
                  // Same widget as login so the number is sent in the same
                  // E.164 form the account was registered with.
                  AppPhoneField(
                    onChanged: (full) => _phone = full,
                    validator: (v) => (v == null || v.trim().length < 9)
                        ? 'Enter a valid phone number'
                        : null,
                  ),
                  SizedBox(height: h * 0.03),
                  AppGradientButton(
                    label: 'Send OTP',
                    isLoading: _sending,
                    height: (h * 0.058).clamp(46.0, 54.0),
                    onPressed: _sending ? null : _sendCode,
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

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Row(
      children: [
        Expanded(
          child: Text(
            'Forgot Password',
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: (w * 0.05).clamp(18.0, 22.0),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Close',
          onPressed: onClose,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceVariant,
          ),
          icon: Icon(
            HugeIcons.strokeRoundedCancel01,
            size: (w * 0.045).clamp(16.0, 20.0),
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
