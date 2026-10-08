import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_hub_widgets.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_password_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_text_field.dart';

/// Reasons offered for leaving. The label (or the rider's own words for
/// "Other") is what's sent as `reason`.
const _reasons = [
  (code: 'no_longer_delivering', label: 'I no longer want to deliver'),
  (code: 'found_alternative', label: 'I found another delivery job'),
  (code: 'privacy_concerns', label: 'I have privacy or data concerns'),
  (code: 'bad_experience', label: 'I had a bad experience with orders or payouts'),
  (code: 'too_many_notifications', label: 'I receive too many notifications'),
  (code: 'other', label: 'Other'),
];

/// Route target for [AppRoutes.deleteAccount] — the same flow as the
/// customer and vendor app: a warning, a reason, the rider's password, then
/// one last confirmation before `POST /account/delete`.
///
/// Reached from the drawer's and Settings' "Delete Account" entries, each of
/// which shows its own first warning before pushing this screen.
class RiderDeleteAccountScreen extends ConsumerStatefulWidget {
  const RiderDeleteAccountScreen({super.key});

  @override
  ConsumerState<RiderDeleteAccountScreen> createState() =>
      _RiderDeleteAccountScreenState();
}

class _RiderDeleteAccountScreenState
    extends ConsumerState<RiderDeleteAccountScreen> {
  final _passwordController = TextEditingController();
  final _otherReasonController = TextEditingController();

  String? _reasonCode;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_refresh);
    _otherReasonController.addListener(_refresh);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _otherReasonController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  bool get _isOther => _reasonCode == 'other';

  bool get _canSubmit =>
      _reasonCode != null &&
      _passwordController.text.isNotEmpty &&
      (!_isOther || _otherReasonController.text.trim().isNotEmpty);

  String? get _reason {
    if (_reasonCode == null) return null;
    if (_isOther) return _otherReasonController.text.trim();
    return _reasons.firstWhere((r) => r.code == _reasonCode).label;
  }

  void _confirmDeletion() {
    if (_submitting || !_canSubmit) return;
    FocusScope.of(context).unfocus();
    CustomDialog.showConfirmation(
      context: context,
      title: 'Delete Account Permanently?',
      subtitle: 'This is your last chance to back out. Once deleted, your '
          'profile, delivery history and wallet balance cannot be recovered.',
      confirmText: 'Yes, Delete',
      cancelText: 'Keep My Account',
      isDestructive: true,
      icon: HugeIcons.strokeRoundedDelete02,
      onConfirm: _submit,
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final auth = ref.read(riderAuthProvider.notifier);
    final deleted = await auth.deleteAccount(
      password: _passwordController.text,
      reason: _reason,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!deleted) {
      final message = ref.read(riderAuthProvider).errorMessage ??
          "We couldn't delete your account. Please try again.";
      auth.clearError();
      CustomDialog.showError(
        context: context,
        title: "Couldn't Delete Account",
        subtitle: message,
      );
      return;
    }

    // Same destination as logout. The dialog goes on the root navigator once
    // the login screen is in place — shown from this screen's context, it
    // would be removed along with it.
    final navigator = Navigator.of(context, rootNavigator: true);
    context.go(AppRoutes.login);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!navigator.mounted) return;
      CustomDialog.showSuccess(
        context: navigator.context,
        title: 'Account Deleted',
        subtitle: "Your account has been permanently deleted. We're sorry "
            'to see you go.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final gap = w * 0.04;

    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(HugeIcons.strokeRoundedArrowLeft01),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text('Delete Account'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(gap * 1.25, gap, gap * 1.25, gap),
                  children: [
                    const KycNotice(
                      icon: HugeIcons.strokeRoundedAlert02,
                      color: AppColors.error,
                      title: 'This action is permanent',
                      message: 'Deleting your account permanently removes '
                          'your profile, delivery history, earnings records '
                          'and any wallet balance you have not withdrawn. '
                          'This cannot be undone.',
                    ),
                    SizedBox(height: gap * 1.5),
                    _Heading(
                      title: 'Why are you leaving?',
                      subtitle:
                          'Help us improve — choose the reason that fits best.',
                      w: w,
                    ),
                    SizedBox(height: gap),
                    for (final reason in _reasons) ...[
                      _ReasonTile(
                        label: reason.label,
                        selected: reason.code == _reasonCode,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _reasonCode = reason.code);
                        },
                        w: w,
                      ),
                      SizedBox(height: gap * 0.6),
                    ],
                    if (_isOther) ...[
                      SizedBox(height: gap * 0.4),
                      AppTextField(
                        label: 'Tell us more',
                        hint: 'What made you decide to leave?',
                        controller: _otherReasonController,
                        maxLines: 3,
                        maxLength: 500,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                    SizedBox(height: gap * 1.5),
                    _Heading(
                      title: 'Confirm your password',
                      subtitle:
                          'For your security, enter your password to continue.',
                      w: w,
                    ),
                    SizedBox(height: gap),
                    AppPasswordField(
                      label: 'Password',
                      controller: _passwordController,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
              _DeleteButtonBar(
                enabled: _canSubmit,
                submitting: _submitting,
                onPressed: _confirmDeletion,
                w: w,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.subtitle, required this.w});

  final String title;
  final String subtitle;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: (w * 0.045).clamp(16.0, 20.0),
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: (w * 0.034).clamp(12.0, 15.0),
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// One choice in the single-select reason list.
class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.w,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double w;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(w * 0.035);
    final color = selected ? AppColors.primary : AppColors.textPrimary;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.07)
            : AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.04,
              vertical: w * 0.035,
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? HugeIcons.strokeRoundedCheckmarkCircle02
                      : HugeIcons.strokeRoundedCircle,
                  size: (w * 0.055).clamp(20.0, 26.0),
                  color: selected ? AppColors.primary : AppColors.textHint,
                ),
                SizedBox(width: w * 0.035),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: (w * 0.036).clamp(13.0, 16.0),
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteButtonBar extends StatelessWidget {
  const _DeleteButtonBar({
    required this.enabled,
    required this.submitting,
    required this.onPressed,
    required this.w,
  });

  final bool enabled;
  final bool submitting;
  final VoidCallback onPressed;
  final double w;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.scaffold,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: w * 0.03),
        child: SizedBox(
          width: double.infinity,
          height: (w * 0.14).clamp(48.0, 58.0),
          child: ElevatedButton(
            onPressed: enabled && !submitting ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.error.withValues(alpha: 0.35),
              disabledForegroundColor: Colors.white,
              elevation: 0,
            ),
            child: submitting
                ? SizedBox.square(
                    dimension: w * 0.055,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text('Delete My Account'),
          ),
        ),
      ),
    );
  }
}
