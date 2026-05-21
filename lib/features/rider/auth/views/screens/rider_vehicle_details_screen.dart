import 'dart:math' show sin, pi;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:delivery_boy/features/rider/auth/views/screens/rider_vehicle_info_screen.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_text_field.dart';
import 'package:hugeicons/hugeicons.dart';

class RiderVehicleDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> credentials;

  const RiderVehicleDetailsScreen({super.key, required this.credentials});

  @override
  ConsumerState<RiderVehicleDetailsScreen> createState() =>
      _RiderVehicleDetailsScreenState();
}

class _RiderVehicleDetailsScreenState
    extends ConsumerState<RiderVehicleDetailsScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _regNumCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();

  late AnimationController _entranceCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _formCtrl;

  late Animation<double> _entranceFade;
  late Animation<Offset> _entranceSlide;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;

  VehicleType get _vehicleType {
    final raw = widget.credentials['vehicleType'] as String? ?? '';
    return VehicleType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => VehicleType.motorcycle,
    );
  }

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _formCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _entranceFade =
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut),
    );
    _formFade = CurvedAnimation(parent: _formCtrl, curve: Curves.easeOutCubic);
    _formSlide =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _formCtrl, curve: Curves.easeOutCubic),
    );

    _entranceCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _formCtrl.forward();
    });

    for (final c in [_regNumCtrl, _yearCtrl, _makeCtrl, _modelCtrl, _colorCtrl]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _floatCtrl.dispose();
    _formCtrl.dispose();
    for (final c in [_regNumCtrl, _yearCtrl, _makeCtrl, _modelCtrl, _colorCtrl]) {
      c.removeListener(_onChanged);
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _canSubmit {
    if (_yearCtrl.text.trim().isEmpty) return false;
    if (_makeCtrl.text.trim().isEmpty) return false;
    if (_modelCtrl.text.trim().isEmpty) return false;
    if (_colorCtrl.text.trim().isEmpty) return false;
    if (_vehicleType.requiresPlate && _regNumCtrl.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    ref.read(pendingVehicleProvider.notifier).state = PendingVehicleInfo(
      type: _vehicleType.name,
      regNumber: _regNumCtrl.text.trim(),
      year: _yearCtrl.text.trim(),
      make: _makeCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      color: _colorCtrl.text.trim(),
    );
    context.go(AppRoutes.otp, extra: widget.credentials);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final h = mq.size.height;
    final hPad = (w * 0.06).clamp(20.0, 40.0);
    final currentYear = DateTime.now().year;

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
          onPressed: () => context.go(
            AppRoutes.vehicleInfo,
            extra: widget.credentials,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: FadeTransition(
          opacity: _entranceFade,
          child: SlideTransition(
            position: _entranceSlide,
            child: Form(
              key: _formKey,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        SizedBox(height: h * 0.01),

                        // ── Stepper ────────────────────────────────────
                        RegistrationStepper(
                          steps: const ['Account', 'Vehicle', 'Details', 'Verify'],
                          currentIndex: 2,
                        ),

                        SizedBox(height: h * 0.036),

                        // ── Animated Vehicle Icon ──────────────────────
                        _FloatingVehicleIcon(
                          controller: _floatCtrl,
                          vehicleType: _vehicleType,
                        ),

                        SizedBox(height: h * 0.028),

                        // ── Heading ────────────────────────────────────
                        Text(
                          'Vehicle Details',
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
                          'Tell us more about your ${_vehicleType.label.toLowerCase()}',
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: (w * 0.036).clamp(12.0, 16.0),
                            color: AppColors.textSecondary,
                          ),
                        ),

                        SizedBox(height: h * 0.032),

                        // ── Form ───────────────────────────────────────
                        FadeTransition(
                          opacity: _formFade,
                          child: SlideTransition(
                            position: _formSlide,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // License plate
                                AppTextField(
                                  label: _vehicleType.requiresPlate
                                      ? 'License Plate Number'
                                      : 'Registration Number (if any)',
                                  hint: _vehicleType.requiresPlate
                                      ? 'e.g. GR-1234-22'
                                      : 'Leave blank if none',
                                  prefixIcon: HugeIcons.strokeRoundedIdentityCard,
                                  controller: _regNumCtrl,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  validator: (v) {
                                    if (_vehicleType.requiresPlate &&
                                        (v == null || v.trim().isEmpty)) {
                                      return 'Please enter the license plate number';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: h * 0.018),

                                // Year + Make
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: AppTextField(
                                        label: 'Year',
                                        hint: 'e.g. 2020',
                                        prefixIcon:
                                            HugeIcons.strokeRoundedCalendar01,
                                        controller: _yearCtrl,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(4),
                                        ],
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return 'Required';
                                          }
                                          final year = int.tryParse(v.trim());
                                          if (year == null ||
                                              year < 1980 ||
                                              year > currentYear) {
                                            return '1980–$currentYear';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(width: w * 0.028),
                                    Expanded(
                                      child: AppTextField(
                                        label: 'Make',
                                        hint: 'e.g. Honda',
                                        prefixIcon:
                                            HugeIcons.strokeRoundedCar01,
                                        controller: _makeCtrl,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        validator: (v) =>
                                            (v == null || v.trim().isEmpty)
                                                ? 'Required'
                                                : null,
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: h * 0.018),

                                // Model
                                AppTextField(
                                  label: 'Model',
                                  hint: 'e.g. CB150R',
                                  prefixIcon: HugeIcons.strokeRoundedMotorbike01,
                                  controller: _modelCtrl,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Please enter the vehicle model'
                                          : null,
                                ),

                                SizedBox(height: h * 0.018),

                                // Color
                                AppTextField(
                                  label: 'Color',
                                  hint: 'e.g. Red',
                                  prefixIcon: HugeIcons.strokeRoundedPaintBoard,
                                  controller: _colorCtrl,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Please enter the vehicle color'
                                          : null,
                                ),

                                SizedBox(height: h * 0.012),

                                _ColorQuickPick(
                                  controller: _colorCtrl,
                                  onPicked: () => setState(() {}),
                                ),

                                if (_vehicleType.isElectric) ...[
                                  SizedBox(height: h * 0.02),
                                  _ElectricNote(w: w),
                                ],
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: h * 0.036),

                        AppGradientButton(
                          label: 'Continue',
                          onPressed: _canSubmit ? _submit : null,
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
      ),
    );
  }
}

// ── Floating Vehicle Icon ─────────────────────────────────────────────────────

class _FloatingVehicleIcon extends StatelessWidget {
  final AnimationController controller;
  final VehicleType vehicleType;

  const _FloatingVehicleIcon({
    required this.controller,
    required this.vehicleType,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final containerSize = (w * 0.32).clamp(110.0, 145.0);
    final iconSize = containerSize * 0.46;

    return Center(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          // Smooth sine-wave float: -9px to +9px
          final floatOffset = sin(controller.value * 2 * pi) * 9.0;
          // Shadow stretches as icon rises
          final shadowBlur = 16.0 + (1 - (floatOffset + 9) / 18) * 10;
          final shadowOpacity = 0.10 + (1 - (floatOffset + 9) / 18) * 0.08;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                offset: Offset(0, floatOffset),
                child: child,
              ),
              const SizedBox(height: 6),
              // Floating shadow on the ground
              AnimatedContainer(
                duration: Duration.zero,
                width: containerSize * 0.55,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.primary.withValues(alpha: shadowOpacity),
                      blurRadius: shadowBlur,
                      spreadRadius: 2,
                    ),
                  ],
                  color: Colors.transparent,
                ),
              ),
            ],
          );
        },
        child: Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.4,
              colors: [
                AppColors.primary.withValues(alpha: 0.14),
                AppColors.primary.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              vehicleType.icon,
              size: iconSize,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Color Quick Pick ──────────────────────────────────────────────────────────

class _ColorQuickPick extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onPicked;

  const _ColorQuickPick({required this.controller, required this.onPicked});

  @override
  State<_ColorQuickPick> createState() => _ColorQuickPickState();
}

class _ColorQuickPickState extends State<_ColorQuickPick> {
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
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final current = widget.controller.text.trim().toLowerCase();

    return Wrap(
      spacing: w * 0.022,
      runSpacing: w * 0.02,
      children: _colors.map((entry) {
        final name = entry.$1;
        final color = entry.$2;
        final isSelected = current == name.toLowerCase();
        final isLight = name == 'White' || name == 'Yellow';

        return GestureDetector(
          onTap: () {
            widget.controller.text = name;
            widget.onPicked();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.034,
              vertical: w * 0.016,
            ),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(w * 0.08),
              border: Border.all(
                color: color,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              name,
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: (w * 0.032).clamp(10.0, 13.0),
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

// ── Electric Note ─────────────────────────────────────────────────────────────

class _ElectricNote extends StatelessWidget {
  final double w;

  const _ElectricNote({required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.04,
        vertical: w * 0.035,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0EA5E9).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(w * 0.028),
        border: Border.all(
          color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(HugeIcons.strokeRoundedFlash, color: Color(0xFF0EA5E9), size: 20),
          SizedBox(width: w * 0.02),
          const Expanded(
            child: Text(
              'Electric vehicle — ensure your battery is adequately charged before each delivery.',
              style: TextStyle(
                fontFamily: 'Mukta',
                color: Color(0xFF0369A1),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
