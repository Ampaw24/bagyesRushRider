import 'dart:math' show sin, pi;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:delivery_boy/features/rider/auth/views/screens/rider_vehicle_info_screen.dart';
import 'package:delivery_boy/features/rider/auth/views/widgets/registration_stepper.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_password_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_phone_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_text_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/password_strength_validator.dart';

class RiderSignupScreen extends ConsumerStatefulWidget {
  /// Values to restore into the form when registration fails or is redirected back.
  final Map<String, dynamic> prefill;

  const RiderSignupScreen({super.key, this.prefill = const {}});

  @override
  ConsumerState<RiderSignupScreen> createState() => _RiderSignupScreenState();
}

class _RiderSignupScreenState extends ConsumerState<RiderSignupScreen>
    with TickerProviderStateMixin {
  final _formKey0 = GlobalKey<FormState>();
  final _formKey1 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  late PageController _pageController;
  int _currentStep = 0;

  // Step 0: Personal Info
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneDigitsCtrl = TextEditingController();
  String _phone = '';

  // Step 1: Account Credentials & Region
  final _emailCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _password = '';

  // Step 2: Vehicle Type
  VehicleType _selectedVehicleType = VehicleType.motorcycle;

  // Step 3: Vehicle Specs
  final _plateCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();

  DateTime? _lastBackPress;
  Map<String, String> _serverErrors = {};

  late AnimationController _floatCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const List<String> _stepTitles = [
    'Personal Profile',
    'Account & Region',
    'Select Vehicle',
    'Vehicle Specs',
  ];

  static const List<String> _stepSubtitles = [
    'Enter your full name and phone number',
    'Setup your login credentials and operating city',
    'Choose the vehicle type for your deliveries',
    'Provide your license plate and vehicle details',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _passwordCtrl.addListener(() {
      setState(() => _password = _passwordCtrl.text);
    });

    for (final c in [
      _firstNameCtrl,
      _lastNameCtrl,
      _emailCtrl,
      _cityCtrl,
      _confirmCtrl,
      _plateCtrl,
      _yearCtrl,
      _makeCtrl,
      _modelCtrl,
      _colorCtrl,
    ]) {
      c.addListener(_rebuild);
    }

    _restorePrefill();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

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

    final fullPhone = (p['phone'] as String?) ?? '';
    _phone = fullPhone;
    _phoneDigitsCtrl.text = _localDigitsOf(fullPhone);

    final vehicleTypeStr = p['vehicleType'] as String? ?? p['vehicle_type'] as String?;
    if (vehicleTypeStr != null) {
      _selectedVehicleType = VehicleType.values.firstWhere(
        (e) => e.name == vehicleTypeStr || e.apiValue == vehicleTypeStr,
        orElse: () => VehicleType.motorcycle,
      );
    }

    _plateCtrl.text = (p['plate_number'] as String?) ?? '';
    if (p['vehicle_year'] != null) _yearCtrl.text = p['vehicle_year'].toString();
    _makeCtrl.text = (p['vehicle_make'] as String?) ?? '';
    _modelCtrl.text = (p['vehicle_model'] as String?) ?? '';
    _colorCtrl.text = (p['vehicle_colour'] as String?) ?? '';

    final errors = (p['field_errors'] as Map?)?.cast<String, String>();
    if (errors != null && errors.isNotEmpty) {
      _serverErrors = Map.of(errors);
      if (errors.containsKey('email') || errors.containsKey('city') || errors.containsKey('password')) {
        _navigateToStep(1);
      } else if (errors.containsKey('plate_number') || errors.containsKey('vehicle_type')) {
        _navigateToStep(3);
      }
    }
  }

  String _localDigitsOf(String e164) {
    final match = RegExp(r'^\+\d{1,4}').firstMatch(e164);
    return match == null ? e164 : e164.substring(match.end);
  }

  String? _takeServerError(String field) => _serverErrors[field];

  void _clearServerError(String field) {
    if (_serverErrors.containsKey(field)) {
      setState(() => _serverErrors.remove(field));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeCtrl.dispose();
    _floatCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneDigitsCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _plateCtrl.dispose();
    _yearCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  // ── Step Validation Getters ─────────────────────────────────────────────

  bool get _isStep0Valid {
    return _firstNameCtrl.text.trim().length >= 2 &&
        _lastNameCtrl.text.trim().length >= 2 &&
        _phone.length >= 9;
  }

  bool get _isStep1Valid {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final strength = evaluatePasswordStrength(_password);
    return emailRegex.hasMatch(_emailCtrl.text.trim()) &&
        _cityCtrl.text.trim().isNotEmpty &&
        _password.length >= 8 &&
        strength != PasswordStrength.weak &&
        _confirmCtrl.text == _password;
  }

  bool get _isStep2Valid => true; // Vehicle type is always selected

  bool get _isStep3Valid {
    final currentYear = DateTime.now().year;
    final yearVal = int.tryParse(_yearCtrl.text.trim());
    final yearValid = yearVal != null && yearVal >= 1980 && yearVal <= currentYear;

    return _plateCtrl.text.trim().isNotEmpty &&
        yearValid &&
        _makeCtrl.text.trim().isNotEmpty &&
        _modelCtrl.text.trim().isNotEmpty &&
        _colorCtrl.text.trim().isNotEmpty;
  }

  bool get _canProceedCurrentStep {
    switch (_currentStep) {
      case 0:
        return _isStep0Valid;
      case 1:
        return _isStep1Valid;
      case 2:
        return _isStep2Valid;
      case 3:
        return _isStep3Valid;
      default:
        return false;
    }
  }

  void _navigateToStep(int step) {
    if (step < 0 || step > 3) return;
    HapticFeedback.selectionClick();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _nextStep() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_currentStep == 0) {
      if (!_formKey0.currentState!.validate()) return;
    } else if (_currentStep == 1) {
      if (!_formKey1.currentState!.validate()) return;
    }
    if (_currentStep < 3) {
      _navigateToStep(_currentStep + 1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _navigateToStep(_currentStep - 1);
    }
  }

  Future<void> _submitRegistration() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey3.currentState!.validate()) return;

    HapticFeedback.mediumImpact();

    final ok = await ref.read(riderAuthProvider.notifier).register(
          email: _emailCtrl.text.trim(),
          phone: _phone,
          password: _password,
          confirmPassword: _confirmCtrl.text,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          vehicleType: _selectedVehicleType.apiValue,
          plateNumber: _plateCtrl.text.trim().toUpperCase(),
        );

    if (!mounted) return;

    if (!ok) {
      _handleRegisterFailure();
      return;
    }

    final collected = {
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phone,
      'city': _cityCtrl.text.trim(),
      'password': _password,
      'vehicleType': _selectedVehicleType.name,
      'vehicle_type': _selectedVehicleType.apiValue,
      'plate_number': _plateCtrl.text.trim().toUpperCase(),
      'vehicle_year': int.tryParse(_yearCtrl.text.trim()),
      'vehicle_make': _makeCtrl.text.trim(),
      'vehicle_model': _modelCtrl.text.trim(),
      'vehicle_colour': _colorCtrl.text.trim(),
      'registered': true,
    };

    context.go(AppRoutes.otp, extra: collected);
  }

  void _handleRegisterFailure() {
    final fieldErrors = ref.read(riderAuthProvider).fieldErrors;
    if (fieldErrors.isEmpty) return;

    String? first(String key) {
      final list = fieldErrors[key];
      return (list != null && list.isNotEmpty) ? list.first : null;
    }

    final plateMsg = first('plate_number') ?? first('vehicle_type');
    if (plateMsg != null) {
      setState(() => _serverErrors['plate_number'] = plateMsg);
      _navigateToStep(3);
      _formKey3.currentState?.validate();
      return;
    }

    final phoneMsg = first('phone');
    final emailMsg = first('email');
    if (phoneMsg != null) {
      setState(() => _serverErrors['phone'] = phoneMsg);
      _navigateToStep(0);
      _formKey0.currentState?.validate();
      return;
    }
    if (emailMsg != null) {
      setState(() => _serverErrors['email'] = emailMsg);
      _navigateToStep(1);
      _formKey1.currentState?.validate();
      return;
    }

    final firstErr = fieldErrors.values.expand((e) => e).firstOrNull ?? 'Registration failed';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(firstErr),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(riderAuthProvider).isLoading;

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
    final hPad = (w * 0.05).clamp(16.0, 32.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentStep > 0) {
          _previousStep();
          return;
        }
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _currentStep > 0
              ? IconButton(
                  icon: const Icon(
                    HugeIcons.strokeRoundedArrowLeft01,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                  onPressed: _previousStep,
                )
              : IconButton(
                  icon: const Icon(
                    HugeIcons.strokeRoundedCancel01,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                  onPressed: () => context.go(AppRoutes.login),
                ),
          title: Text(
            'Step ${_currentStep + 1} of 4',
            style: const TextStyle(
              fontFamily: 'Mukta',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                // ── Stepper Header ──────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: RegistrationStepper(
                    steps: const ['Personal', 'Account', 'Vehicle', 'Details'],
                    currentIndex: _currentStep,
                    onStepTapped: (step) => _navigateToStep(step),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Active Step Subheader ───────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _stepTitles[_currentStep],
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: (w * 0.068).clamp(22.0, 30.0),
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _stepSubtitles[_currentStep],
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: (w * 0.035).clamp(12.0, 15.0),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── PageView Step Content ───────────────────────────────────
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) => setState(() => _currentStep = page),
                    children: [
                      _buildStep0Personal(hPad, w, h),
                      _buildStep1Account(hPad, w, h),
                      _buildStep2VehicleType(hPad, w, h),
                      _buildStep3VehicleDetails(hPad, w, h),
                    ],
                  ),
                ),

                // ── Bottom Navigation Controls ──────────────────────────────
                _buildBottomControls(hPad, w, h, isLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 0: Personal Info ──────────────────────────────────────────────────

  Widget _buildStep0Personal(double hPad, double w, double h) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Form(
        key: _formKey0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: h * 0.01),

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

            SizedBox(height: h * 0.02),

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

            SizedBox(height: h * 0.02),

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
            SizedBox(height: h * 0.008),
            AppPhoneField(
              digitController: _phoneDigitsCtrl,
              initialDigits: _phoneDigitsCtrl.text.isEmpty ? null : _phoneDigitsCtrl.text,
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

            SizedBox(height: h * 0.03),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Account Credentials & Region ────────────────────────────────────

  Widget _buildStep1Account(double hPad, double w, double h) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: h * 0.01),

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
                final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!emailRegex.hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),

            SizedBox(height: h * 0.02),

            AppTextField(
              label: 'Operating City',
              hint: 'e.g. Accra',
              prefixIcon: HugeIcons.strokeRoundedCity03,
              controller: _cityCtrl,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [LengthLimitingTextInputFormatter(255)],
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

            SizedBox(height: h * 0.02),

            AppPasswordField(
              label: 'Password',
              hint: 'Create a strong password',
              controller: _passwordCtrl,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter a password';
                if (v.length < 8) return 'Password must be at least 8 characters';
                if (evaluatePasswordStrength(v) == PasswordStrength.weak) {
                  return 'Password is too weak';
                }
                return null;
              },
            ),

            PasswordStrengthValidator(password: _password),

            SizedBox(height: h * 0.02),

            AppPasswordField(
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              controller: _confirmCtrl,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v != _password) return 'Passwords do not match';
                return null;
              },
            ),

            SizedBox(height: h * 0.03),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Vehicle Type Selection ─────────────────────────────────────────

  Widget _buildStep2VehicleType(double hPad, double w, double h) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: h * 0.01),

          ...VehicleType.values.map((type) {
            final isSelected = _selectedVehicleType == type;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedVehicleType = type);
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: EdgeInsets.all(w * 0.04),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.04)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: (w * 0.13).clamp(44.0, 56.0),
                        height: (w * 0.13).clamp(44.0, 56.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          type.icon,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          size: 26,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.label,
                              style: TextStyle(
                                fontFamily: 'Mukta',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              type.description,
                              style: const TextStyle(
                                fontFamily: 'Mukta',
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                HugeIcons.strokeRoundedCheckmarkCircle01,
                                color: Colors.white,
                                size: 14,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          SizedBox(height: h * 0.03),
        ],
      ),
    );
  }

  // ── Step 3: Vehicle Specs & Details ────────────────────────────────────────

  Widget _buildStep3VehicleDetails(double hPad, double w, double h) {
    final currentYear = DateTime.now().year;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Form(
        key: _formKey3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: h * 0.005),

            // Animated Vehicle Icon Header
            Center(
              child: AnimatedBuilder(
                animation: _floatCtrl,
                builder: (context, child) {
                  final floatOffset = sin(_floatCtrl.value * 2 * pi) * 6.0;
                  return Transform.translate(
                    offset: Offset(0, floatOffset),
                    child: child,
                  );
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    _selectedVehicleType.icon,
                    size: 34,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            SizedBox(height: h * 0.02),

            AppTextField(
              label: 'License Plate Number',
              hint: 'e.g. GR-1234-22',
              prefixIcon: HugeIcons.strokeRoundedIdentityCard,
              controller: _plateCtrl,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [LengthLimitingTextInputFormatter(32)],
              onChanged: (_) {
                _clearServerError('plate_number');
                setState(() {});
              },
              validator: (v) {
                final serverError = _takeServerError('plate_number');
                if (serverError != null) return serverError;
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter the license plate number';
                }
                return null;
              },
            ),

            SizedBox(height: h * 0.018),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Year',
                    hint: 'e.g. 2022',
                    prefixIcon: HugeIcons.strokeRoundedCalendar01,
                    controller: _yearCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final y = int.tryParse(v.trim());
                      if (y == null || y < 1980 || y > currentYear) {
                        return '1980–$currentYear';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Make',
                    hint: 'e.g. Honda',
                    prefixIcon: HugeIcons.strokeRoundedCar01,
                    controller: _makeCtrl,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),

            SizedBox(height: h * 0.018),

            AppTextField(
              label: 'Model',
              hint: 'e.g. CB150R',
              prefixIcon: HugeIcons.strokeRoundedMotorbike01,
              controller: _modelCtrl,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter model' : null,
            ),

            SizedBox(height: h * 0.018),

            AppTextField(
              label: 'Color',
              hint: 'e.g. Red',
              prefixIcon: HugeIcons.strokeRoundedPaintBoard,
              controller: _colorCtrl,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter color' : null,
            ),

            SizedBox(height: h * 0.012),

            _ColorQuickPick(
              controller: _colorCtrl,
              onPicked: () => setState(() {}),
            ),

            if (_selectedVehicleType.isElectric) ...[
              SizedBox(height: h * 0.018),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(HugeIcons.strokeRoundedFlash, color: Color(0xFF0EA5E9), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Electric vehicle — ensure battery is charged before starting deliveries.',
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: 13,
                          color: Color(0xFF0369A1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: h * 0.03),
          ],
        ),
      ),
    );
  }

  // ── Bottom Navigation Controls ─────────────────────────────────────────────

  Widget _buildBottomControls(double hPad, double w, double h, bool isLoading) {
    final isLastStep = _currentStep == 3;
    final canProceed = _canProceedCurrentStep;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : _previousStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: AppGradientButton(
                  label: isLastStep
                      ? (isLoading ? 'Creating Account…' : 'Complete Registration')
                      : 'Continue',
                  isLoading: isLastStep ? isLoading : false,
                  onPressed: (!canProceed || isLoading)
                      ? null
                      : (isLastStep ? _submitRegistration : _nextStep),
                ),
              ),
            ],
          ),

          if (_currentStep == 0) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go(AppRoutes.login),
                  child: const Text(
                    'Sign In',
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
          ],
        ],
      ),
    );
  }
}

// ── Color Quick Pick Helper ──────────────────────────────────────────────────

class _ColorQuickPick extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onPicked;

  const _ColorQuickPick({required this.controller, required this.onPicked});

  static const _colors = [
    ('Black', Color(0xFF1A1A1A)),
    ('White', Color(0xFFF0F0F0)),
    ('Silver', Color(0xFFA8A8A8)),
    ('Red', AppColors.primary),
    ('Blue', Color(0xFF3182CE)),
    ('Yellow', Color(0xFFF59E0B)),
    ('Green', Color(0xFF38A169)),
    ('Orange', Color(0xFFDD6B20)),
  ];

  @override
  Widget build(BuildContext context) {
    final current = controller.text.trim().toLowerCase();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _colors.map((entry) {
        final name = entry.$1;
        final color = entry.$2;
        final isSelected = current == name.toLowerCase();
        final isLight = name == 'White' || name == 'Yellow';

        return GestureDetector(
          onTap: () {
            controller.text = name;
            onPicked();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              name,
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? (isLight ? Colors.black87 : Colors.white)
                    : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
