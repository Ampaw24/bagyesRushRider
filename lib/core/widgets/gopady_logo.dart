import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:gopady_rider/constant/app_tokens.dart';
import 'package:gopady_rider/constant/asset_images.dart';

enum GoPadyLogoVariant {
  /// Green "Go", yellow "Pady" — for white and mint surfaces.
  light,

  /// White "Go", yellow "Pady" — for forest and brand-green surfaces.
  onDark,
}

/// The official GoPady lockup, used as-is (never recoloured or re-typeset).
///
/// The tagline row is only legible from [minLockupWidth] up; narrower slots
/// get the speed-cart mark instead.
class GoPadyLogo extends StatelessWidget {
  const GoPadyLogo({
    super.key,
    required this.width,
    this.variant = GoPadyLogoVariant.light,
    this.decorative = false,
  });

  /// Below this width the tagline would be unreadable.
  static const double minLockupWidth = 160;

  final double width;
  final GoPadyLogoVariant variant;

  /// True when the logo sits next to the name as text, so screen readers
  /// shouldn't announce it twice.
  final bool decorative;

  @override
  Widget build(BuildContext context) {
    final useMark = width < minLockupWidth;
    final asset = switch ((useMark, variant)) {
      (true, GoPadyLogoVariant.light) => AssetImages.gopadyIconGreen,
      (true, GoPadyLogoVariant.onDark) => AssetImages.gopadyIconYellow,
      (false, GoPadyLogoVariant.light) => AssetImages.gopadyLogoLight,
      (false, GoPadyLogoVariant.onDark) =>
        AssetImages.gopadyLogoTransparentWhite,
    };

    final image = Image.asset(
      asset,
      width: width,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );

    if (decorative) return ExcludeSemantics(child: image);
    return Semantics(label: 'GoPady', header: true, child: image);
  }
}

/// Plays [child]'s one-shot entrance during the [begin]–[end] slice of
/// [animation]: fade, scale from [scaleFrom], slide in from [slideFrom]
/// and sharpen from [blurFrom]
/// (a fraction of the child's own size, so it scales with the screen).
/// Renders the final pose immediately when animations are disabled.
class BrandReveal extends StatelessWidget {
  const BrandReveal({
    super.key,
    required this.animation,
    required this.child,
    this.begin = 0,
    this.end = 1,
    this.scaleFrom = 1,
    this.slideFrom = Offset.zero,
    this.blurFrom = 0,
    this.curve = AppMotion.outExpo,
  });

  final Animation<double> animation;
  final Widget child;
  final double begin;
  final double end;
  final double scaleFrom;
  final Offset slideFrom;

  /// Starting blur sigma in logical pixels; sharpens to zero as it settles.
  final double blurFrom;
  final Curve curve;

  Animation<double> _slice(Curve curve) =>
      animation.drive(CurveTween(curve: Interval(begin, end, curve: curve)));

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final motion = _slice(curve);
    return FadeTransition(
      opacity: _slice(Curves.easeOut),
      child: SlideTransition(
        position: motion.drive(Tween(begin: slideFrom, end: Offset.zero)),
        child: ScaleTransition(
          scale: motion.drive(Tween(begin: scaleFrom, end: 1.0)),
          child: blurFrom == 0
              ? child
              : AnimatedBuilder(
                  animation: motion,
                  child: child,
                  builder: (context, child) {
                    final sigma = blurFrom * (1 - motion.value);
                    if (sigma < 0.1) return child!;
                    return ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: sigma,
                        sigmaY: sigma,
                      ),
                      child: child,
                    );
                  },
                ),
        ),
      ),
    );
  }
}
