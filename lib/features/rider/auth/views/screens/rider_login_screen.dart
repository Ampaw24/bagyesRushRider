import 'package:delivery_boy/components/widget/decorative.widget.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_phone_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:delivery_boy/constant/asset_images.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:delivery_boy/features/rider/auth/views/widgets/forgot_password_sheet.dart';

class RiderLoginScreen extends ConsumerStatefulWidget {
  const RiderLoginScreen({super.key});

  @override
  ConsumerState<RiderLoginScreen> createState() => _RiderLoginScreenState();
}

class _RiderLoginScreenState extends ConsumerState<RiderLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  String _fullPhone = '';
  String _password = '';
  DateTime? _lastBackPress;

  final _passwordCtrl = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  // Phone digits only (without country code) need ≥ 9 chars
  bool get _isFilled => _fullPhone.length >= 12 && _password.isNotEmpty;

  Future<void> _login() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(riderAuthProvider.notifier).login(
          phone: _fullPhone,
          password: _password,
        );
    if (!success || !mounted) return;

    // An account that never completed phone verification resumes there.
    final user = ref.read(riderAuthProvider).user;
    if (user != null && !user.phoneVerified) {
      context.go(AppRoutes.otp, extra: {
        'phone': _fullPhone,
        'password': _password,
        'mode': 'verify',
      });
      return;
    }

    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(riderAuthProvider);
    final isLoading = authState.status == AuthStatus.loading;

    ref.listen<RiderAuthState>(riderAuthProvider, (_, next) {
      // Only this screen's own errors: the forgot-password sheet and the
      // screens pushed over login report theirs, and clearing it here
      // would race them for the message.
      if (!mounted || ModalRoute.isCurrentOf(context) != true) return;
      if (next.errorMessage != null) {
        CustomDialog.showError(
          context: context,
          title: 'Sign In Failed',
          subtitle: next.errorMessage!,
        );
        ref.read(riderAuthProvider.notifier).clearError();
      }
    });

    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final h = mq.size.height;
    final hPad = (w * 0.06).clamp(20.0, 40.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          Fluttertoast.showToast(
            msg: 'Press Back Once Again to Exit.',
            backgroundColor: Colors.black,
            textColor: whiteColor,
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.kDecorativeBackgroundColor,
        body: DecorativeBackground(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Form(
                    key: _formKey,
                    child: CustomScrollView(
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: hPad),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: h * 0.06),

                                // ── Logo + Brand ───────────────────────────────
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: (w * 0.22).clamp(72.0, 100.0),
                                      height: (w * 0.22).clamp(72.0, 100.0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(22),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.22),
                                            blurRadius: 24,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(22),
                                        child: Image.asset(
                                          AssetImages.bagyesLogo,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: h * 0.014),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Bagyes',
                                            style: TextStyle(
                                              fontFamily: 'Mukta',
                                              fontSize:
                                                  (w * 0.058).clamp(18.0, 26.0),
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.textPrimary,
                                              letterSpacing: -0.4,
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'RUSH',
                                            style: TextStyle(
                                              fontFamily: 'Mukta',
                                              fontSize:
                                                  (w * 0.058).clamp(18.0, 26.0),
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.primary,
                                              letterSpacing: -0.4,
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' Rider',
                                            style: TextStyle(
                                              fontFamily: 'Mukta',
                                              fontSize:
                                                  (w * 0.042).clamp(13.0, 18.0),
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textSecondary,
                                              letterSpacing: 0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: h * 0.048),

                                // ── Heading ────────────────────────────────────
                                Text(
                                  'Welcome back',
                                  style: TextStyle(
                                    fontFamily: 'Mukta',
                                    fontSize: (w * 0.072).clamp(24.0, 34.0),
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.8,
                                    height: 1.1,
                                  ),
                                ),
                                SizedBox(height: h * 0.006),
                                Text(
                                  'Sign in to continue delivering',
                                  style: TextStyle(
                                    fontFamily: 'Mukta',
                                    fontSize: (w * 0.036).clamp(12.0, 16.0),
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),

                                SizedBox(height: h * 0.036),

                                // ── Phone Label ────────────────────────────────
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
                                const SizedBox(height: 5),

                                // ── Phone Field ────────────────────────────────
                                AppPhoneField(
                                  onChanged: (full) =>
                                      setState(() => _fullPhone = full),
                                  validator: (v) {
                                    if (v == null || v.trim().length < 9) {
                                      return 'Enter a valid phone number';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // ── Password Label ─────────────────────────────
                                Text(
                                  'Password',
                                  style: TextStyle(
                                    fontFamily: 'Mukta',
                                    fontSize: (w * 0.033).clamp(11.0, 14.0),
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 5),

                                // ── Password Field ─────────────────────────────
                                TextFormField(
                                  controller: _passwordCtrl,
                                  obscureText: _obscurePassword,
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  keyboardType: TextInputType.visiblePassword,
                                  textInputAction: TextInputAction.done,
                                  enabled: !isLoading,
                                  onChanged: (v) =>
                                      setState(() => _password = v.trim()),
                                  onFieldSubmitted: (_) {
                                    if (!isLoading && _isFilled) _login();
                                  },
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                  style: TextStyle(
                                    fontFamily: 'Mukta',
                                    fontSize: (w * 0.038).clamp(13.0, 16.0),
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your password',
                                    prefixIcon: Icon(
                                      HugeIcons.strokeRoundedLock,
                                      size: 20,
                                      color: Colors.grey.shade400,
                                    ),
                                    suffixIcon: GestureDetector(
                                      onTap: () => setState(() =>
                                          _obscurePassword = !_obscurePassword),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: w * 0.03),
                                        child: Icon(
                                          _obscurePassword
                                              ? HugeIcons.strokeRoundedViewOff
                                              : HugeIcons.strokeRoundedEye,
                                          size: 20,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                    hintStyle: TextStyle(
                                      fontFamily: 'Mukta',
                                      fontSize: (w * 0.036).clamp(12.0, 15.0),
                                      color: AppColors.textHint,
                                    ),
                                    filled: true,
                                    fillColor: isLoading
                                        ? Colors.grey.shade100
                                        : const Color(0xFFF8F9FB),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppColors.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppColors.border, width: 1.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppColors.primary, width: 1.5),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppColors.error, width: 1.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppColors.error, width: 1.5),
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppColors.border),
                                    ),
                                  ),
                                ),

                                // ── Forgot Password ────────────────────────────
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : () => ForgotPasswordSheet.show(context),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6, horizontal: 0),
                                    ),
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        fontFamily: 'Mukta',
                                        color: AppColors.primary,
                                        fontSize: (w * 0.033).clamp(11.0, 14.0),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // ── Sign In Button ─────────────────────────────
                                SizedBox(
                                  width: double.infinity,
                                  height: (h * 0.058).clamp(46.0, 54.0),
                                  child: ElevatedButton(
                                    onPressed:
                                        isLoading || !_isFilled ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      disabledBackgroundColor: AppColors.primary
                                          .withValues(alpha: 0.5),
                                      elevation: 0,
                                      // The theme's default vertical padding (14+14) no
                                      // longer fits this SizedBox's fixed height, which
                                      // was clipping the label — let the box center it.
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: isLoading
                                        ? const SpinKitRing(
                                            color: Colors.white,
                                            lineWidth: 2.5,
                                            size: 26,
                                          )
                                        : Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontFamily: 'Mukta',
                                              color: Colors.white,
                                              fontSize:
                                                  (w * 0.04).clamp(14.0, 17.0),
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                  ),
                                ),

                                const Spacer(),

                                // ── Sign Up link ───────────────────────────────
                                Padding(
                                  padding: EdgeInsets.only(bottom: h * 0.035),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Don't have an account? ",
                                        style: TextStyle(
                                          fontFamily: 'Mukta',
                                          color: AppColors.textSecondary,
                                          fontSize:
                                              (w * 0.036).clamp(12.0, 15.0),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: isLoading
                                            ? null
                                            : () =>
                                                context.go(AppRoutes.signup),
                                        child: Text(
                                          'Sign Up',
                                          style: TextStyle(
                                            fontFamily: 'Mukta',
                                            color: AppColors.primary,
                                            fontSize:
                                                (w * 0.036).clamp(12.0, 15.0),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
