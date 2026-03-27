import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';

// ── Vehicle Type Enum ─────────────────────────────────────────────────────────

enum VehicleType {
  tricycle,
  bicycle,
  electricBicycle,
  motorcycle,
  electricMotorcycle;

  String get label {
    switch (this) {
      case VehicleType.tricycle:
        return 'Tricycle (Aboboyaa)';
      case VehicleType.bicycle:
        return 'Bicycle';
      case VehicleType.electricBicycle:
        return 'Electric Bicycle';
      case VehicleType.motorcycle:
        return 'Motorcycle';
      case VehicleType.electricMotorcycle:
        return 'Electric Motorcycle';
    }
  }

  String get description {
    switch (this) {
      case VehicleType.tricycle:
        return 'Three-wheeled cargo vehicle, ideal for bulk deliveries';
      case VehicleType.bicycle:
        return 'Pedal-powered, perfect for short local routes';
      case VehicleType.electricBicycle:
        return 'Battery-assisted cycling for faster local deliveries';
      case VehicleType.motorcycle:
        return 'Fast and agile for city-wide deliveries';
      case VehicleType.electricMotorcycle:
        return 'Eco-friendly and low-noise for urban routes';
    }
  }

  IconData get icon {
    switch (this) {
      case VehicleType.tricycle:
        return Icons.airport_shuttle_outlined;
      case VehicleType.bicycle:
        return Icons.directions_bike_outlined;
      case VehicleType.electricBicycle:
        return Icons.electric_bike_outlined;
      case VehicleType.motorcycle:
        return Icons.two_wheeler_outlined;
      case VehicleType.electricMotorcycle:
        return Icons.electric_moped_outlined;
    }
  }

  bool get isElectric =>
      this == VehicleType.electricBicycle ||
      this == VehicleType.electricMotorcycle;

  bool get requiresPlate =>
      this != VehicleType.bicycle && this != VehicleType.electricBicycle;
}

// ── Main Screen ───────────────────────────────────────────────────────────────

class RiderVehicleInfoScreen extends StatefulWidget {
  final Map<String, dynamic> credentials;

  const RiderVehicleInfoScreen({super.key, required this.credentials});

  @override
  State<RiderVehicleInfoScreen> createState() => _RiderVehicleInfoScreenState();
}

class _RiderVehicleInfoScreenState extends State<RiderVehicleInfoScreen>
    with TickerProviderStateMixin {
  VehicleType? _selectedType;

  late AnimationController _entranceCtrl;
  late AnimationController _tilesCtrl;

  late Animation<double> _entranceFade;
  late Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _tilesCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _entranceFade =
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut),
    );

    _entranceCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _tilesCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _tilesCtrl.dispose();
    super.dispose();
  }

  void _selectType(VehicleType type) {
    if (_selectedType == type) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedType = type);
  }

  void _continue() {
    HapticFeedback.mediumImpact();
    context.go(AppRoutes.vehicleDetails, extra: {
      ...widget.credentials,
      'vehicleType': _selectedType!.name,
    });
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
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      SizedBox(height: h * 0.01),

                      // ── Stepper ──────────────────────────────────────
                      RegistrationStepper(
                        steps: const ['Account', 'Vehicle', 'Details', 'Verify'],
                        currentIndex: 1,
                      ),

                      SizedBox(height: h * 0.032),

                      // ── Heading ──────────────────────────────────────
                      Text(
                        'Your Vehicle',
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
                        'Select the vehicle you\'ll use for deliveries',
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: (w * 0.036).clamp(12.0, 16.0),
                          color: AppColors.textSecondary,
                        ),
                      ),

                      SizedBox(height: h * 0.032),

                      // ── Vehicle Tiles ─────────────────────────────────
                      ...VehicleType.values.indexed.map((entry) {
                        final index = entry.$1;
                        final type = entry.$2;
                        return _StaggeredItem(
                          parent: _tilesCtrl,
                          index: index,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: h * 0.014),
                            child: _VehicleTile(
                              type: type,
                              isSelected: _selectedType == type,
                              onTap: () => _selectType(type),
                            ),
                          ),
                        );
                      }),

                      SizedBox(height: h * 0.036),

                      AppGradientButton(
                        label: 'Continue',
                        onPressed: _selectedType != null ? _continue : null,
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
    );
  }
}

// ── Staggered Item ────────────────────────────────────────────────────────────

class _StaggeredItem extends StatelessWidget {
  final Animation<double> parent;
  final int index;
  final Widget child;

  const _StaggeredItem({
    required this.parent,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.14).clamp(0.0, 0.8);
    final end = (start + 0.55).clamp(0.0, 1.0);
    final interval = CurveTween(
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    final fade = parent.drive(
      Tween<double>(begin: 0.0, end: 1.0).chain(interval),
    );
    final slide = parent.drive(
      Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
          .chain(interval),
    );

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

// ── Vehicle Tile ──────────────────────────────────────────────────────────────

class _VehicleTile extends StatefulWidget {
  final VehicleType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleTile({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_VehicleTile> createState() => _VehicleTileState();
}

class _VehicleTileState extends State<_VehicleTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 160),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final iconBoxSize = (w * 0.13).clamp(44.0, 58.0);
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.042,
            vertical: h * 0.018,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.04)
                : Colors.white,
            borderRadius: BorderRadius.circular(w * 0.036),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: w * 0.06,
                      offset: Offset(0, w * 0.015),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: w * 0.04,
                      offset: Offset(0, w * 0.008),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Icon box
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: iconBoxSize,
                height: iconBoxSize,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(w * 0.028),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.type.icon,
                      key: ValueKey(isSelected),
                      size: iconBoxSize * 0.48,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),

              SizedBox(width: w * 0.038),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: (w * 0.042).clamp(14.0, 18.0),
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        height: 1.2,
                      ),
                      child: Text(widget.type.label),
                    ),
                    SizedBox(height: h * 0.004),
                    Text(
                      widget.type.description,
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: (w * 0.032).clamp(11.0, 13.0),
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: w * 0.028),

              // Selection indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: w * 0.058,
                height: w * 0.058,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 0 : 1.5,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: w * 0.034,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Registration Stepper (public — shared with vehicle details screen) ─────────

class RegistrationStepper extends StatelessWidget {
  final List<String> steps;
  final int currentIndex;

  const RegistrationStepper({
    super.key,
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
                  color: i <= currentIndex ? AppColors.primary : Colors.white,
                  border: Border.all(
                    color: i <= currentIndex ? AppColors.primary : AppColors.border,
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
                  fontSize: (w * 0.026).clamp(8.0, 11.0),
                  fontWeight:
                      i == currentIndex ? FontWeight.w700 : FontWeight.w400,
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
