import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_text_field.dart';

// ── Vehicle Type Enum ─────────────────────────────────────────────────────────

enum VehicleType {
  tricycle,
  bicycle,
  electricBicycle,
  motorcycle,
  electricMotorcycle;

  String get primaryLabel {
    switch (this) {
      case VehicleType.tricycle:
        return 'Tricycle';
      case VehicleType.bicycle:
        return 'Bicycle';
      case VehicleType.electricBicycle:
        return 'Electric';
      case VehicleType.motorcycle:
        return 'Motorcycle';
      case VehicleType.electricMotorcycle:
        return 'Electric';
    }
  }

  String? get subLabel {
    switch (this) {
      case VehicleType.tricycle:
        return 'Aboboyaa';
      case VehicleType.electricBicycle:
        return 'Bicycle';
      case VehicleType.electricMotorcycle:
        return 'Motorcycle';
      default:
        return null;
    }
  }

  String get emoji {
    switch (this) {
      case VehicleType.tricycle:
        return '🛺';
      case VehicleType.bicycle:
        return '🚲';
      case VehicleType.electricBicycle:
        return '⚡🚲';
      case VehicleType.motorcycle:
        return '🏍️';
      case VehicleType.electricMotorcycle:
        return '⚡🏍️';
    }
  }

  bool get isElectric =>
      this == VehicleType.electricBicycle ||
      this == VehicleType.electricMotorcycle;

  bool get requiresPlate =>
      this != VehicleType.bicycle && this != VehicleType.electricBicycle;
}

// ── Main Screen ───────────────────────────────────────────────────────────────

class RiderVehicleInfoScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> credentials;

  const RiderVehicleInfoScreen({super.key, required this.credentials});

  @override
  ConsumerState<RiderVehicleInfoScreen> createState() =>
      _RiderVehicleInfoScreenState();
}

class _RiderVehicleInfoScreenState extends ConsumerState<RiderVehicleInfoScreen>
    with TickerProviderStateMixin {
  VehicleType? _selectedType;
  final _formKey = GlobalKey<FormState>();

  final _regNumCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();

  late AnimationController _entranceCtrl;
  late AnimationController _formCtrl;

  late Animation<double> _entranceFade;
  late Animation<Offset> _entranceSlide;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _formCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _entranceFade =
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut),
    );

    _formFade = CurvedAnimation(parent: _formCtrl, curve: Curves.easeOutCubic);
    _formSlide =
        Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero).animate(
      CurvedAnimation(parent: _formCtrl, curve: Curves.easeOutCubic),
    );

    _entranceCtrl.forward();

    _regNumCtrl.addListener(_onFieldChanged);
    _yearCtrl.addListener(_onFieldChanged);
    _makeCtrl.addListener(_onFieldChanged);
    _modelCtrl.addListener(_onFieldChanged);
    _colorCtrl.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _formCtrl.dispose();
    _regNumCtrl.dispose();
    _yearCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  void _selectType(VehicleType type) {
    if (_selectedType == type) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedType = type);
    _formCtrl.forward(from: 0);
  }

  bool get _canSubmit {
    if (_selectedType == null) return false;
    if (_yearCtrl.text.trim().isEmpty) return false;
    if (_makeCtrl.text.trim().isEmpty) return false;
    if (_modelCtrl.text.trim().isEmpty) return false;
    if (_colorCtrl.text.trim().isEmpty) return false;
    if (_selectedType!.requiresPlate && _regNumCtrl.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    ref.read(pendingVehicleProvider.notifier).state = PendingVehicleInfo(
      type: _selectedType!.name,
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

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => context.go(AppRoutes.signup),
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
                        _RegistrationStepper(
                          steps: const ['Account', 'Vehicle', 'Verify'],
                          currentIndex: 1,
                        ),
                        SizedBox(height: h * 0.028),
                        Text(
                          'Your Vehicle',
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: (w * 0.072).clamp(24.0, 34.0),
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.8,
                          ),
                        ),
                        SizedBox(height: h * 0.006),
                        Text(
                          'Tell us what you ride to get started',
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: (w * 0.036).clamp(12.0, 16.0),
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: h * 0.032),
                        Text(
                          'Choose your ride',
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: (w * 0.038).clamp(13.0, 16.0),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: h * 0.016),
                        LayoutBuilder(
                          builder: (context, constraints) => _VehicleTypeGrid(
                            availableWidth: constraints.maxWidth,
                            screenHeight: h,
                            selectedType: _selectedType,
                            onSelect: _selectType,
                          ),
                        ),
                        if (_selectedType != null) ...[
                          SizedBox(height: h * 0.032),
                          FadeTransition(
                            opacity: _formFade,
                            child: SlideTransition(
                              position: _formSlide,
                              child: _buildDetailsForm(w, h),
                            ),
                          ),
                        ],
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

  Widget _buildDetailsForm(double w, double h) {
    final currentYear = DateTime.now().year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Details',
          style: TextStyle(
            fontFamily: 'Mukta',
            fontSize: (w * 0.038).clamp(13.0, 16.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: h * 0.016),
        AppTextField(
          label: _selectedType!.requiresPlate
              ? 'License Plate Number'
              : 'Registration Number (optional)',
          hint: _selectedType!.requiresPlate
              ? 'e.g. GR-1234-22'
              : 'Leave blank if none',
          prefixIcon: Icons.badge_outlined,
          controller: _regNumCtrl,
          textCapitalization: TextCapitalization.characters,
          validator: (v) {
            if (_selectedType!.requiresPlate &&
                (v == null || v.trim().isEmpty)) {
              return 'Please enter the license plate number';
            }
            return null;
          },
        ),
        SizedBox(height: h * 0.018),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Year',
                hint: 'e.g. 2020',
                prefixIcon: Icons.calendar_today_outlined,
                controller: _yearCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Required';
                  }
                  final year = int.tryParse(v.trim());
                  if (year == null || year < 1980 || year > currentYear) {
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
                prefixIcon: Icons.directions_car_outlined,
                controller: _makeCtrl,
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: h * 0.018),
        AppTextField(
          label: 'Model',
          hint: 'e.g. CB150R',
          prefixIcon: Icons.two_wheeler_outlined,
          controller: _modelCtrl,
          textCapitalization: TextCapitalization.words,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Please enter vehicle model';
            return null;
          },
        ),
        SizedBox(height: h * 0.018),
        AppTextField(
          label: 'Color',
          hint: 'e.g. Red',
          prefixIcon: Icons.palette_outlined,
          controller: _colorCtrl,
          textCapitalization: TextCapitalization.words,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Please enter vehicle color';
            return null;
          },
        ),
        SizedBox(height: h * 0.012),
        _ColorQuickPick(
          controller: _colorCtrl,
          onPicked: () => setState(() {}),
        ),
        if (_selectedType!.isElectric) ...[
          SizedBox(height: h * 0.02),
          _ElectricNote(w: w),
        ],
      ],
    );
  }
}

// ── Registration Stepper ──────────────────────────────────────────────────────

class _RegistrationStepper extends StatelessWidget {
  final List<String> steps;
  final int currentIndex;

  const _RegistrationStepper({
    required this.steps,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final circleSize = (w * 0.072).clamp(28.0, 40.0);

    return Row(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= currentIndex
                      ? AppColors.primary
                      : Colors.white,
                  border: Border.all(
                    color: i <= currentIndex
                        ? AppColors.primary
                        : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: i < currentIndex
                      ? Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: (w * 0.038).clamp(14.0, 20.0),
                        )
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: (w * 0.032).clamp(11.0, 15.0),
                            fontWeight: FontWeight.w700,
                            color: i == currentIndex
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[i],
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: (w * 0.028).clamp(9.0, 12.0),
                  fontWeight: i == currentIndex
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: i == currentIndex
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (i < steps.length - 1)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: (w * 0.005).clamp(2.0, 4.0),
                  color: i < currentIndex ? AppColors.primary : AppColors.border,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

// ── Vehicle Type Grid ─────────────────────────────────────────────────────────

class _VehicleTypeGrid extends StatelessWidget {
  final double availableWidth;
  final double screenHeight;
  final VehicleType? selectedType;
  final void Function(VehicleType) onSelect;

  const _VehicleTypeGrid({
    required this.availableWidth,
    required this.screenHeight,
    required this.selectedType,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final gap = availableWidth * 0.034;
    final cardW = (availableWidth - gap) / 2;
    final cardH = screenHeight * 0.135;

    return Column(
      children: [
        Row(
          children: [
            _VehicleCard(
              type: VehicleType.tricycle,
              isSelected: selectedType == VehicleType.tricycle,
              onTap: () => onSelect(VehicleType.tricycle),
              width: cardW,
              height: cardH,
            ),
            SizedBox(width: gap),
            _VehicleCard(
              type: VehicleType.bicycle,
              isSelected: selectedType == VehicleType.bicycle,
              onTap: () => onSelect(VehicleType.bicycle),
              width: cardW,
              height: cardH,
            ),
          ],
        ),
        SizedBox(height: gap),
        Row(
          children: [
            _VehicleCard(
              type: VehicleType.electricBicycle,
              isSelected: selectedType == VehicleType.electricBicycle,
              onTap: () => onSelect(VehicleType.electricBicycle),
              width: cardW,
              height: cardH,
            ),
            SizedBox(width: gap),
            _VehicleCard(
              type: VehicleType.motorcycle,
              isSelected: selectedType == VehicleType.motorcycle,
              onTap: () => onSelect(VehicleType.motorcycle),
              width: cardW,
              height: cardH,
            ),
          ],
        ),
        SizedBox(height: gap),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: cardW,
              child: _VehicleCard(
                type: VehicleType.electricMotorcycle,
                isSelected: selectedType == VehicleType.electricMotorcycle,
                onTap: () => onSelect(VehicleType.electricMotorcycle),
                width: cardW,
                height: cardH,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Vehicle Card ──────────────────────────────────────────────────────────────

class _VehicleCard extends StatefulWidget {
  final VehicleType type;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;
  final double height;

  const _VehicleCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
    required this.width,
    required this.height,
  });

  @override
  State<_VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<_VehicleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.94).animate(_pressCtrl);
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height;
    final w = widget.width;
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.07)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(h * 0.15),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: h * 0.14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(left: w * 0.08),
                child: Text(
                  widget.type.emoji,
                  style: TextStyle(fontSize: h * 0.3),
                ),
              ),
              SizedBox(width: w * 0.06),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.type.primaryLabel,
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: (h * 0.155).clamp(12.0, 17.0),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (widget.type.subLabel != null)
                    Text(
                      widget.type.subLabel!,
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: (h * 0.12).clamp(10.0, 13.0),
                        fontWeight: FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.8)
                            : AppColors.textHint,
                      ),
                    ),
                ],
              ),
            ],
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

  const _ColorQuickPick({
    required this.controller,
    required this.onPicked,
  });

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
    final currentValue = widget.controller.text.trim().toLowerCase();

    return Wrap(
      spacing: w * 0.022,
      runSpacing: w * 0.02,
      children: _colors.map((entry) {
        final name = entry.$1;
        final color = entry.$2;
        final isSelected = currentValue == name.toLowerCase();
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
              color: isSelected
                  ? color
                  : color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(w * 0.08),
              border: Border.all(
                color: isSelected ? color : color,
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
          const Icon(
            Icons.bolt_rounded,
            color: Color(0xFF0EA5E9),
            size: 20,
          ),
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
