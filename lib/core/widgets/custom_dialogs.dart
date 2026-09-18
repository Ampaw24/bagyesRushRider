import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';

/// What a [CustomDialog] communicates — drives its accent colour and icon.
enum DialogType { success, error, confirmation, info, warning }

class CustomDialogConfig {
  const CustomDialogConfig({
    required this.title,
    required this.subtitle,
    this.type = DialogType.info,
    this.onConfirm,
    this.onCancel,
    this.confirmText = 'OK',
    this.cancelText = 'Cancel',
    this.showCancelButton = false,
    this.customColor,
    this.content,
    this.barrierDismissible = false,
  });

  final String title;
  final String subtitle;
  final DialogType type;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String confirmText;
  final String cancelText;
  final bool showCancelButton;
  final Color? customColor;
  final Widget? content;
  final bool barrierDismissible;
}

/// Animated modal dialog — the same component the vendor/customer app uses
/// to surface API errors, confirmations and success messages.
///
/// Use the static helpers rather than building a [CustomDialogConfig]:
///
/// ```dart
/// CustomDialog.showError(
///   context: context,
///   title: 'Sign In Failed',
///   subtitle: state.errorMessage!,
/// );
/// ```
///
/// Callbacks run after the dialog has animated out and been popped, so they
/// can navigate freely.
class CustomDialog extends StatefulWidget {
  const CustomDialog({super.key, required this.config});

  final CustomDialogConfig config;

  @override
  State<CustomDialog> createState() => _CustomDialogState();

  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String subtitle,
    VoidCallback? onConfirm,
    String confirmText = 'OK',
    bool barrierDismissible = false,
  }) =>
      _show(
        context,
        CustomDialogConfig(
          title: title,
          subtitle: subtitle,
          type: DialogType.success,
          onConfirm: onConfirm,
          confirmText: confirmText,
          barrierDismissible: barrierDismissible,
        ),
      );

  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String subtitle,
    VoidCallback? onConfirm,
    String confirmText = 'OK',
    bool barrierDismissible = false,
  }) =>
      _show(
        context,
        CustomDialogConfig(
          title: title,
          subtitle: subtitle,
          type: DialogType.error,
          onConfirm: onConfirm,
          confirmText: confirmText,
          barrierDismissible: barrierDismissible,
        ),
      );

  static Future<void> showConfirmation({
    required BuildContext context,
    required String title,
    required String subtitle,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool barrierDismissible = false,
    Widget? content,
  }) =>
      _show(
        context,
        CustomDialogConfig(
          title: title,
          subtitle: subtitle,
          type: DialogType.confirmation,
          onConfirm: onConfirm,
          onCancel: onCancel,
          confirmText: confirmText,
          cancelText: cancelText,
          showCancelButton: true,
          barrierDismissible: barrierDismissible,
          content: content,
        ),
      );

  static Future<void> showWarning({
    required BuildContext context,
    required String title,
    required String subtitle,
    VoidCallback? onConfirm,
    String confirmText = 'OK',
    bool barrierDismissible = false,
  }) =>
      _show(
        context,
        CustomDialogConfig(
          title: title,
          subtitle: subtitle,
          type: DialogType.warning,
          onConfirm: onConfirm,
          confirmText: confirmText,
          barrierDismissible: barrierDismissible,
        ),
      );

  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String subtitle,
    VoidCallback? onConfirm,
    String confirmText = 'OK',
    bool barrierDismissible = false,
  }) =>
      _show(
        context,
        CustomDialogConfig(
          title: title,
          subtitle: subtitle,
          type: DialogType.info,
          onConfirm: onConfirm,
          confirmText: confirmText,
          barrierDismissible: barrierDismissible,
        ),
      );

  static Future<void> _show(BuildContext context, CustomDialogConfig config) {
    return showDialog<void>(
      context: context,
      barrierDismissible: config.barrierDismissible,
      builder: (_) => CustomDialog(config: config),
    );
  }
}

class _CustomDialogState extends State<CustomDialog>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 400);

  /// Sizes are proportions of the screen width (matching the vendor app on
  /// phones), but stop growing past a large-phone width so tablets and
  /// landscape get a comfortably sized dialog rather than a stretched one.
  static const _maxBaseWidth = 480.0;

  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _entered = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Started here rather than in initState so the OS "reduce motion"
    // setting can be read first.
    if (_entered) return;
    _entered = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.duration = Duration.zero;
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _accent {
    if (widget.config.customColor != null) return widget.config.customColor!;
    switch (widget.config.type) {
      case DialogType.error:
        return AppColors.error;
      case DialogType.success:
        return AppColors.success;
      case DialogType.warning:
        return AppColors.warning;
      case DialogType.confirmation:
        return AppColors.primary;
      case DialogType.info:
        return AppColors.info;
    }
  }

  IconData get _icon {
    switch (widget.config.type) {
      case DialogType.error:
        return HugeIcons.strokeRoundedAlertCircle;
      case DialogType.success:
        return HugeIcons.strokeRoundedCheckmarkCircle01;
      case DialogType.warning:
      case DialogType.confirmation:
        return HugeIcons.strokeRoundedAlert01;
      case DialogType.info:
        return HugeIcons.strokeRoundedInformationCircle;
    }
  }

  Future<void> _close(VoidCallback? callback) async {
    // First tap wins. A second tap would restart the exit animation — whose
    // cancelled first run never completes — and fire its own callback
    // instead, e.g. Confirm then Cancel running onCancel.
    if (_closing) return;
    _closing = true;
    await _controller.reverse();
    if (!mounted) return;
    Navigator.of(context).pop();
    callback?.call();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final base = math.min(size.width, _maxBaseWidth);
    final textTheme = Theme.of(context).textTheme;
    final config = widget.config;

    return PopScope(
      canPop: config.barrierDismissible,
      child: FadeTransition(
        opacity: _fade,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(
            horizontal: size.width * 0.06,
            vertical: size.height * 0.02,
          ),
          child: SlideTransition(
            position: _slide,
            child: ScaleTransition(
              scale: _scale,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: base * 0.85),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(base * 0.045),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: base * 0.05,
                        offset: Offset(0, base * 0.02),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: base * 0.055,
                      vertical: size.height * 0.022,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _IconBadge(
                          icon: _icon,
                          color: _accent,
                          diameter: base * 0.155,
                        ),
                        SizedBox(height: size.height * 0.016),
                        Text(
                          config.title,
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: base * 0.046,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: size.height * 0.009),
                        Text(
                          config.subtitle,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: base * 0.034,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                        if (config.content != null) ...[
                          SizedBox(height: size.height * 0.015),
                          config.content!,
                        ],
                        SizedBox(height: size.height * 0.024),
                        _buildActions(base, size.height),
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

  Widget _buildActions(double base, double screenHeight) {
    final confirm = _DialogButton(
      label: widget.config.confirmText,
      accent: _accent,
      isPrimary: true,
      base: base,
      screenHeight: screenHeight,
      onPressed: () => _close(widget.config.onConfirm),
    );
    if (!widget.config.showCancelButton) {
      return SizedBox(width: double.infinity, child: confirm);
    }
    return Row(
      children: [
        Expanded(
          child: _DialogButton(
            label: widget.config.cancelText,
            accent: _accent,
            isPrimary: false,
            base: base,
            screenHeight: screenHeight,
            onPressed: () => _close(widget.config.onCancel),
          ),
        ),
        SizedBox(width: base * 0.03),
        Expanded(child: confirm),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    required this.diameter,
  });

  final IconData icon;
  final Color color;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: diameter * 0.026,
        ),
      ),
      child: Icon(icon, size: diameter * 0.48, color: color),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.accent,
    required this.isPrimary,
    required this.base,
    required this.screenHeight,
    required this.onPressed,
  });

  final String label;
  final Color accent;
  final bool isPrimary;
  final double base;
  final double screenHeight;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(base * 0.03),
    );
    final padding = EdgeInsets.symmetric(
      vertical: screenHeight * 0.013,
      horizontal: base * 0.04,
    );
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: base * 0.038,
          fontWeight: FontWeight.w600,
        );
    final child = Text(label, textAlign: TextAlign.center);

    if (isPrimary) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: AppColors.onPrimary,
          padding: padding,
          shape: shape,
          textStyle: textStyle,
        ),
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surfaceVariant,
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        padding: padding,
        shape: shape,
        textStyle: textStyle,
      ),
      child: child,
    );
  }
}
