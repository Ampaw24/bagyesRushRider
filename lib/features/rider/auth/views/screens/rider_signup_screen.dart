import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
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
    return _nameCtrl.text.trim().length >= 2 &&
        _phone.length >= 9 &&
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

    context.go(AppRoutes.otp, extra: {
      'name': _nameCtrl.text.trim(),
      'phone': _phone,
      'email': _emailCtrl.text.trim(),
      'password': _password,
    });
  }

  @override
  Widget build(BuildContext context) {
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
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      // Logo
                      Center(
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(24),
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

                      const SizedBox(height: 32),

                      const Text(
                        'Create account',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Join BagyesRUSH and start delivering',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Full Name
                      AppTextField(
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        prefixIcon: Icons.person_outline_rounded,
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

                      const SizedBox(height: 16),

                      // Phone Number
                      AppPhoneField(
                        onChanged: (full) =>
                            setState(() => _phone = full),
                        validator: (v) {
                          if (v == null || v.trim().length < 9) {
                            return 'Enter a valid phone number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Email (optional)
                      AppTextField(
                        label: 'Email Address (optional)',
                        hint: 'rider@example.com',
                        prefixIcon: Icons.email_outlined,
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final emailRegex =
                              RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!emailRegex.hasMatch(v.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Password
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

                      // Password strength
                      PasswordStrengthValidator(password: _password),

                      const SizedBox(height: 16),

                      // Confirm Password
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

                      const SizedBox(height: 32),

                      AppGradientButton(
                        label: 'Continue',
                        onPressed: _isFilled ? _proceed : null,
                      ),

                      const SizedBox(height: 28),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.login),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
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
