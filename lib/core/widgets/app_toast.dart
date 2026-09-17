import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:delivery_boy/constant/app_theme.dart';

/// Animated overlay toast for success/error feedback — the same style used
/// on the vendor and customer apps, in place of a raw [SnackBar].
///
/// - **Success**: green badge with animated check.
/// - **Error**: red badge with animated X.
///
/// Auto-dismisses after [duration] and calls [onDismissed].
class AppToast extends StatefulWidget {
  final bool isSuccess;
  final String title;
  final String subtitle;
  final Duration duration;
  final VoidCallback? onDismissed;

  const AppToast({
    super.key,
    required this.isSuccess,
    required this.title,
    required this.subtitle,
    this.duration = const Duration(seconds: 3),
    this.onDismissed,
  });

  /// Show as an overlay entry — returns the entry so the caller can remove it
  /// early if needed.
  static OverlayEntry show(
    BuildContext context, {
    required bool isSuccess,
    required String title,
    required String subtitle,
    Duration duration = const Duration(seconds: 3),
  }) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => AppToast(
        isSuccess: isSuccess,
        title: title,
        subtitle: subtitle,
        duration: duration,
        onDismissed: () => entry.remove(),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    return entry;
  }

  @override
  State<AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<AppToast> with TickerProviderStateMixin {
  late final AnimationController _slideController;
  late final AnimationController _iconController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    ));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );

    _slideController.forward().then((_) {
      _iconController.forward();
    });

    _autoDismiss = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    _autoDismiss?.cancel();
    await _slideController.reverse();
    widget.onDismissed?.call();
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _slideController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final topPad = MediaQuery.of(context).padding.top;
    final accentColor = widget.isSuccess ? AppColors.success : AppColors.error;

    return Positioned(
      top: topPad + 12,
      left: w * 0.04,
      right: w * 0.04,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onVerticalDragEnd: (d) {
              if (d.primaryVelocity != null && d.primaryVelocity! < -200) {
                _dismiss();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(w * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(w * 0.04),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Animated badge icon
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: w * 0.12,
                        height: w * 0.12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor,
                              accentColor.withValues(alpha: 0.75),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.isSuccess
                              ? HugeIcons.strokeRoundedTick01
                              : HugeIcons.strokeRoundedCancel01,
                          color: Colors.white,
                          size: w * 0.06,
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.035),
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontFamily: 'Mukta',
                              fontSize: w * 0.038,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: w * 0.005),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              fontFamily: 'Mukta',
                              fontSize: w * 0.031,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Accent bar
                    Container(
                      width: 4,
                      height: w * 0.1,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
