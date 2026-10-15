import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:delivery_boy/constant/app_theme.dart';

/// Surface shared by the order and offer cards: flat white, hairline border,
/// moderate radius, whole card tappable with a slight press-in scale.
/// [header], when given, spans the card's full width above the padded body
/// (the order card's status band).
class RiderOrderCardShell extends StatefulWidget {
  final VoidCallback onTap;
  final String semanticLabel;
  final Widget? header;
  final List<Widget> children;

  const RiderOrderCardShell({
    super.key,
    required this.onTap,
    required this.semanticLabel,
    this.header,
    required this.children,
  });

  @override
  State<RiderOrderCardShell> createState() => _RiderOrderCardShellState();
}

class _RiderOrderCardShellState extends State<RiderOrderCardShell> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular((w * 0.035).clamp(10.0, 16.0)),
      side: const BorderSide(color: AppColors.border),
    );
    final header = widget.header;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: AnimatedScale(
        scale: _pressed && !reduceMotion ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: AppColors.card,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (header != null) header,
                Padding(
                  padding: EdgeInsets.all(w * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.children,
                  ),
                ),
              ],
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

/// Full-width order action, on the cards and in the order sheet. [outlined]
/// gives the secondary style used for e.g. Decline next to a primary Accept
/// ([destructive] tints it red, e.g. failing a stop); [trailingIcon] follows
/// the label, e.g. an arrow on a button that moves the delivery forward.
class RiderOrderCardButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool destructive;
  final bool isLoading;
  final IconData? trailingIcon;

  /// For a screen's main action, which should stand taller than a card's.
  final double? minHeight;

  const RiderOrderCardButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.destructive = false,
    this.isLoading = false,
    this.trailingIcon,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(w * 0.025),
    );
    final padding = EdgeInsets.symmetric(vertical: w * 0.03);
    final fontSize = (w * 0.036).clamp(13.0, 16.0);
    final textStyle = TextStyle(
      fontFamily: 'Roboto',
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
    );
    final icon = trailingIcon;
    final child = isLoading
        ? SizedBox.square(
            dimension: w * 0.045,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: outlined ? AppColors.textPrimary : AppColors.onPrimary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (icon != null) ...[
                SizedBox(width: w * 0.015),
                Icon(icon, size: fontSize * 1.15),
              ],
            ],
          );

    final minimumSize = Size.fromHeight(minHeight ?? 0);

    if (outlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: minimumSize,
          padding: padding,
          shape: shape,
          textStyle: textStyle,
          foregroundColor:
              destructive ? AppColors.error : AppColors.textPrimary,
          side: BorderSide(
            color: destructive ? AppColors.error : AppColors.border,
          ),
        ),
        child: child,
      );
    }
    final tap = onPressed;
    return FilledButton(
      // A light tap haptic on the primary action, like the app's other main
      // buttons.
      onPressed: isLoading || tap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              tap();
            },
      style: FilledButton.styleFrom(
        minimumSize: minimumSize,
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
