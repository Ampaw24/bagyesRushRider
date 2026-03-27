import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/constant/asset_images.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_text_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_password_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_phone_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/password_strength_validator.dart';

class RiderSignupScreen extends StatefulWidget {
  const RiderSignupScreen({super.key});

  @override
  State<RiderSignupScreen> createState() => _RiderSignupScreenState();
}

class _RiderSignupScreenState extends State<RiderSignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _phone = '';
  String _password = '';
  DateTime? _lastBackPress;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
    _passwordCtrl.addListener(() {
      setState(() => _password = _passwordCtrl.text);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _isFilled {
    final strength = evaluatePasswordStrength(_password);
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return _nameCtrl.text.trim().length >= 2 &&
        _phone.length >= 9 &&
        emailRegex.hasMatch(_emailCtrl.text.trim()) &&
        _password.isNotEmpty &&
        strength != PasswordStrength.weak &&
        _confirmCtrl.text == _password;
  }

  void _proceed() {
    if (!_formKey.currentState!.validate()) return;

    final strength = evaluatePasswordStrength(_password);
    if (strength == PasswordStrength.weak) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please use a stronger password'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_confirmCtrl.text != _password) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.go(AppRoutes.vehicleInfo, extra: {
      'name': _nameCtrl.text.trim(),
      'phone': _phone,
      'email': _emailCtrl.text.trim(),
      'password': _password,
    });
  }

  @override
  Widget build(BuildContext context) {
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
            textColor: Colors.white,
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.noScaling),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: h * 0.05),

                        // ── Logo ──────────────────────────────────────────
                        Center(
                          child: Container(
                            width: (w * 0.22).clamp(72.0, 100.0),
                            height: (w * 0.22).clamp(72.0, 100.0),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                AssetImages.deliveryBoy,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: h * 0.038),

                        // ── Heading ───────────────────────────────────────
                        Text(
                          'Create account',
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: (w * 0.072).clamp(24.0, 34.0),
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: h * 0.006),
                        Text(
                          'Join BagyesRUSH and start delivering',
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: (w * 0.036).clamp(12.0, 16.0),
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        SizedBox(height: h * 0.038),

                        // ── Full Name ─────────────────────────────────────
                        AppTextField(
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          prefixIcon: HugeIcons.strokeRoundedUser,
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.trim().length < 2) {
                              return 'Enter your full name (min 2 characters)';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: h * 0.022),

                        // ── Phone Number ──────────────────────────────────
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
                        SizedBox(height: h * 0.010),
                        AppPhoneField(
                          onChanged: (full) => setState(() => _phone = full),
                          validator: (v) {
                            if (v == null || v.trim().length < 9) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: h * 0.022),

                        // ── Email ─────────────────────────────────────────
                        AppTextField(
                          label: 'Email Address',
                          hint: 'rider@example.com',
                          prefixIcon: HugeIcons.strokeRoundedMail01,
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter your email address';
                            }
                            final emailRegex =
                                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                            if (!emailRegex.hasMatch(v.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: h * 0.022),

                        // ── Password ──────────────────────────────────────
                        AppPasswordField(
                          label: 'Password',
                          hint: 'Create a strong password',
                          controller: _passwordCtrl,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (evaluatePasswordStrength(v) ==
                                PasswordStrength.weak) {
                              return 'Password is too weak';
                            }
                            return null;
                          },
                        ),

                        // ── Password strength indicator ───────────────────
                        PasswordStrengthValidator(password: _password),

                        SizedBox(height: h * 0.022),

                        // ── Confirm Password ──────────────────────────────
                        AppPasswordField(
                          label: 'Confirm Password',
                          hint: 'Re-enter your password',
                          controller: _confirmCtrl,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v != _password) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: h * 0.038),

                        // ── Continue button ───────────────────────────────
                        AppGradientButton(
                          label: 'Continue',
                          onPressed: _isFilled ? _proceed : null,
                        ),

                        SizedBox(height: h * 0.032),

                        // ── Sign In link ──────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                fontFamily: 'Mukta',
                                color: AppColors.textSecondary,
                                fontSize: (w * 0.036).clamp(12.0, 15.0),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go(AppRoutes.login),
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  fontFamily: 'Mukta',
                                  color: AppColors.primary,
                                  fontSize: (w * 0.036).clamp(12.0, 15.0),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: h * 0.04),
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
