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
import 'package:delivery_boy/features/rider/auth/views/widgets/registration_stepper.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_password_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_phone_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_select_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_text_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/password_strength_validator.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_make_model.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_model_model.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_type_model.dart';
import 'package:delivery_boy/features/rider/vehicles/viewmodel/vehicle_catalog_viewmodel.dart';

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

  // Step 2: Vehicle Type — fetched from GET /vehicle-types (see
  // VehicleCatalogNotifier), not a hardcoded enum.
  VehicleTypeModel? _selectedVehicleType;

  // Step 3: Vehicle Specs — Make/Model come from the cascading
  // GET /vehicle-makes / GET /vehicle-models endpoints.
  final _plateCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  VehicleMakeModel? _selectedMake;
  VehicleModelModel? _selectedModel;
  final _colorCtrl = TextEditingController();

  /// Ids to re-select once the catalogue reloads after a register failure
  /// sends the rider back here with [widget.prefill].
  int? _pendingVehicleTypeId;
  int? _pendingMakeId;
  int? _pendingModelId;

  DateTime? _lastBackPress;
  Map<String, String> _serverErrors = {};

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const List<String> _stepTitles = [
    'Personal Profile',
    'Secure Your Account',
    'Select Vehicle',
    'Vehicle Specs',
  ];

  static const List<String> _stepSubtitles = [
    'Enter your name, phone, email and operating city',
    'Create a strong password to protect your account',
    'Choose the vehicle type for your deliveries',
    'Provide your license plate and vehicle details',
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
    _pageController = PageController(initialPage: 0);

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
      _yearCtrl,
      _colorCtrl,
    ]) {
      c.addListener(_rebuild);
    }

    _restorePrefill();
    Future.microtask(_loadVehicleCatalog);
  }

  /// Fetches vehicle types up front, then — if this screen was reopened
  /// after a register failure — walks the cascade to re-select whatever the
  /// rider had already chosen (see [_restorePrefill]).
  Future<void> _loadVehicleCatalog() async {
    final notifier = ref.read(vehicleCatalogProvider.notifier);
    await notifier.loadTypes();
    if (!mounted) return;

    final typeId = _pendingVehicleTypeId;
    if (typeId == null) return;
    final type = _findById(
      ref.read(vehicleCatalogProvider).types,
      (t) => t.id,
      typeId,
    );
    if (type == null) return;
    setState(() => _selectedVehicleType = type);

    await notifier.loadMakes(type.id);
    if (!mounted) return;

    final makeId = _pendingMakeId;
    if (makeId == null) return;
    final make = _findById(
      ref.read(vehicleCatalogProvider).makes,
      (m) => m.id,
      makeId,
    );
    if (make == null) return;
    setState(() => _selectedMake = make);

    await notifier.loadModels(make.id);
    if (!mounted) return;

    final modelId = _pendingModelId;
    if (modelId == null) return;
    final model = _findById(
      ref.read(vehicleCatalogProvider).models,
      (m) => m.id,
      modelId,
    );
    if (model != null) setState(() => _selectedModel = model);
  }

  T? _findById<T>(List<T> items, int Function(T) idOf, int id) {
    for (final item in items) {
      if (idOf(item) == id) return item;
    }
    return null;
  }

  void _selectVehicleType(VehicleTypeModel type) {
    if (_selectedVehicleType?.id == type.id) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedVehicleType = type;
      // Make/Model depend on the type — clear them so a stale selection
      // from a different type can't linger as "selected".
      _selectedMake = null;
      _selectedModel = null;
    });
    ref.read(vehicleCatalogProvider.notifier).loadMakes(type.id);
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
    // _loadVehicleCatalog, which runs right after this.
    _pendingVehicleTypeId = int.tryParse('${p['vehicle_type_id'] ?? ''}');
    _pendingMakeId = int.tryParse('${p['vehicle_make_id'] ?? ''}');
    _pendingModelId = int.tryParse('${p['vehicle_model_id'] ?? ''}');

    _plateCtrl.text = (p['plate_number'] as String?) ?? '';
    if (p['vehicle_year'] != null)
      _yearCtrl.text = p['vehicle_year'].toString();
    _colorCtrl.text = (p['vehicle_colour'] as String?) ?? '';

    final errors = (p['field_errors'] as Map?)?.cast<String, String>();
    if (errors != null && errors.isNotEmpty) {
      _serverErrors = Map.of(errors);
      if (errors.containsKey('email') || errors.containsKey('city')) {
        _navigateToStep(0);
      } else if (errors.containsKey('password')) {
        _navigateToStep(1);
      } else if (errors.containsKey('plate_number') ||
          errors.containsKey('vehicle_type')) {
        _navigateToStep(3);
      }
    } else if (p['resume_step'] == 3) {
      // The rider backed out of the terms screen — return them to Vehicle
      // Specs rather than the first page of the wizard.
      _navigateToStep(3);
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
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneDigitsCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _plateCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
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

  bool get _isStep2Valid => _selectedVehicleType != null;

  /// Last 20 registration years, newest first. Not part of the vehicle
  /// catalogue API (which has no year endpoint), so this stays a simple
  /// generated range rather than a network call.
  List<int> get _availableYears {
    final current = DateTime.now().year;
    return List.generate(20, (i) => current - i);
  }

  bool get _isStep3Valid {
    final yearVal = int.tryParse(_yearCtrl.text.trim());
    final validYear = yearVal != null && _availableYears.contains(yearVal);

    return _plateCtrl.text.trim().isNotEmpty &&
        _selectedMake != null &&
        _selectedModel != null &&
        validYear;
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

  /// Vehicle Specs is no longer where the account is created — it hands off
  /// to the terms screen, which registers and records consent before OTP.
  /// A register failure there sends the rider back here via `field_errors`
  /// in `extra`, which [_restorePrefill] already knows how to place on the
  /// right step, so this screen needs no failure-handling of its own.
  void _proceedToTerms() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey3.currentState!.validate()) return;

    HapticFeedback.mediumImpact();

    final type = _selectedVehicleType!;
    final make = _selectedMake!;
    final model = _selectedModel!;

    final collected = {
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phone,
      'city': _cityCtrl.text.trim(),
      'password': _password,
      // `vehicle_type_id` is what `POST /register` actually needs (see
      // RiderTermsConditionsScreen); `vehicle_type` (the slug) is kept for
      // the later `PUT /rider/me` shape.
      'vehicle_type_id': type.id.toString(),
      'vehicle_type': type.slug,
      'plate_number': _plateCtrl.text.trim().toUpperCase(),
      'vehicle_year': int.tryParse(_yearCtrl.text.trim()),
      'vehicle_make_id': make.id,
      'vehicle_make': make.name,
      'vehicle_model_id': model.id,
      'vehicle_model': model.name,
      //'vehicle_colour': _colorCtrl.text.trim(),
    };

    context.go(AppRoutes.termsAndConditions, extra: collected);
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
                            fontFamily: 'Mukta',
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
                            fontFamily: 'Mukta',
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

  // ── Step 2: Vehicle Type Selection ─────────────────────────────────────────

  Widget _buildStep2VehicleType(double hPad, double w, double h) {
    final catalog = ref.watch(vehicleCatalogProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: h * 0.01),
          if (catalog.isLoadingTypes)
            Padding(
              padding: EdgeInsets.symmetric(vertical: h * 0.06),
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (catalog.typesError != null)
            _CatalogRetry(
              message: catalog.typesError!,
              onRetry: () =>
                  ref.read(vehicleCatalogProvider.notifier).loadTypes(),
            )
          else if (catalog.types.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: h * 0.06),
              child: Text(
                'No vehicle types are available right now.',
                style: TextStyle(
                  fontFamily: 'Mukta',
                  color: AppColors.textSecondary,
                  fontSize: (w * 0.036).clamp(13.0, 15.0),
                ),
              ),
            )
          else
            ...catalog.types.map((type) {
              final isSelected = _selectedVehicleType?.id == type.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  onTap: () => _selectVehicleType(type),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: EdgeInsets.all(w * 0.04),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.04)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2.0 : 1.0,
                      ),
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
                            HugeIcons.strokeRoundedMotorbike01,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type.name,
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
                                (type.description ?? '').isNotEmpty
                                    ? type.description!
                                    : 'Max parcel size: ${type.maxParcelSizeLabel}',
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
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
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
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Form(
        key: _formKey3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: h * 0.005),

            ///["Not required for now "]
            // Vehicle Icon Header
            // Center(
            //   child: Container(
            //     width: 72,
            //     height: 72,
            //     decoration: BoxDecoration(
            //       shape: BoxShape.circle,
            //       color: AppColors.primary.withValues(alpha: 0.1),
            //       border: Border.all(
            //         color: AppColors.primary.withValues(alpha: 0.2),
            //         width: 1.5,
            //       ),
            //     ),
            //     child: Icon(
            //       _selectedVehicleType.icon,
            //       size: 34,
            //       color: AppColors.primary,
            //     ),
            //   ),
            // ),

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

            // Make/Model are constrained to the live vehicle catalogue
            // (GET /vehicle-makes, /vehicle-models) instead of free text, so
            // a rider can't submit a model that doesn't exist for their
            // vehicle type.
            Builder(builder: (context) {
              final catalog = ref.watch(vehicleCatalogProvider);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSelectField<VehicleMakeModel>(
                    label: 'Make',
                    hint: catalog.isLoadingMakes
                        ? 'Loading manufacturers…'
                        : 'Select the manufacturer',
                    sheetTitle: 'Select Make',
                    prefixIcon: HugeIcons.strokeRoundedCar01,
                    enabled:
                        !catalog.isLoadingMakes && catalog.makes.isNotEmpty,
                    value: _selectedMake,
                    options: catalog.makes,
                    labelBuilder: (make) => make.name,
                    onChanged: (make) {
                      if (make == null) return;
                      setState(() {
                        _selectedMake = make;
                        // Model depends on make — clear it so a stale model
                        // from a different manufacturer can't linger as
                        // "selected".
                        _selectedModel = null;
                      });
                      ref
                          .read(vehicleCatalogProvider.notifier)
                          .loadModels(make.id);
                    },
                    validator: (v) =>
                        v == null ? 'Select the manufacturer' : null,
                  ),
                  if (catalog.makesError != null && _selectedVehicleType != null)
                    _InlineRetry(
                      message: catalog.makesError!,
                      onRetry: () => ref
                          .read(vehicleCatalogProvider.notifier)
                          .loadMakes(_selectedVehicleType!.id),
                    ),
                ],
              );
            }),

            SizedBox(height: h * 0.018),

            Builder(builder: (context) {
              final catalog = ref.watch(vehicleCatalogProvider);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSelectField<VehicleModelModel>(
                    // Forces a fresh FormField (and therefore an unselected
                    // value) whenever the make changes, since the options
                    // depend on it.
                    key: ValueKey('model-${_selectedMake?.id}'),
                    label: 'Model',
                    hint: _selectedMake == null
                        ? 'Select a make first'
                        : catalog.isLoadingModels
                            ? 'Loading models…'
                            : 'Select the model',
                    sheetTitle: 'Select Model',
                    prefixIcon: HugeIcons.strokeRoundedMotorbike01,
                    enabled: _selectedMake != null &&
                        !catalog.isLoadingModels &&
                        catalog.models.isNotEmpty,
                    value: _selectedModel,
                    options: catalog.models,
                    labelBuilder: (model) => model.name,
                    onChanged: (model) =>
                        setState(() => _selectedModel = model),
                    validator: (v) => v == null ? 'Select the model' : null,
                  ),
                  if (catalog.modelsError != null && _selectedMake != null)
                    _InlineRetry(
                      message: catalog.modelsError!,
                      onRetry: () => ref
                          .read(vehicleCatalogProvider.notifier)
                          .loadModels(_selectedMake!.id),
                    ),
                ],
              );
            }),

            SizedBox(height: h * 0.018),

            AppSelectField<int>(
              label: 'Year',
              hint: 'Select the registration year',
              sheetTitle: 'Select Year',
              prefixIcon: HugeIcons.strokeRoundedCalendar01,
              value: int.tryParse(_yearCtrl.text),
              options: _availableYears,
              labelBuilder: (year) => year.toString(),
              onChanged: (year) =>
                  setState(() => _yearCtrl.text = year?.toString() ?? ''),
              validator: (v) =>
                  v == null ? 'Select the registration year' : null,
            ),

            SizedBox(height: h * 0.018),

            // AppTextField(
            //   label: 'Color',
            //   hint: 'e.g. Red',
            //   prefixIcon: HugeIcons.strokeRoundedPaintBoard,
            //   controller: _colorCtrl,
            //   textCapitalization: TextCapitalization.words,
            //   onChanged: (_) => setState(() {}),
            //   validator: (v) =>
            //       (v == null || v.trim().isEmpty) ? 'Please enter color' : null,
            // ),

            //  SizedBox(height: h * 0.012),

            // _ColorQuickPick(
            //   controller: _colorCtrl,
            //   onPicked: () => setState(() {}),
            // ),

            if (_selectedVehicleType?.isElectric ?? false) ...[
              SizedBox(height: h * 0.018),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(HugeIcons.strokeRoundedFlash,
                        color: AppColors.info, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Electric vehicle — ensure battery is charged before starting deliveries.',
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: 13,
                          color: AppColors.info,
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
    // Vehicle Specs only navigates to the terms screen now — no network
    // call happens here, so this step never shows a loading state.
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

// ── Catalogue Load-Error Retry ────────────────────────────────────────────────

/// Shown in place of a list (vehicle types) when its fetch failed — the
/// list/error/empty states share a consistent, simple look across the app.
class _CatalogRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CatalogRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Mukta',
              color: AppColors.error,
              fontSize: 13,
            ),
          ),
          SizedBox(height: w * 0.026),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Retry',
              style:
                  TextStyle(fontFamily: 'Mukta', fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inline Retry (Make/Model load failures) ─────────────────────────────────

/// A compact one-line error + retry, used under the Make/Model selects
/// where a full-page [_CatalogRetry] would be too heavy.
class _InlineRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.only(top: w * 0.015, left: w * 0.01),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Mukta',
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: w * 0.02),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontFamily: 'Mukta',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Color Quick Pick Helper ──────────────────────────────────────────────────
//["Not required for now "]
// class _ColorQuickPick extends StatelessWidget {
//   final TextEditingController controller;
//   final VoidCallback onPicked;

//   const _ColorQuickPick({required this.controller, required this.onPicked});

//   static const _colors = [
//     ('Black', Color(0xFF1A1A1A)),
//     ('White', Color(0xFFF0F0F0)),
//     ('Silver', Color(0xFFA8A8A8)),
//     ('Red', AppColors.primary),
//     ('Blue', Color(0xFF3182CE)),
//     ('Yellow', Color(0xFFF59E0B)),
//     ('Green', Color(0xFF38A169)),
//     ('Orange', Color(0xFFDD6B20)),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final current = controller.text.trim().toLowerCase();

//     return Wrap(
//       spacing: 8,
//       runSpacing: 8,
//       children: _colors.map((entry) {
//         final name = entry.$1;
//         final color = entry.$2;
//         final isSelected = current == name.toLowerCase();
//         final isLight = name == 'White' || name == 'Yellow';

//         return GestureDetector(
//           onTap: () {
//             controller.text = name;
//             onPicked();
//           },
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             decoration: BoxDecoration(
//               color: isSelected ? color : color.withValues(alpha: 0.14),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(
//                 color: color,
//                 width: isSelected ? 1.5 : 1.0,
//               ),
//             ),
//             child: Text(
//               name,
//               style: TextStyle(
//                 fontFamily: 'Mukta',
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 color: isSelected
//                     ? (isLight ? Colors.black87 : Colors.white)
//                     : AppColors.textSecondary,
//               ),
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }
// }
