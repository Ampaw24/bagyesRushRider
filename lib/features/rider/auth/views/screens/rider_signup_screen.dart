import 'dart:math' as math;

import 'package:gopady_rider/constant/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:gopady_rider/constant/app_theme.dart';
import 'package:gopady_rider/core/router/app_routes.dart';
import 'package:gopady_rider/core/widgets/app_gradient_button.dart';
import 'package:gopady_rider/core/widgets/custom_dialogs.dart';
import 'package:gopady_rider/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:gopady_rider/features/rider/auth/views/widgets/registration_stepper.dart';
import 'package:gopady_rider/features/rider/auth/views/widgets/signup_vehicle_step.dart';
import 'package:gopady_rider/features/rider/shared_widgets/app_password_field.dart';
import 'package:gopady_rider/features/rider/shared_widgets/app_phone_field.dart';
import 'package:gopady_rider/features/rider/shared_widgets/app_select_field.dart';
import 'package:gopady_rider/features/rider/shared_widgets/app_text_field.dart';
import 'package:gopady_rider/features/rider/shared_widgets/password_strength_validator.dart';
import 'package:gopady_rider/features/rider/vehicles/model/vehicle_type_model.dart';
import 'package:gopady_rider/features/rider/vehicles/viewmodel/vehicle_catalog_viewmodel.dart';

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
  final _formKey2 = GlobalKey<FormState>();

  late PageController _pageController;
  int _currentStep = 0;

  // Step 0: Personal Info + Email + Operating City
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneDigitsCtrl = TextEditingController();
  String _phone = '';
  final _emailCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  // Step 1: Security (Password)
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _password = '';

  // Step 2: Vehicle — only what `/register` requires for a rider
  // (`vehicle_type_id`, `plate_number`). Make, model, year and colour are
  // collected later, in the KYC vehicle section.
  VehicleTypeModel? _selectedVehicleType;
  final _plateCtrl = TextEditingController();

  /// Type id to re-select once the catalogue loads after a register failure
  /// sends the rider back here with [widget.prefill].
  int? _pendingVehicleTypeId;

  static const _lastStep = 2;

  DateTime? _lastBackPress;
  Map<String, String> _serverErrors = {};

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const List<String> _stepTitles = [
    'Personal Profile',
    'Secure Your Account',
    'Your Vehicle',
  ];

  static const List<String> _stepSubtitles = [
    'Enter your name, phone, email and operating city',
    'Create a strong password to protect your account',
    'Confirm your vehicle type and enter its license plate',
  ];

  /// Placeholder list of major Ghanaian cities for the operating-city
  /// picker. Swap for a live/searchable source once one exists.
  static const List<String> _ghanaCities = [
    'Accra',
    'Kumasi',
    'Tamale',
    'Sekondi-Takoradi',
    'Ashaiman',
    'Sunyani',
    'Cape Coast',
    'Obuasi',
    'Teshie',
    'Tema',
    'Madina',
    'Koforidua',
    'Wa',
    'Ho',
    'Techiman',
  ];

  @override
  void initState() {
    super.initState();
    // Before the PageController exists: a reopen after a register failure
    // (or a back-out from terms) picks the page the wizard starts on.
    _restorePrefill();
    _pageController = PageController(initialPage: _currentStep);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

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
    ]) {
      c.addListener(_rebuild);
    }

    Future.microtask(_loadVehicleTypes);
  }

  /// Fetches the selectable vehicle types, then re-selects the rider's
  /// earlier choice (after a register failure) or — when only one type is
  /// on offer — picks it for them.
  Future<void> _loadVehicleTypes() async {
    await ref.read(vehicleCatalogProvider.notifier).loadTypes();
    if (!mounted || _selectedVehicleType != null) return;

    final types = ref.read(vehicleCatalogProvider).types;
    VehicleTypeModel? pick;
    for (final t in types) {
      if (t.id == _pendingVehicleTypeId) pick = t;
    }
    if (pick == null && types.length == 1) pick = types.single;
    if (pick != null) setState(() => _selectedVehicleType = pick);
  }

  void _selectVehicleType(VehicleTypeModel type) {
    HapticFeedback.selectionClick();
    setState(() => _selectedVehicleType = type);
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

    // Resolved against the live catalogue once it loads — see
    // _loadVehicleTypes, which runs right after this.
    _pendingVehicleTypeId = int.tryParse('${p['vehicle_type_id'] ?? ''}');
    _plateCtrl.text = (p['plate_number'] as String?) ?? '';

    // Runs from initState, before the PageView is attached, so this sets
    // the starting page rather than calling _navigateToStep (whose
    // animateToPage throws on an unattached PageController).
    final errors = (p['field_errors'] as Map?)?.cast<String, String>();
    if (errors != null && errors.isNotEmpty) {
      _serverErrors = Map.of(errors);
      _currentStep = _stepForFieldErrors(errors.keys);
      // Not every field shows its server message inline (names, password,
      // unmapped keys), so the rider always gets the dialog.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showRegisterFailure(errors));
    } else if (p['resume_step'] == _lastStep) {
      // The rider backed out of the terms screen — return them to the last
      // step rather than the first page of the wizard.
      _currentStep = _lastStep;
    }
  }

  /// The earliest wizard page that owns one of the rejected `/register`
  /// fields, so the rider fixes them in order. Anything unmapped opens the
  /// first page; the dialog still names it.
  static int _stepForFieldErrors(Iterable<String> fields) {
    const stepOf = {
      'first_name': 0,
      'last_name': 0,
      'phone': 0,
      'email': 0,
      'city': 0,
      'password': 1,
      'password_confirmation': 1,
      'vehicle_type_id': 2,
      'vehicle_type': 2,
      'plate_number': 2,
    };
    final steps = fields.map((f) => stepOf[f]).whereType<int>();
    return steps.isEmpty ? 0 : steps.reduce(math.min);
  }

  void _showRegisterFailure(Map<String, String> errors) {
    if (!mounted) return;
    CustomDialog.showError(
      context: context,
      title: 'Registration Failed',
      subtitle: errors.values.toSet().join('\n'),
    );
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
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneDigitsCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  // ── Step Validation Getters ─────────────────────────────────────────────

  bool get _isStep0Valid {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return _firstNameCtrl.text.trim().length >= 2 &&
        _lastNameCtrl.text.trim().length >= 2 &&
        _phone.length >= 9 &&
        emailRegex.hasMatch(_emailCtrl.text.trim()) &&
        _cityCtrl.text.trim().isNotEmpty;
  }

  bool get _isStep1Valid {
    final strength = evaluatePasswordStrength(_password);
    return _password.length >= 8 &&
        strength != PasswordStrength.weak &&
        _confirmCtrl.text == _password;
  }

  bool get _isStep2Valid =>
      _selectedVehicleType != null &&
      (!_selectedVehicleType!.requiresPlate ||
          _plateCtrl.text.trim().isNotEmpty);

  bool get _canProceedCurrentStep => switch (_currentStep) {
        0 => _isStep0Valid,
        1 => _isStep1Valid,
        _ => _isStep2Valid,
      };

  GlobalKey<FormState> get _currentFormKey =>
      [_formKey0, _formKey1, _formKey2][_currentStep];

  void _navigateToStep(int step) {
    if (step < 0 || step > _lastStep) return;
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
    if (!_currentFormKey.currentState!.validate()) return;
    _navigateToStep(_currentStep + 1);
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _navigateToStep(_currentStep - 1);
    }
  }

  /// The wizard doesn't create the account — it hands off to the terms
  /// screen, which registers and records consent before OTP. A register
  /// failure there sends the rider back here via `field_errors` in `extra`,
  /// which [_restorePrefill] already knows how to place on the right step,
  /// so this screen needs no failure-handling of its own.
  void _proceedToTerms() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey2.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    final type = _selectedVehicleType!;

    // Exactly what `POST /register` takes (see RiderTermsConditionsScreen).
    final collected = {
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phone,
      'city': _cityCtrl.text.trim(),
      'password': _password,
      'vehicle_type_id': type.id.toString(),
      if (type.requiresPlate)
        'plate_number': _plateCtrl.text.trim().toUpperCase(),
    };

    context.go(AppRoutes.termsAndConditions, extra: collected);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(riderAuthProvider).isLoading;

    ref.listen<RiderAuthState>(riderAuthProvider, (_, next) {
      if (!mounted) return;
      if (next.errorMessage != null && next.fieldErrors.isEmpty) {
        CustomDialog.showError(
          context: context,
          title: 'Registration Failed',
          subtitle: next.errorMessage!,
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
            'Step ${_currentStep + 1} of ${_lastStep + 1}',
            style: const TextStyle(
              fontFamily: AppFonts.body,
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
                    steps: const ['Personal', 'Account', 'Vehicle'],
                    currentIndex: _currentStep,
                    onStepTapped: (step) => _navigateToStep(step),
                  ),
                ),

                SizedBox(height: h * 0.02),

                // ── Active Step Subheader ───────────────────────────────────
                // Wrapped in a full-width SizedBox because the parent Column
                // has no crossAxisAlignment override (defaults to .center),
                // which would otherwise shrink-wrap this block to its
                // widest line and center it as a unit instead of letting the
                // inner start-aligned Column read from the true left edge.
                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _stepTitles[_currentStep],
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: (w * 0.068).clamp(22.0, 30.0),
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: h * 0.005),
                        Text(
                          _stepSubtitles[_currentStep],
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: (w * 0.035).clamp(12.0, 15.0),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: h * 0.02),

                // ── PageView Step Content ───────────────────────────────────
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) =>
                        setState(() => _currentStep = page),
                    children: [
                      _buildStep0Personal(hPad, w, h),
                      _buildStep1Account(hPad, w, h),
                      SignupVehicleStep(
                        formKey: _formKey2,
                        selectedType: _selectedVehicleType,
                        onTypeChanged: _selectVehicleType,
                        plateController: _plateCtrl,
                        serverError: _takeServerError,
                        onFieldEdited: _clearServerError,
                        onRetry: _loadVehicleTypes,
                        horizontalPadding: hPad,
                        screenHeight: h,
                      ),
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

  // ── Step 0: Personal Info + Email + Operating City ─────────────────────────

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
                fontFamily: AppFonts.body,
                fontSize: (w * 0.033).clamp(11.0, 14.0),
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.1,
              ),
            ),
            SizedBox(height: h * 0.008),
            AppPhoneField(
              digitController: _phoneDigitsCtrl,
              initialDigits:
                  _phoneDigitsCtrl.text.isEmpty ? null : _phoneDigitsCtrl.text,
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
            SizedBox(height: h * 0.02),
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
            AppSelectField<String>(
              label: 'Operating City',
              hint: 'Select your operating city',
              sheetTitle: 'Select Operating City',
              prefixIcon: HugeIcons.strokeRoundedCity03,
              value:
                  _ghanaCities.contains(_cityCtrl.text) ? _cityCtrl.text : null,
              options: _ghanaCities,
              labelBuilder: (city) => city,
              onChanged: (city) {
                _clearServerError('city');
                setState(() => _cityCtrl.text = city ?? '');
              },
              validator: (v) {
                final serverError = _takeServerError('city');
                if (serverError != null) return serverError;
                if (v == null || v.trim().isEmpty) {
                  return 'Select the city you will operate in';
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

  // ── Step 1: Security (Password) ─────────────────────────────────────────────

  Widget _buildStep1Account(double hPad, double w, double h) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: h * 0.01),
            AppPasswordField(
              label: 'Password',
              hint: 'Create a strong password',
              controller: _passwordCtrl,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter a password';
                if (v.length < 8)
                  return 'Password must be at least 8 characters';
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

  // ── Bottom Navigation Controls ─────────────────────────────────────────────

  Widget _buildBottomControls(double hPad, double w, double h, bool isLoading) {
    final isLastStep = _currentStep == _lastStep;
    final canProceed = _canProceedCurrentStep;
    // The last step only navigates to the terms screen — no network call
    // happens here, so it never shows a loading state.
    final busy = isLastStep ? false : isLoading;

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
                    onPressed: busy ? null : _previousStep,
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
                        fontFamily: AppFonts.body,
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
                  label: isLastStep ? 'Review & Accept Terms' : 'Continue',
                  isLoading: false,
                  onPressed: (!canProceed || busy)
                      ? null
                      : (isLastStep ? _proceedToTerms : _nextStep),
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
                    fontFamily: AppFonts.body,
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go(AppRoutes.login),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
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
