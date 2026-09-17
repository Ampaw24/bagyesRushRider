import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/auth/data/rider_agreement_content.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:delivery_boy/features/rider/auth/views/widgets/registration_stepper.dart';
import 'package:hugeicons/hugeicons.dart';

/// Final gate of the signup wizard: the rider accepts the terms/consent,
/// which registers the account and records that consent, then hands off
/// to phone verification.
///
/// `POST /rider/me/agreement` requires Bearer auth, so it cannot fire
/// before `/register` the way the checkout order on this screen implies —
/// tapping "Accept & Continue" runs `register` first to obtain a session,
/// then submits the consent captured here. See
/// `RiderAuthNotifier.registerAndAcceptAgreement`.
class RiderTermsConditionsScreen extends ConsumerStatefulWidget {
  /// Everything collected across the signup wizard: `email, phone, password,
  /// first_name, last_name, city, vehicle_type, plate_number` plus the
  /// vehicle spec fields `/register` doesn't accept.
  final Map<String, dynamic> credentials;

  const RiderTermsConditionsScreen({super.key, required this.credentials});

  @override
  ConsumerState<RiderTermsConditionsScreen> createState() =>
      _RiderTermsConditionsScreenState();
}

class _RiderTermsConditionsScreenState
    extends ConsumerState<RiderTermsConditionsScreen>
    with SingleTickerProviderStateMixin {
  static const _termsVersion = RiderAgreementContent.version;

  bool _acceptTerms = false;
  bool _consentToVerification = false;

  /// Guards against a double-submit while `register` + `acceptAgreement`
  /// are in flight — mirrors the OTP screen's own `_busy` guard.
  bool _busy = false;

  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  bool get _canSubmit => _acceptTerms && _consentToVerification && !_busy;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entranceFade =
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut),
    );
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _goBack() {
    // Returns to Vehicle Specs (not the first page of the wizard) so the
    // rider doesn't have to retype everything.
    context.go(AppRoutes.signup, extra: {
      ...widget.credentials,
      'resume_step': 3,
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();

    final c = widget.credentials;
    final ok =
        await ref.read(riderAuthProvider.notifier).registerAndAcceptAgreement(
              email: c['email'] as String? ?? '',
              phone: c['phone'] as String? ?? '',
              password: c['password'] as String? ?? '',
              confirmPassword: c['password'] as String? ?? '',
              firstName: c['first_name'] as String? ?? '',
              lastName: c['last_name'] as String? ?? '',
              city: c['city'] as String? ?? '',
              vehicleType: c['vehicle_type'] as String? ?? '',
              plateNumber: c['plate_number'] as String? ?? '',
              acceptTerms: _acceptTerms,
              consentToVerification: _consentToVerification,
              termsVersion: _termsVersion,
            );

    if (!mounted) return;

    if (!ok) {
      setState(() => _busy = false);
      _handleRegisterFailure();
      return;
    }

    context.go(AppRoutes.otp, extra: {...c, 'registered': true});
  }

  /// Sends each rejected field back to the wizard page that owns it —
  /// `RiderSignupScreen._restorePrefill` already knows how to place
  /// `field_errors` on the right step.
  void _handleRegisterFailure() {
    final fieldErrors = ref.read(riderAuthProvider).fieldErrors;
    if (fieldErrors.isEmpty) return; // the ref.listen snackbar covers it

    String? first(String key) {
      final list = fieldErrors[key];
      return (list != null && list.isNotEmpty) ? list.first : null;
    }

    final takenAccount = fieldErrors.entries.any(
      (e) =>
          (e.key == 'phone' || e.key == 'email') &&
          e.value.any((m) =>
              RegExp(r'already been taken', caseSensitive: false).hasMatch(m)),
    );

    final messages = {
      for (final key in fieldErrors.keys)
        if (first(key) != null) key: first(key)!,
    };

    if (takenAccount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(messages.values.first),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Sign in',
            textColor: Colors.white,
            onPressed: () => context.go(AppRoutes.login),
          ),
        ),
      );
      return;
    }

    context.go(AppRoutes.signup, extra: {
      ...widget.credentials,
      'field_errors': messages,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(riderAuthProvider).isLoading || _busy;

    // Field-specific messages are routed by _handleRegisterFailure; this
    // catches everything else (network, 500s, unmapped fields).
    ref.listen<RiderAuthState>(riderAuthProvider, (_, next) {
      if (!mounted) return;
      if (next.errorMessage != null && next.fieldErrors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(riderAuthProvider.notifier).clearError();
      }
    });

    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final h = mq.size.height;
    final hPad = (w * 0.06).clamp(20.0, 40.0);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            HugeIcons.strokeRoundedArrowLeft01,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: _goBack,
        ),
      ),
      body: SafeArea(
        top: false,
        child: FadeTransition(
          opacity: _entranceFade,
          child: SlideTransition(
            position: _entranceSlide,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      SizedBox(height: h * 0.01),

                      RegistrationStepper(
                        steps: const ['Sign Up', 'Terms', 'Verify'],
                        currentIndex: 1,
                      ),

                      SizedBox(height: h * 0.032),

                      _HeaderIcon(w: w),

                      SizedBox(height: h * 0.024),

                      Text(
                        'Terms & Conditions',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: (w * 0.072).clamp(24.0, 34.0),
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: h * 0.008),
                      Text(
                        'Review and accept to create your rider account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: (w * 0.036).clamp(12.0, 16.0),
                          color: AppColors.textSecondary,
                        ),
                      ),

                      SizedBox(height: h * 0.028),

                      _TermsDocument(w: w, h: h),

                      SizedBox(height: h * 0.022),

                      _ConsentTile(
                        w: w,
                        value: _acceptTerms,
                        icon: HugeIcons.strokeRoundedFile01,
                        title: 'I accept the Terms & Conditions',
                        subtitle:
                            'I have read and agree to the rider Terms of '
                            'Service and Privacy Policy.',
                        onChanged: (v) =>
                            setState(() => _acceptTerms = v ?? false),
                      ),

                      SizedBox(height: h * 0.014),

                      _ConsentTile(
                        w: w,
                        value: _consentToVerification,
                        icon: HugeIcons.strokeRoundedUserCheck01,
                        title: 'I consent to verification checks',
                        subtitle:
                            'I authorise BagyesRUSH to verify my identity, '
                            'vehicle and background before I start '
                            'accepting deliveries.',
                        onChanged: (v) =>
                            setState(() => _consentToVerification = v ?? false),
                      ),

                      SizedBox(height: h * 0.036),

                      AppGradientButton(
                        label: isLoading
                            ? 'Creating account…'
                            : 'Accept & Continue',
                        isLoading: isLoading,
                        onPressed: (_canSubmit && !isLoading) ? _submit : null,
                      ),

                      SizedBox(height: h * 0.04),
                    ]),
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

// ── Header icon ────────────────────────────────────────────────────────────

class _HeaderIcon extends StatelessWidget {
  final double w;

  const _HeaderIcon({required this.w});

  @override
  Widget build(BuildContext context) {
    final containerSize = (w * 0.24).clamp(80.0, 110.0);

    return Center(
      child: Container(
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: 0.1),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.18),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Icon(
            HugeIcons.strokeRoundedShield01,
            size: containerSize * 0.46,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ── Terms document ───────────────────────────────────────────────────────────

class _TermsDocument extends StatelessWidget {
  final double w;
  final double h;

  const _TermsDocument({required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: h * 0.36),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Scrollbar(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(w * 0.045),
          child: Html(
            data: RiderAgreementContent.html,
            shrinkWrap: true,
            style: {
              'body': Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                fontFamily: 'Mukta',
                fontSize: FontSize((w * 0.033).clamp(11.5, 13.5)),
                color: AppColors.textSecondary,
                lineHeight: LineHeight.em(1.35),
              ),
              'h2': Style(
                fontFamily: 'Mukta',
                fontSize: FontSize((w * 0.042).clamp(15.0, 17.0)),
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                margin: Margins.only(bottom: 10),
              ),
              'h3': Style(
                fontFamily: 'Mukta',
                fontSize: FontSize((w * 0.038).clamp(13.0, 15.0)),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                margin: Margins.only(top: 14, bottom: 4),
              ),
              'p': Style(margin: Margins.only(bottom: 8)),
              'ol': Style(margin: Margins.only(bottom: 8)),
              'li': Style(margin: Margins.only(bottom: 4)),
            },
          ),
        ),
      ),
    );
  }
}

// ── Consent checkbox tile ────────────────────────────────────────────────────

class _ConsentTile extends StatelessWidget {
  final double w;
  final bool value;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<bool?> onChanged;

  const _ConsentTile({
    required this.w,
    required this.value,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(w * 0.04),
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(w * 0.036),
        decoration: BoxDecoration(
          color: value
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.card,
          borderRadius: BorderRadius.circular(w * 0.04),
          border: Border.all(
            color: value
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border,
            width: value ? 1.4 : 0.8,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: (w * 0.07).clamp(24.0, 30.0),
              height: (w * 0.07).clamp(24.0, 30.0),
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            SizedBox(width: w * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: (w * 0.042).clamp(15.0, 18.0), color: AppColors.primary),
                      SizedBox(width: w * 0.016),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: (w * 0.036).clamp(13.0, 15.0),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: w * 0.01),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: (w * 0.031).clamp(11.0, 13.0),
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
