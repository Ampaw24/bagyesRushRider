import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/app_theme.dart';

/// Surface shared by the order and offer cards: flat white, hairline border,
/// moderate radius, whole card tappable.
class RiderOrderCardShell extends StatelessWidget {
  final VoidCallback onTap;
  final String semanticLabel;
  final List<Widget> children;

  const RiderOrderCardShell({
    super.key,
    required this.onTap,
    required this.semanticLabel,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(w * 0.035),
      side: const BorderSide(color: AppColors.border),
    );

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.white,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(w * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// Small tinted label — order status, distance, and similar metadata.
class RiderOrderChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const RiderOrderChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.022, vertical: w * 0.01),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(w * 0.015),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: w * 0.032, color: color),
            SizedBox(width: w * 0.012),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: w * 0.029,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width card action. [outlined] gives the secondary style used for
/// e.g. Decline next to a primary Accept.
class RiderOrderCardButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool isLoading;

  const RiderOrderCardButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(w * 0.025),
    );
    final padding = EdgeInsets.symmetric(vertical: w * 0.03);
    final textStyle = TextStyle(
      fontFamily: 'Roboto',
      fontSize: w * 0.036,
      fontWeight: FontWeight.w600,
    );
    final child = isLoading
        ? SizedBox.square(
            dimension: w * 0.045,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);

    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(0),
          padding: padding,
          shape: shape,
          textStyle: textStyle,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
        ),
        child: child,
      );
    }
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(0),
        padding: padding,
        shape: shape,
        textStyle: textStyle,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
      ),
      child: child,
    );
  }
}
