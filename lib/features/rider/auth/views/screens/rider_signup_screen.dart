import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/constant/asset_images.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_text_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_password_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_phone_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/password_strength_validator.dart';

class RiderSignupScreen extends ConsumerStatefulWidget {
  /// Values to restore into the form, forwarded back here when registration
  /// fails on a later screen for a field typed on this one. Empty on a fresh
  /// start.
  final Map<String, dynamic> prefill;

  const RiderSignupScreen({super.key, this.prefill = const {}});

  @override
  ConsumerState<RiderSignupScreen> createState() => _RiderSignupScreenState();
}

class _RiderSignupScreenState extends ConsumerState<RiderSignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneDigitsCtrl = TextEditingController();

  String _phone = '';
  String _password = '';
  DateTime? _lastBackPress;

  /// Server-side rejections for fields on this screen, seeded on arrival
  /// when we've been sent back from the vehicle screen. Cleared per-field as
  /// the user edits.
  Map<String, String> _serverErrors = {};

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
    _restorePrefill();
  }

  /// Repopulates the form when we've been bounced back from a failed
  /// registration, and surfaces whichever field the server rejected.
  void _restorePrefill() {
    final p = widget.prefill;
    if (p.isEmpty) return;

    _firstNameCtrl.text = (p['first_name'] as String?) ?? '';
    _lastNameCtrl.text = (p['last_name'] as String?) ?? '';
    _emailCtrl.text = (p['email'] as String?) ?? '';
    _cityCtrl.text = (p['city'] as String?) ?? '';
    _passwordCtrl.text = (p['password'] as String?) ?? '';
    _confirmCtrl.text = (p['password'] as String?) ?? '';
    _password = _passwordCtrl.text;

    // AppPhoneField wants the local digits; the map carries E.164.
    final fullPhone = (p['phone'] as String?) ?? '';
    _phone = fullPhone;
    _phoneDigitsCtrl.text = _localDigitsOf(fullPhone);

    final errors = (p['field_errors'] as Map?)?.cast<String, String>();
    if (errors != null && errors.isNotEmpty) {
      _serverErrors = Map.of(errors);
      // Run validation once mounted so the rejected field is already marked.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _formKey.currentState?.validate();
      });
    }
  }

  /// Strips the country code so the digits can seed AppPhoneField.
  String _localDigitsOf(String e164) {
    final match = RegExp(r'^\+\d{1,4}').firstMatch(e164);
    return match == null ? e164 : e164.substring(match.end);
  }

  /// Consumes a server error once — the message stops applying as soon as
  /// the user edits that field.
  String? _takeServerError(String field) => _serverErrors[field];

  void _clearServerError(String field) {
    if (_serverErrors.containsKey(field)) {
      setState(() => _serverErrors.remove(field));
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _phoneDigitsCtrl.dispose();
    super.dispose();
  }

  bool get _isFilled {
    final strength = evaluatePasswordStrength(_password);
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return _firstNameCtrl.text.trim().length >= 2 &&
        _lastNameCtrl.text.trim().length >= 2 &&
        _phone.length >= 9 &&
        emailRegex.hasMatch(_emailCtrl.text.trim()) &&
        _cityCtrl.text.trim().isNotEmpty &&
        _password.length >= 8 && // backend: min:8
        strength != PasswordStrength.weak &&
        _confirmCtrl.text == _password;
  }

  Future<void> _proceed() async {
    FocusManager.instance.primaryFocus?.unfocus();
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

    // No network call here. `POST /register` requires vehicle_type and
    // plate_number for riders, so registration can only happen once the
    // vehicle screens have run — see rider_vehicle_details_screen.
    context.go(AppRoutes.vehicleInfo, extra: {
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phone,
      'city': _cityCtrl.text.trim(),
      'password': _password,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(riderAuthProvider).isLoading;

    ref.listen<RiderAuthState>(riderAuthProvider, (_, next) {
      if (!mounted) return;
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

                        // ── First Name ────────────────────────────────────
                        AppTextField(
                          label: 'First Name',
                          hint: 'Enter your first name',
                          prefixIcon: HugeIcons.strokeRoundedUser,
                          controller: _firstNameCtrl,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.trim().length < 2) {
                              return 'Enter your first name (min 2 characters)';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: h * 0.022),

                        // ── Last Name ─────────────────────────────────────
                        AppTextField(
                          label: 'Last Name',
                          hint: 'Enter your last name',
                          prefixIcon: HugeIcons.strokeRoundedUser,
                          controller: _lastNameCtrl,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.trim().length < 2) {
                              return 'Enter your last name (min 2 characters)';
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
                          digitController: _phoneDigitsCtrl,
                          initialDigits: _phoneDigitsCtrl.text.isEmpty
                              ? null
                              : _phoneDigitsCtrl.text,
                          onChanged: (full) {
                            _clearServerError('phone');
                            setState(() => _phone = full);
                          },
                          validator: (v) {
                            final serverError = _takeServerError('phone');
                            if (serverError != null) return serverError;
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
                          onChanged: (_) {
                            _clearServerError('email');
                            setState(() {});
                          },
                          validator: (v) {
                            final serverError = _takeServerError('email');
                            if (serverError != null) return serverError;
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

                        // ── City ──────────────────────────────────────────
                        // Required by the backend for riders and vendors.
                        AppTextField(
                          label: 'City',
                          hint: 'e.g. Accra',
                          prefixIcon: HugeIcons.strokeRoundedCity03,
                          controller: _cityCtrl,
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(255),
                          ],
                          onChanged: (_) {
                            _clearServerError('city');
                            setState(() {});
                          },
                          validator: (v) {
                            final serverError = _takeServerError('city');
                            if (serverError != null) return serverError;
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter the city you will operate in';
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
                            // Length first — "too weak" isn't actionable
                            // when the real problem is that it's short.
                            if (v.length < 8) {
                              return 'Password must be at least 8 characters';
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
                          label: isLoading ? 'Creating account…' : 'Continue',
                          onPressed:
                              (_isFilled && !isLoading) ? _proceed : null,
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
