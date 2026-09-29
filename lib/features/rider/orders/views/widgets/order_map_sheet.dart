import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/services/rider_directions_service.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_order_detail_sections.dart';

enum OrderMapStopKind { pickup, pending, delivered, failed }

/// One point on the order map. [latLng] starts as the server's coordinates
/// and may be filled in later by geocoding the address.
class OrderMapStop {
  final String label;
  final String? address;
  final OrderMapStopKind kind;
  LatLng? latLng;

  OrderMapStop({
    required this.label,
    required this.address,
    required this.kind,
    double? latitude,
    double? longitude,
  }) : latLng = (latitude != null && longitude != null)
            ? LatLng(latitude, longitude)
            : null;

  bool get isDone =>
      kind == OrderMapStopKind.delivered || kind == OrderMapStopKind.failed;
}

double _font(double w, double factor, double min, double max) =>
    (w * factor).clamp(min, max);

/// Content of the order map's bottom sheet: trip summary first (what fits at
/// the collapsed height), then customer and the full stop list on drag-up.
class OrderMapSheet extends StatelessWidget {
  final ScrollController scrollController;
  final String reference;
  final String amount;
  final String statusLabel;
  final Color statusColor;
  final RiderRoute? route;
  final bool routeLoading;
  final List<OrderMapStop> stops;
  final OrderMapStop? nextStop;
  final String? customerName;
  final String? customerPhone;
  final ValueChanged<OrderMapStop> onNavigate;
  final VoidCallback onCall;
  final VoidCallback onChat;

  const OrderMapSheet({
    super.key,
    required this.scrollController,
    required this.reference,
    required this.amount,
    required this.statusLabel,
    required this.statusColor,
    required this.route,
    required this.routeLoading,
    required this.stops,
    required this.nextStop,
    required this.customerName,
    required this.customerPhone,
    required this.onNavigate,
    required this.onCall,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final gutter = w * 0.05;
    final next = nextStop;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, w * 0.04),
              children: [
                const _Handle(),
                _TripSummary(
                  route: route,
                  loading: routeLoading,
                  statusLabel: statusLabel,
                  statusColor: statusColor,
                ),
                SizedBox(height: w * 0.012),
                Text(
                  [reference, if (amount.isNotEmpty) amount].join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: _font(w, 0.034, 12, 15),
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: w * 0.05),
                const OrderSectionLabel(title: 'Customer'),
                OrderCustomerTile(
                  name: customerName,
                  phone: customerPhone,
                  onCall: onCall,
                  onChat: onChat,
                ),
                SizedBox(height: w * 0.05),
                const OrderSectionLabel(title: 'Stops'),
                _StopList(stops: stops, next: next, onNavigate: onNavigate),
              ],
            ),
          ),
          if (next != null)
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              padding: EdgeInsets.fromLTRB(gutter, w * 0.03, gutter, w * 0.03),
              child: SafeArea(
                top: false,
                child: AppGradientButton(
                  label: 'Navigate to ${next.label.toLowerCase()}',
                  height: (w * 0.12).clamp(46.0, 56.0),
                  onPressed: () => onNavigate(next),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: w * 0.03),
        width: w * 0.1,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _TripSummary extends StatelessWidget {
  final RiderRoute? route;
  final bool loading;
  final String statusLabel;
  final Color statusColor;

  const _TripSummary({
    required this.route,
    required this.loading,
    required this.statusLabel,
    required this.statusColor,
  });

  static String formatDuration(Duration d) {
    final minutes = (d.inSeconds / 60).ceil();
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60, m = minutes % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }

  static String formatDistance(int meters) => meters < 1000
      ? '$meters m'
      : '${(meters / 1000).toStringAsFixed(1)} km';

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final r = route;

    final Widget headline;
    if (r != null) {
      headline = Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: formatDuration(r.duration),
              style: TextStyle(
                fontSize: _font(w, 0.06, 20, 26),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            TextSpan(
              text: '   ${formatDistance(r.distanceMeters)}',
              style: TextStyle(
                fontSize: _font(w, 0.038, 14, 17),
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        style: const TextStyle(fontFamily: 'Roboto'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      headline = Text(
        loading ? 'Finding route…' : 'Route overview',
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: _font(w, 0.05, 18, 22),
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: headline),
        SizedBox(width: w * 0.02),
        OrderStatusPill(label: statusLabel, color: statusColor),
      ],
    );
  }
}

class _StopList extends StatelessWidget {
  final List<OrderMapStop> stops;
  final OrderMapStop? next;
  final ValueChanged<OrderMapStop> onNavigate;

  const _StopList({
    required this.stops,
    required this.next,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return OrderSurface(
      child: Column(
        children: [
          for (var i = 0; i < stops.length; i++)
            _StopRow(
              stop: stops[i],
              isNext: identical(stops[i], next),
              showConnector: i < stops.length - 1,
              onNavigate: () => onNavigate(stops[i]),
            ),
        ],
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  final OrderMapStop stop;
  final bool isNext;
  final bool showConnector;
  final VoidCallback onNavigate;

  const _StopRow({
    required this.stop,
    required this.isNext,
    required this.showConnector,
    required this.onNavigate,
  });

  String? get _statusText => switch (stop.kind) {
        OrderMapStopKind.delivered => 'Delivered',
        OrderMapStopKind.failed => 'Failed',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final dot = w * 0.03;
    final dotColor = stop.isDone
        ? AppColors.textHint
        : isNext
            ? AppColors.primary
            : AppColors.textPrimary;
    final status = _statusText;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: w * 0.05,
            child: Column(
              children: [
                SizedBox(height: w * 0.012),
                Container(
                  width: dot,
                  height: dot,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isNext ? dotColor : Colors.white,
                    border: Border.all(color: dotColor, width: dot * 0.25),
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
              padding: EdgeInsets.only(bottom: showConnector ? w * 0.035 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [stop.label, if (status != null) status, if (isNext) 'Next']
                        .join(' · '),
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: _font(w, 0.03, 11, 13),
                      fontWeight: FontWeight.w500,
                      color: isNext ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: w * 0.006),
                  Text(
                    (stop.address?.isNotEmpty ?? false)
                        ? stop.address!
                        : 'Address not provided',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: _font(w, 0.035, 13, 15),
                      fontWeight: FontWeight.w600,
                      color: stop.isDone
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!stop.isDone)
            Align(
              alignment: Alignment.topCenter,
              child: IconButton(
                onPressed: onNavigate,
                tooltip: 'Navigate to ${stop.label}',
                icon: Icon(
                  HugeIcons.strokeRoundedNavigator02,
                  size: w * 0.05,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
