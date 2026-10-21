import 'package:flutter/material.dart';

import 'package:gopady_rider/constant/asset_images.dart';

/// Accra skyline silhouette, pinned to the bottom edge and scaled by width.
///
/// The source art is dark-green on black, so its luminance is converted to
/// alpha and tinted with [color]; the black backdrop never shows.
class SkylineWatermark extends StatelessWidget {
  const SkylineWatermark({
    super.key,
    required this.color,
    this.opacity = 0.85,
    this.maxHeightFactor = 0.4,
  });

  final Color color;
  final double opacity;

  /// Cap on the watermark height as a share of the available height, so
  /// landscape and wide screens never let it swallow the content.
  final double maxHeightFactor;

  // Source art is 1280x548 with black margins; this is the silhouette's
  // bounding box (left, top, right, bottom), used to crop the margins away so
  // the skyline touches the screen's left, right and bottom edges.
  static const double _sourceWidth = 1280;
  static const double _sourceHeight = 548;
  static const Rect _content = Rect.fromLTRB(56, 89, 1224, 474);
  // Silhouette green ≈ 51/255 on a ~0 backdrop.
  static const double _alphaGain = 6;
  // Clips JPEG noise on the black backdrop to fully transparent.
  static const double _noiseFloor = 20;

  ColorFilter get _lumaToTint => ColorFilter.matrix(<double>[
    0,
    0,
    0,
    0,
    (color.r * 255),
    0,
    0,
    0,
    0,
    (color.g * 255),
    0,
    0,
    0,
    0,
    (color.b * 255),
    0,
    _alphaGain * opacity,
    0,
    0,
    -_noiseFloor * opacity,
  ]);

  @override
  Widget build(BuildContext context) {
    final contentAspect = _content.width / _content.height;
    final alignment = Alignment(
      2 * _content.left / (_sourceWidth - _content.width) - 1,
      2 * _content.top / (_sourceHeight - _content.height) - 1,
    );

    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight * maxHeightFactor;
          final width = (maxHeight * contentAspect).clamp(
            0.0,
            constraints.maxWidth,
          );
          final height = width / contentAspect;

          return ClipRect(
            child: SizedBox(
              width: width,
              height: height,
              child: ColorFiltered(
                colorFilter: _lumaToTint,
                child: OverflowBox(
                  alignment: alignment,
                  minWidth: 0,
                  minHeight: 0,
                  maxWidth: width * _sourceWidth / _content.width,
                  maxHeight: height * _sourceHeight / _content.height,
                  child: Image.asset(
                    AssetImages.accraSkyline,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
