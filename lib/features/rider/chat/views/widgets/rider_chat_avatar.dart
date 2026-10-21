import 'package:gopady_rider/constant/app_tokens.dart';
import 'package:flutter/material.dart';

import 'package:gopady_rider/constant/app_theme.dart';
import 'package:gopady_rider/core/utils/initials.dart';

/// Circular participant avatar: the photo when [photoUrl] is known and loads,
/// the name's initials otherwise (no URL, still loading, or a failed fetch) —
/// never an empty circle.
class RiderChatAvatar extends StatelessWidget {
  const RiderChatAvatar({
    super.key,
    required this.name,
    required this.size,
    this.photoUrl,
  });

  final String name;
  final double size;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim() ?? '';
    final initials = ColoredBox(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          initialsOf(name),
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );

    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: url.isEmpty
            ? initials
            : Image.network(
                url,
                fit: BoxFit.cover,
                cacheWidth:
                    (size * MediaQuery.devicePixelRatioOf(context)).round(),
                errorBuilder: (_, __, ___) => initials,
                frameBuilder: (_, image, frame, loadedSync) {
                  if (loadedSync) return image;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      initials,
                      AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(milliseconds: 250),
                        child: image,
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
