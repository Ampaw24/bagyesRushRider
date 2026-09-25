import 'dart:io';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';
import 'package:delivery_boy/features/rider/auth/views/widgets/phone_change_flow_sheet.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_avatar_providers.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:delivery_boy/features/rider/shared/rider_me_action_status.dart';
import 'package:delivery_boy/features/rider/shared_widgets/rider_avatar.dart';
import 'package:hugeicons/hugeicons.dart';

/// Edit Profile — personal info + vehicle plate, restyled after the
/// customer/vendor app's `EditProfile` screen: a pinned hero header
/// carrying the avatar, focus-aware field cards, and a save action that
/// only lights up once something has actually changed (so a rider tapping
/// in and back out never fires a needless PATCH). Kept solid-colour
/// throughout rather than the reference's gradients, per this project's
/// no-gradient-UI rule.
class RiderProfileEditScreen extends ConsumerStatefulWidget {
  const RiderProfileEditScreen({super.key});

  @override
  ConsumerState<RiderProfileEditScreen> createState() =>
      _RiderProfileEditScreenState();
}

class _RiderProfileEditScreenState
    extends ConsumerState<RiderProfileEditScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _areaInputCtrl = TextEditingController();
  File? _pickedImage;
  bool _isUploading = false;

  // Work preferences — plain fields rather than controllers since they're
  // edited via chips/pickers, not free text.
  List<String> _operatingAreas = [];
  List<String> _operatingDays = [];
  String? _shiftStartTime;
  String? _shiftEndTime;
  double _maxDeliveryRadiusKm = 15;

  // Snapshot of the loaded values — compared against the live controllers
  // to decide whether Save should be reachable at all.
  String _initialFirstName = '';
  String _initialLastName = '';
  String _initialPlate = '';
  List<String> _initialOperatingAreas = const [];
  List<String> _initialOperatingDays = const [];
  String? _initialShiftStartTime;
  String? _initialShiftEndTime;
  double _initialMaxDeliveryRadiusKm = 15;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl.addListener(_handleFieldChanged);
    _lastNameCtrl.addListener(_handleFieldChanged);
    _plateCtrl.addListener(_handleFieldChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _populate());
  }

  void _handleFieldChanged() {
    if (mounted) setState(() {});
  }

  bool get _isDirty =>
      _pickedImage != null ||
      _firstNameCtrl.text.trim() != _initialFirstName ||
      _lastNameCtrl.text.trim() != _initialLastName ||
      _plateCtrl.text.trim() != _initialPlate ||
      !listEquals(_operatingAreas, _initialOperatingAreas) ||
      !listEquals(_operatingDays, _initialOperatingDays) ||
      _shiftStartTime != _initialShiftStartTime ||
      _shiftEndTime != _initialShiftEndTime ||
      _maxDeliveryRadiusKm != _initialMaxDeliveryRadiusKm;

  void _populate() {
    final session = sl<UserSessionManager>();
    final profile = ref.read(riderMeProfileProvider).profile;
    _firstNameCtrl.text = profile?.firstName ?? session.firstName ?? '';
    _lastNameCtrl.text = profile?.lastName ?? session.lastName ?? '';
    _plateCtrl.text = profile?.plateNumber ?? '';
    _operatingAreas = List<String>.from(profile?.operatingAreas ?? const []);
    _operatingDays = List<String>.from(profile?.operatingDays ?? const []);
    _shiftStartTime = profile?.shiftStartTime;
    _shiftEndTime = profile?.shiftEndTime;
    _maxDeliveryRadiusKm =
        (profile?.maxDeliveryRadiusKm?.toDouble() ?? 15).clamp(1, 100);

    _initialFirstName = _firstNameCtrl.text;
    _initialLastName = _lastNameCtrl.text;
    _initialPlate = _plateCtrl.text;
    _initialOperatingAreas = List<String>.from(_operatingAreas);
    _initialOperatingDays = List<String>.from(_operatingDays);
    _initialShiftStartTime = _shiftStartTime;
    _initialShiftEndTime = _shiftEndTime;
    _initialMaxDeliveryRadiusKm = _maxDeliveryRadiusKm;
    setState(() {});
  }

  void _addArea(String value) {
    final area = value.trim();
    if (area.isEmpty || _operatingAreas.length >= 10) return;
    if (_operatingAreas.any((a) => a.toLowerCase() == area.toLowerCase())) {
      _areaInputCtrl.clear();
      return;
    }
    setState(() {
      _operatingAreas.add(area);
      _areaInputCtrl.clear();
    });
  }

  void _removeArea(String area) => setState(() => _operatingAreas.remove(area));

  void _toggleDay(String day) => setState(() {
        if (_operatingDays.contains(day)) {
          _operatingDays.remove(day);
        } else {
          _operatingDays.add(day);
        }
      });

  void _setDeliveryRadius(double value) =>
      setState(() => _maxDeliveryRadiusKm = value);

  Future<void> _pickShiftTime({required bool isStart}) async {
    final current = isStart ? _shiftStartTime : _shiftEndTime;
    final parts = (current ?? '').split(':');
    final hour =
        int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? (isStart ? 8 : 18);
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      builder: (context, child) {
        final clampedScaler = MediaQuery.textScalerOf(context)
            .clamp(minScaleFactor: 0.8, maxScaleFactor: 1.2);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: clampedScaler),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                  ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isStart) {
        _shiftStartTime = formatted;
      } else {
        _shiftEndTime = formatted;
      }
    });
  }

  @override
  void dispose() {
    _firstNameCtrl
      ..removeListener(_handleFieldChanged)
      ..dispose();
    _lastNameCtrl
      ..removeListener(_handleFieldChanged)
      ..dispose();
    _plateCtrl
      ..removeListener(_handleFieldChanged)
      ..dispose();
    _areaInputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final profileState = ref.watch(riderMeProfileProvider);
    final isLoading =
        profileState.actionStatus == RiderMeActionStatus.inProgress ||
            _isUploading;

    ref.listen(riderMeProfileProvider, (prev, next) {
      // Only on the transition into an error, so a later emission (e.g. a
      // profile reload) can't re-open the dialog for the same failure.
      if (next.actionStatus == RiderMeActionStatus.error &&
          prev?.actionStatus != RiderMeActionStatus.error &&
          next.actionMessage != null) {
        CustomDialog.showError(
          context: context,
          title: 'Profile Not Updated',
          subtitle: next.actionMessage!,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: (w * 0.52).clamp(210.0, 300.0),
            pinned: true,
            backgroundColor: AppColors.primary,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: EdgeInsets.all(w * 0.018),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  color: Colors.white,
                  size: w * 0.05,
                ),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: w * 0.04),
                child: isLoading
                    ? SizedBox(
                        width: w * 0.06,
                        height: w * 0.06,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : TextButton(
                        onPressed: _isDirty ? _save : null,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              Colors.white.withValues(alpha: 0.08),
                          disabledForegroundColor:
                              Colors.white.withValues(alpha: 0.4),
                          padding: EdgeInsets.symmetric(
                              horizontal: w * 0.045, vertical: w * 0.02),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(w * 0.05),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            fontWeight: FontWeight.w700,
                            fontSize: (w * 0.038).clamp(13.0, 16.0),
                          ),
                        ),
                      ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _ProfileEditHero(
                w: w,
                onTapAvatar: _selectPhotoBottomSheet,
                localImage: _pickedImage,
                avatarUrl: ref.watch(riderAvatarUrlProvider),
                isUploading: _isUploading,
              ),
            ),
          ),
          SliverPadding(
            padding:
                EdgeInsets.fromLTRB(w * 0.05, w * 0.045, w * 0.05, w * 0.08),
            sliver: SliverList.list(
              children: [
                const _SectionLabel('Personal Info'),
                SizedBox(height: w * 0.03),
                _ProfileFieldCard(
                  icon: HugeIcons.strokeRoundedUser,
                  iconColor: AppColors.primary,
                  label: 'First Name',
                  controller: _firstNameCtrl,
                  hint: 'Enter your first name',
                  textCapitalization: TextCapitalization.words,
                ),
                SizedBox(height: w * 0.03),
                _ProfileFieldCard(
                  icon: HugeIcons.strokeRoundedUser,
                  iconColor: AppColors.primary,
                  label: 'Last Name',
                  controller: _lastNameCtrl,
                  hint: 'Enter your last name',
                  textCapitalization: TextCapitalization.words,
                ),
                SizedBox(height: w * 0.03),
                _ReadOnlyInfoCard(
                  icon: HugeIcons.strokeRoundedSmartPhone01,
                  iconColor: AppColors.success,
                  label: 'PHONE NUMBER',
                  value: sl<UserSessionManager>().phone ?? 'Not set',
                  actionLabel: 'Change',
                  onAction: () {
                    final phone = sl<UserSessionManager>().phone;
                    if (phone == null || phone.isEmpty) return;
                    PhoneChangeFlowSheet.show(context, oldPhone: phone);
                  },
                ),
                SizedBox(height: w * 0.07),
                const _SectionLabel('Vehicle'),
                SizedBox(height: w * 0.03),
                _ProfileFieldCard(
                  icon: HugeIcons.strokeRoundedCar01,
                  iconColor: AppColors.secondary,
                  label: 'Number Plate',
                  controller: _plateCtrl,
                  hint: 'e.g. GR-1234-21',
                  textCapitalization: TextCapitalization.characters,
                ),
                SizedBox(height: w * 0.07),
                const _SectionLabel('Work Preferences'),
                SizedBox(height: w * 0.03),
                _DeliveryRadiusCard(
                  radiusKm: _maxDeliveryRadiusKm,
                  onChanged: _setDeliveryRadius,
                ),
                SizedBox(height: w * 0.03),
                _OperatingAreasCard(
                  areas: _operatingAreas,
                  controller: _areaInputCtrl,
                  onAdd: _addArea,
                  onRemove: _removeArea,
                ),
                SizedBox(height: w * 0.03),
                _OperatingDaysCard(
                  selectedDays: _operatingDays,
                  onToggleDay: _toggleDay,
                ),
                SizedBox(height: w * 0.03),
                Row(
                  children: [
                    Expanded(
                      child: _ShiftTimeCard(
                        label: 'Shift Start',
                        time: _shiftStartTime,
                        onTap: () => _pickShiftTime(isStart: true),
                      ),
                    ),
                    SizedBox(width: w * 0.03),
                    Expanded(
                      child: _ShiftTimeCard(
                        label: 'Shift End',
                        time: _shiftEndTime,
                        onTap: () => _pickShiftTime(isStart: false),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: w * 0.09),
                AppGradientButton(
                  label: 'Save Changes',
                  height: (w * 0.13).clamp(46.0, 58.0),
                  borderRadius: w * 0.035,
                  isLoading: isLoading,
                  onPressed: (isLoading || !_isDirty) ? null : _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectPhotoBottomSheet() async {
    final w = MediaQuery.sizeOf(context).width;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.scaffold,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.06)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(w * 0.05, 0, w * 0.05, w * 0.06),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Update Profile Photo',
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: (w * 0.043).clamp(14.0, 18.0),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.05),
            _PhotoSourceOption(
              icon: HugeIcons.strokeRoundedCamera01,
              label: 'Take a Photo',
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            SizedBox(height: w * 0.03),
            _PhotoSourceOption(
              icon: HugeIcons.strokeRoundedImage01,
              label: 'Choose from Gallery',
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final file = await ImagePicker()
        .pickImage(source: source, imageQuality: 80, maxWidth: 1024);
    if (file != null && mounted) {
      setState(() => _pickedImage = File(file.path));
    }
  }

  Future<void> _save() async {
    final notifier = ref.read(riderMeProfileProvider.notifier);

    // 1. Upload photo if a new one was picked
    if (_pickedImage != null) {
      setState(() => _isUploading = true);
      final uploaded = await notifier.uploadPhoto(_pickedImage!.path);
      setState(() => _isUploading = false);
      if (!uploaded && mounted) return; // error shown via listener
    }

    // 2. Update text fields
    final ok = await notifier.updateProfile({
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'plate_number': _plateCtrl.text.trim(),
      'operating_areas': _operatingAreas,
      'operating_days': _operatingDays,
      'shift_start_time': _shiftStartTime,
      'shift_end_time': _shiftEndTime,
      'max_delivery_radius_km': _maxDeliveryRadiusKm.round(),
    });

    if (ok) {
      await sl<UserSessionManager>().updateUser({
        'profile': {
          ...?sl<UserSessionManager>().currentUser?['profile'] as Map?,
          'first_name': _firstNameCtrl.text.trim(),
          'last_name': _lastNameCtrl.text.trim(),
        },
      });
    }

    if (ok && mounted) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }
}

// ── Hero header ─────────────────────────────────────────────────────────────

class _ProfileEditHero extends StatelessWidget {
  final double w;
  final VoidCallback onTapAvatar;
  final File? localImage;
  final String? avatarUrl;
  final bool isUploading;

  const _ProfileEditHero({
    required this.w,
    required this.onTapAvatar,
    this.localImage,
    this.avatarUrl,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatarRadius = (w * 0.14).clamp(48.0, 76.0);

    return ColoredBox(
      color: AppColors.primary,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: w * 0.1),
            GestureDetector(
              onTap: onTapAvatar,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: localImage != null
                        ? CircleAvatar(
                            radius: avatarRadius,
                            backgroundImage: FileImage(localImage!),
                          )
                        : RiderAvatar(
                            radius: avatarRadius,
                            imageUrl: avatarUrl,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.25),
                            placeholder: HugeIcon(
                              icon: HugeIcons.strokeRoundedUser,
                              size: avatarRadius * 0.75,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  if (isUploading)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black38,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    ),
                  Container(
                    padding: EdgeInsets.all(w * 0.02),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCamera01,
                      color: Colors.white,
                      size: w * 0.04,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: w * 0.03),
            Text(
              'Tap to change photo',
              style: TextStyle(
                fontFamily: 'Mukta',
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: (w * 0.032).clamp(11.0, 14.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Mukta',
        fontSize: (w * 0.03).clamp(10.0, 13.0),
        fontWeight: FontWeight.w800,
        color: AppColors.textHint,
        letterSpacing: 1.1,
      ),
    );
  }
}

// ── Focus-aware field card ───────────────────────────────────────────────────
//
// Each field is its own bordered card whose border/shadow intensify on
// focus, so the active input reads clearly without relying on a shared
// list divider.

class _ProfileFieldCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextCapitalization textCapitalization;

  const _ProfileFieldCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.controller,
    required this.hint,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<_ProfileFieldCard> createState() => _ProfileFieldCardState();
}

class _ProfileFieldCardState extends State<_ProfileFieldCard> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(
          color: _focused ? AppColors.primary : AppColors.border,
          width: _focused ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _focused
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: _focused ? 16 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: w * 0.1,
            height: w * 0.1,
            decoration: BoxDecoration(
              color: widget.iconColor.withValues(alpha: _focused ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(w * 0.03),
            ),
            child: Center(
              child: HugeIcon(
                icon: widget.icon,
                color: widget.iconColor,
                size: w * 0.045,
              ),
            ),
          ),
          SizedBox(width: w * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: (w * 0.028).clamp(10.0, 12.0),
                    fontWeight: FontWeight.w700,
                    color: _focused ? AppColors.primary : AppColors.textHint,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: w * 0.005),
                TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  textCapitalization: widget.textCapitalization,
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: (w * 0.04).clamp(14.0, 17.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      fontFamily: 'Mukta',
                      color: AppColors.textHint,
                      fontSize: (w * 0.036).clamp(12.0, 15.0),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Max delivery radius (slider) ─────────────────────────────────────────────

class _DeliveryRadiusCard extends StatelessWidget {
  final double radiusKm;
  final ValueChanged<double> onChanged;

  const _DeliveryRadiusCard({
    required this.radiusKm,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.035),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: w * 0.1,
                height: w * 0.1,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(w * 0.03),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedLocation04,
                    color: AppColors.secondary,
                    size: w * 0.045,
                  ),
                ),
              ),
              SizedBox(width: w * 0.035),
              Expanded(
                child: Text(
                  'MAX DELIVERY RADIUS',
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: (w * 0.028).clamp(10.0, 12.0),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHint,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Text(
                '${radiusKm.round()} km',
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: (w * 0.042).clamp(15.0, 18.0),
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
              trackHeight: w * 0.008,
            ),
            child: Slider(
              value: radiusKm,
              min: 1,
              max: 100,
              divisions: 99,
              label: '${radiusKm.round()} km',
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Operating areas (chip input) ─────────────────────────────────────────────

class _OperatingAreasCard extends StatelessWidget {
  final List<String> areas;
  final TextEditingController controller;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  const _OperatingAreasCard({
    required this.areas,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final atLimit = areas.length >= 10;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.035),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: w * 0.1,
                height: w * 0.1,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(w * 0.03),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedLocation01,
                    color: AppColors.accent,
                    size: w * 0.045,
                  ),
                ),
              ),
              SizedBox(width: w * 0.035),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OPERATING AREAS',
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: (w * 0.028).clamp(10.0, 12.0),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: w * 0.005),
                    Text(
                      atLimit
                          ? 'Maximum of 10 zones reached'
                          : 'Zones you\'re willing to deliver in',
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: (w * 0.032).clamp(11.0, 13.0),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (areas.isNotEmpty) ...[
            SizedBox(height: w * 0.035),
            Wrap(
              spacing: w * 0.02,
              runSpacing: w * 0.02,
              children: areas
                  .map((area) => _RemovableChip(
                        label: area,
                        onRemove: () => onRemove(area),
                      ))
                  .toList(),
            ),
          ],
          if (!atLimit) ...[
            SizedBox(height: w * 0.035),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: (w * 0.038).clamp(13.0, 16.0),
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'e.g. East Legon',
                      hintStyle: TextStyle(
                        fontFamily: 'Mukta',
                        color: AppColors.textHint,
                        fontSize: (w * 0.036).clamp(12.0, 15.0),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: w * 0.03, vertical: w * 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(w * 0.03),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: onAdd,
                  ),
                ),
                SizedBox(width: w * 0.02),
                Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(w * 0.03),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(w * 0.03),
                    onTap: () => onAdd(controller.text),
                    child: Padding(
                      padding: EdgeInsets.all(w * 0.032),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedAdd01,
                        color: Colors.white,
                        size: w * 0.05,
                      ),
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

class _RemovableChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _RemovableChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: w * 0.017),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(w * 0.05),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: (w * 0.033).clamp(12.0, 14.0),
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: w * 0.015),
          GestureDetector(
            onTap: onRemove,
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedCancel01,
              color: AppColors.primary,
              size: w * 0.032,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Operating days (multi-select chips) ──────────────────────────────────────

class _OperatingDaysCard extends StatelessWidget {
  static const _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  static const _dayLabels = {
    'monday': 'Mon',
    'tuesday': 'Tue',
    'wednesday': 'Wed',
    'thursday': 'Thu',
    'friday': 'Fri',
    'saturday': 'Sat',
    'sunday': 'Sun',
  };

  final List<String> selectedDays;
  final ValueChanged<String> onToggleDay;

  const _OperatingDaysCard({
    required this.selectedDays,
    required this.onToggleDay,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final today = _days[DateTime.now().weekday - 1];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.035),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: w * 0.1,
                height: w * 0.1,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(w * 0.03),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedCalendar03,
                    color: AppColors.success,
                    size: w * 0.045,
                  ),
                ),
              ),
              SizedBox(width: w * 0.035),
              Text(
                'OPERATING DAYS',
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: (w * 0.028).clamp(10.0, 12.0),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHint,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.035),
          Wrap(
            spacing: w * 0.02,
            runSpacing: w * 0.02,
            children: _days.map((day) {
              final isSelected = selectedDays.contains(day);
              final isToday = day == today;
              return GestureDetector(
                onTap: () => onToggleDay(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.032,
                    vertical: w * 0.02,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(w * 0.03),
                    border: isToday
                        ? Border.all(
                            color:
                                isSelected ? Colors.white : AppColors.primary,
                            width: 1.4,
                          )
                        : null,
                  ),
                  child: Text(
                    _dayLabels[day]!,
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: (w * 0.033).clamp(12.0, 14.0),
                      fontWeight: FontWeight.w700,
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Shift time picker card ───────────────────────────────────────────────────

class _ShiftTimeCard extends StatelessWidget {
  final String label;
  final String? time;
  final VoidCallback onTap;

  const _ShiftTimeCard({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(w * 0.04),
      child: InkWell(
        borderRadius: BorderRadius.circular(w * 0.04),
        onTap: onTap,
        child: Container(
          padding:
              EdgeInsets.symmetric(horizontal: w * 0.035, vertical: w * 0.03),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(w * 0.04),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: (w * 0.026).clamp(9.0, 11.0),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHint,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: w * 0.015),
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedClock01,
                    color: AppColors.primary,
                    size: w * 0.042,
                  ),
                  SizedBox(width: w * 0.02),
                  Expanded(
                    child: Text(
                      time ?? 'Not set',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: (w * 0.038).clamp(13.0, 16.0),
                        fontWeight: FontWeight.w700,
                        color: time != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
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

// ── Read-only info card (phone) ──────────────────────────────────────────────

class _ReadOnlyInfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String actionLabel;
  final VoidCallback onAction;

  const _ReadOnlyInfoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: w * 0.1,
            height: w * 0.1,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(w * 0.03),
            ),
            child: Center(
              child: HugeIcon(icon: icon, color: iconColor, size: w * 0.045),
            ),
          ),
          SizedBox(width: w * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: (w * 0.028).clamp(10.0, 12.0),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHint,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: w * 0.005),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: (w * 0.04).clamp(14.0, 17.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
              padding: EdgeInsets.symmetric(
                  horizontal: w * 0.03, vertical: w * 0.014),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(w * 0.03),
              ),
            ),
            child: Text(
              actionLabel,
              style: TextStyle(
                fontFamily: 'Mukta',
                fontWeight: FontWeight.w700,
                fontSize: (w * 0.033).clamp(12.0, 14.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photo source bottom-sheet option ─────────────────────────────────────────

class _PhotoSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(w * 0.04),
        child: Container(
          padding:
              EdgeInsets.symmetric(horizontal: w * 0.045, vertical: w * 0.038),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(w * 0.04),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.022),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                    icon: icon, color: AppColors.primary, size: w * 0.045),
              ),
              SizedBox(width: w * 0.04),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: (w * 0.038).clamp(13.0, 16.0),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
