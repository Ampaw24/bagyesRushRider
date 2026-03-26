import 'package:delivery_boy/features/rider/shared_widgets/app_phone_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/constant/asset_images.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';

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
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
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
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(riderAuthProvider.notifier).login(
          phone: _fullPhone,
          password: _password,
        );
    if (success && mounted) {
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(riderAuthProvider);
    final isLoading = authState.status == AuthStatus.loading;

    ref.listen<RiderAuthState>(riderAuthProvider, (_, next) {
      if (next.errorMessage != null) {
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
        backgroundColor: AppColors.scaffold,
        body: SafeArea(
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
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    width: (w * 0.22).clamp(72.0, 100.0),
                                    height: (w * 0.22).clamp(72.0, 100.0),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(22),
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
                                      borderRadius:
                                          BorderRadius.circular(22),
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
                                            fontSize: (w * 0.058)
                                                .clamp(18.0, 26.0),
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.textPrimary,
                                            letterSpacing: -0.4,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'RUSH',
                                          style: TextStyle(
                                            fontFamily: 'Mukta',
                                            fontSize: (w * 0.058)
                                                .clamp(18.0, 26.0),
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.primary,
                                            letterSpacing: -0.4,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' Rider',
                                          style: TextStyle(
                                            fontFamily: 'Mukta',
                                            fontSize: (w * 0.042)
                                                .clamp(13.0, 18.0),
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
                            const SizedBox(height: 6),
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

                            SizedBox(height: h * 0.02),

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
                              style: const TextStyle(
                                fontFamily: 'Mukta',
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20,
                                  color: Colors.grey.shade400,
                                ),
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                  child: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                labelStyle: TextStyle(
                                  fontFamily: 'Mukta',
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                                hintStyle: TextStyle(
                                  fontFamily: 'Mukta',
                                  fontSize: 14,
                                  color: Colors.grey.shade400,
                                ),
                                filled: true,
                                fillColor: isLoading
                                    ? Colors.grey.shade100
                                    : Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade200,
                                      width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.primary, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.error, width: 1.5),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.error, width: 2),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade200),
                                ),
                              ),
                            ),

                            // ── Forgot Password ────────────────────────────
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () => context
                                        .push(AppRoutes.forgotPassword),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 0),
                                ),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontFamily: 'Mukta',
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: h * 0.01),

                            // ── Sign In Button ─────────────────────────────
                            SizedBox(
                              width: double.infinity,
                              height: (h * 0.072).clamp(50.0, 60.0),
                              child: ElevatedButton(
                                onPressed:
                                    (isLoading || !_isFilled) ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  disabledBackgroundColor:
                                      AppColors.primary.withValues(alpha: 0.5),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: isLoading
                                    ? const SpinKitRing(
                                        color: Colors.white,
                                        lineWidth: 2.5,
                                        size: 26,
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontFamily: 'Mukta',
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                              ),
                            ),

                            const Spacer(),

                            // ── Sign Up link ───────────────────────────────
                            Padding(
                              padding: const EdgeInsets.only(bottom: 28),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: TextStyle(
                                      fontFamily: 'Mukta',
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: isLoading
                                        ? null
                                        : () =>
                                            context.go(AppRoutes.signup),
                                    child: const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        fontFamily: 'Mukta',
                                        color: AppColors.primary,
                                        fontSize: 14,
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
    );
  }
}
