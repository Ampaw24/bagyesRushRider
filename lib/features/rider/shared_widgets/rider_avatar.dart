import 'package:flutter/material.dart';

import 'package:delivery_boy/constant/app_theme.dart';

/// Circular profile photo that shows [placeholder] — usually the rider's
/// initials — when there is no [imageUrl], while the photo loads, and if it
/// fails to load.
///
/// Use this rather than `CircleAvatar(backgroundImage: NetworkImage(...))`,
/// which renders an empty circle (and logs an exception) for a broken URL.
class RiderAvatar extends StatelessWidget {
  const RiderAvatar({
    super.key,
    required this.radius,
    required this.placeholder,
    this.imageUrl,
    this.backgroundColor = AppColors.primary,
  });

  final double radius;
  final String? imageUrl;
  final Widget placeholder;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final fallback = Center(child: placeholder);
    final url = imageUrl;

    return SizedBox.square(
      dimension: diameter,
      child: ClipOval(
        child: ColoredBox(
          color: backgroundColor,
          child: url == null
              ? fallback
              : Image.network(
                  url,
                  width: diameter,
                  height: diameter,
                  fit: BoxFit.cover,
                  // Decode at display size rather than the photo's full
                  // camera resolution.
                  cacheWidth:
                      (diameter * MediaQuery.devicePixelRatioOf(context))
                          .round(),
                  frameBuilder: (context, child, frame, wasSyncLoaded) =>
                      wasSyncLoaded || frame != null ? child : fallback,
                  errorBuilder: (context, error, stackTrace) => fallback,
                ),
        ),
      ),
    );
  }
}
