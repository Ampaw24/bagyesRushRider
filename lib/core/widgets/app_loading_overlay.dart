import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:delivery_boy/constant/app_theme.dart';

/// Full-screen, non-dismissible busy indicator for actions that must block
/// interaction until they settle — e.g. logout. Same visual language as
/// [CustomDialog] (white card, soft shadow, no gradients/glow) so it reads
/// as part of the same design system rather than a one-off spinner.
///
/// ```dart
/// AppLoadingOverlay.show(context, message: 'Logging out...');
/// await doWork();
/// if (context.mounted) AppLoadingOverlay.hide(context);
/// ```
class AppLoadingOverlay {
  const AppLoadingOverlay._();

  static Future<void> show(
    BuildContext context, {
    String message = 'Please wait...',
  }) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _AppLoadingOverlayView(message: message),
    );
  }

  /// No-ops if the overlay isn't showing, so callers don't need to track
  /// whether [show] actually pushed a route.
  static void hide(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) navigator.pop();
  }
}

class _AppLoadingOverlayView extends StatelessWidget {
  const _AppLoadingOverlayView({required this.message});

  final String message;

  static const _maxBaseWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final base = math.min(size.width, _maxBaseWidth);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return PopScope(
      canPop: false,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          builder: (context, t, child) => Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.85 + (0.15 * t.clamp(0.0, 1.0)), child: child),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: base * 0.6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(base * 0.045),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: base * 0.05,
                    offset: Offset(0, base * 0.02),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: base * 0.07,
                  vertical: size.height * 0.028,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: base * 0.11,
                      height: base * 0.11,
                      child: CircularProgressIndicator(
                        strokeWidth: base * 0.009,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    SizedBox(height: size.height * 0.018),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: base * 0.036,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
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
