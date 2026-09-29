import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:hugeicons/hugeicons.dart';

/// Presentational building blocks for `RiderMeOrderDetailSheet`. They hold no
/// order state and trigger nothing themselves — every action is a callback,
/// so the sheet stays the single owner of order logic.

const double _kRadius = 12;

double _font(double w, double factor, double min, double max) =>
    (w * factor).clamp(min, max);

// ── Header ────────────────────────────────────────────────────────────────

class OrderSheetHeader extends StatelessWidget {
  final String reference;
  final String statusLabel;
  final Color statusColor;
  final String amount;
  final int? stopCount;

  const OrderSheetHeader({
    super.key,
    required this.reference,
    required this.statusLabel,
    required this.statusColor,
    required this.amount,
    this.stopCount,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reference,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: _font(w, 0.05, 17, 22),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: w * 0.015),
              Wrap(
                spacing: w * 0.02,
                runSpacing: w * 0.01,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OrderStatusPill(label: statusLabel, color: statusColor),
                  if (stopCount != null)
                    Text(
                      '$stopCount stops',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: _font(w, 0.032, 12, 14),
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (amount.isNotEmpty) ...[
          SizedBox(width: w * 0.03),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Order total',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: _font(w, 0.029, 11, 13),
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: w * 0.008),
              Text(
                amount,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: _font(w, 0.045, 16, 20),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class OrderStatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const OrderStatusPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: w * 0.008),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(_kRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: w * 0.015,
            height: w * 0.015,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: w * 0.015),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: _font(w, 0.03, 11, 13),
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────

class OrderSectionLabel extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const OrderSectionLabel({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.only(bottom: w * 0.02),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: _font(w, 0.034, 13, 15),
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Compact text-only action for a section header ("View map").
class OrderSectionAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const OrderSectionAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: _font(w, 0.04, 14, 18)),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.symmetric(horizontal: w * 0.02),
        textStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: _font(w, 0.033, 12, 14),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Surface ───────────────────────────────────────────────────────────────

/// Flat bordered surface — the one grouping container used in the sheet.
class OrderSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const OrderSurface({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

// ── Route ─────────────────────────────────────────────────────────────────

class OrderRouteTimeline extends StatelessWidget {
  final String? pickupAddress;
  final String? dropoffAddress;
  final String dropoffLabel;
  final VoidCallback onNavigatePickup;
  final VoidCallback onNavigateDropoff;

  const OrderRouteTimeline({
    super.key,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.dropoffLabel,
    required this.onNavigatePickup,
    required this.onNavigateDropoff,
  });

  @override
  Widget build(BuildContext context) {
    return OrderSurface(
      child: Column(
        children: [
          _RouteStop(
            label: 'Pickup',
            address: pickupAddress ?? 'Pickup not provided',
            marker: _RouteMarker.origin,
            showConnector: true,
            onNavigate: onNavigatePickup,
          ),
          _RouteStop(
            label: dropoffLabel,
            address: dropoffAddress ?? 'Drop-off not provided',
            marker: _RouteMarker.destination,
            showConnector: false,
            onNavigate: onNavigateDropoff,
          ),
        ],
      ),
    );
  }
}

enum _RouteMarker { origin, destination }

class _RouteStop extends StatelessWidget {
  final String label;
  final String address;
  final _RouteMarker marker;
  final bool showConnector;
  final VoidCallback onNavigate;

  const _RouteStop({
    required this.label,
    required this.address,
    required this.marker,
    required this.showConnector,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final markerSize = w * 0.035;
    final isOrigin = marker == _RouteMarker.origin;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Marker + connector line down to the next stop.
          SizedBox(
            width: w * 0.06,
            child: Column(
              children: [
                SizedBox(height: w * 0.012),
                Container(
                  width: markerSize,
                  height: markerSize,
                  decoration: BoxDecoration(
                    color: isOrigin ? Colors.white : AppColors.primary,
                    shape: isOrigin ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius:
                        isOrigin ? null : BorderRadius.circular(markerSize / 4),
                    border: Border.all(
                      color: isOrigin ? AppColors.textPrimary : AppColors.primary,
                      width: markerSize * 0.25,
                    ),
                  ),
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: EdgeInsets.symmetric(vertical: w * 0.01),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showConnector ? w * 0.045 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: _font(w, 0.03, 11, 13),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: w * 0.008),
                  Text(
                    address,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: _font(w, 0.037, 14, 16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: w * 0.02),
          Align(
            alignment: Alignment.topCenter,
            child: _RoundIconButton(
              icon: HugeIcons.strokeRoundedNavigator02,
              tooltip: 'Navigate to $label',
              onTap: onNavigate,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Customer ──────────────────────────────────────────────────────────────

class OrderCustomerTile extends StatelessWidget {
  final String? name;
  final String? phone;
  final VoidCallback? onCall;
  final VoidCallback onChat;

  const OrderCustomerTile({
    super.key,
    required this.name,
    required this.phone,
    required this.onCall,
    required this.onChat,
  });

  String get _initials {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2);
    final letters = parts.map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final hasName = name?.trim().isNotEmpty ?? false;
    final hasPhone = phone?.trim().isNotEmpty ?? false;

    return OrderSurface(
      child: Row(
        children: [
          CircleAvatar(
            radius: w * 0.055,
            backgroundColor: AppColors.surfaceVariant,
            child: Text(
              _initials,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: _font(w, 0.036, 13, 16),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasName ? name!.trim() : 'Customer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: _font(w, 0.038, 14, 17),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: w * 0.005),
                Text(
                  hasPhone ? phone!.trim() : 'No phone number',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: _font(w, 0.033, 12, 14),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: w * 0.02),
          _RoundIconButton(
            icon: HugeIcons.strokeRoundedBubbleChat,
            tooltip: 'Chat with customer',
            onTap: onChat,
          ),
          SizedBox(width: w * 0.02),
          _RoundIconButton(
            icon: HugeIcons.strokeRoundedCall,
            tooltip: 'Call customer',
            onTap: hasPhone ? onCall : null,
          ),
        ],
      ),
    );
  }
}

// ── Trouble actions ───────────────────────────────────────────────────────

class OrderIssueAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  const OrderIssueAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });
}

/// Grouped list of "something went wrong" actions — secondary to the pinned
/// primary step, so they read as settings-style rows rather than buttons.
class OrderIssueList extends StatelessWidget {
  final List<OrderIssueAction> actions;

  const OrderIssueList({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return OrderSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: w * 0.15,
                color: AppColors.divider,
              ),
            _IssueRow(action: actions[i]),
          ],
        ],
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  final OrderIssueAction action;

  const _IssueRow({required this.action});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final tint = action.destructive ? AppColors.error : AppColors.textPrimary;
    final enabled = action.onTap != null;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(_kRadius),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.04,
            vertical: w * 0.035,
          ),
          child: Row(
            children: [
              Container(
                width: w * 0.08,
                height: w * 0.08,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(_kRadius * 0.75),
                ),
                child: Icon(action.icon, size: w * 0.045, color: tint),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: _font(w, 0.036, 14, 16),
                        fontWeight: FontWeight.w600,
                        color: tint,
                      ),
                    ),
                    SizedBox(height: w * 0.004),
                    Text(
                      action.subtitle,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: _font(w, 0.03, 11, 13),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                HugeIcons.strokeRoundedArrowRight01,
                size: w * 0.045,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    // Never below the 48dp minimum touch target, whatever the screen width.
    final size = (w * 0.12).clamp(48.0, 56.0);
    final enabled = onTap != null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surfaceVariant,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onTap!();
                }
              : null,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              size: size * 0.42,
              color: enabled ? AppColors.primary : AppColors.textHint,
            ),
          ),
        ),
      ),
    );
  }
}
