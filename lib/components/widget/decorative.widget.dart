import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../constant/constant.dart';

/// Warm cream backdrop shared by the splash, onboarding and login screens.
const Color kDecorativeBackgroundColor = Color(0xFFFBF7F4);

/// Wraps [child] with the shared decorative background — Adinkra-inspired
/// motifs (concentric rings, a rotated square, a leaf shape, a paired dot
/// grid) faded top and bottom so the motifs never compete with foreground
/// content. Use alongside [kDecorativeBackgroundColor] as the Scaffold's
/// `backgroundColor` for a consistent look across auth/onboarding screens.
class DecorativeBackground extends StatelessWidget {
  const DecorativeBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _DecorativeMotifLayer()),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _DecorativeMotifLayer extends StatelessWidget {
  const _DecorativeMotifLayer();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [0.0, 0.16, 0.84, 1.0],
            ).createShader(rect);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _DotGridPainter(
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Top-left concentric ring.
              Positioned(
                left: -width * 0.30,
                top: height * 0.03,
                child: _Ring(
                  diameter: width * 0.62,
                  color: primaryColor.withValues(alpha: 0.06),
                  strokeWidth: width * 0.62 * 0.035,
                ),
              ),
              // Top-right rotated square with a small solid centre.
              Positioned(
                right: width * 0.02,
                top: height * 0.14,
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: width * 0.20,
                        height: width * 0.20,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.06),
                            width: 1.4,
                          ),
                        ),
                      ),
                      Container(
                        width: width * 0.05,
                        height: width * 0.05,
                        color: primaryColor.withValues(alpha: 0.14),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom-left leaf motif (a square with one rounded corner).
              Positioned(
                left: -width * 0.06,
                bottom: height * 0.14,
                child: Transform.rotate(
                  angle: -math.pi / 10,
                  child: Container(
                    width: width * 0.22,
                    height: width * 0.22,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.06),
                        width: 1.4,
                      ),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(width * 0.22),
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom-right concentric ring.
              Positioned(
                right: -width * 0.28,
                bottom: -height * 0.05,
                child: _Ring(
                  diameter: width * 0.7,
                  color: Colors.black.withValues(alpha: 0.05),
                  strokeWidth: width * 0.7 * 0.03,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({
    required this.diameter,
    required this.color,
    required this.strokeWidth,
  });

  final double diameter;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: strokeWidth),
      ),
    );
  }
}

/// Even grid of closely-spaced dot pairs, tiled across the full background.
class _DotGridPainter extends CustomPainter {
  const _DotGridPainter({required this.color});

  final Color color;

  static const double _spacing = 30;
  static const double _dotRadius = 1.2;
  static const double _pairGap = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (double y = _spacing / 2; y < size.height; y += _spacing) {
      for (double x = _spacing / 2; x < size.width; x += _spacing) {
        canvas.drawCircle(Offset(x - _pairGap / 2, y), _dotRadius, paint);
        canvas.drawCircle(Offset(x + _pairGap / 2, y), _dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) =>
      oldDelegate.color != color;
}
