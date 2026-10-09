import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/constant/map_style.dart';
import 'package:delivery_boy/core/services/rider_directions_service.dart';
import 'package:delivery_boy/core/services/rider_location_service.dart';
import 'package:delivery_boy/core/services/rider_places_service.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';
import 'package:delivery_boy/core/utils/external_navigation_launcher.dart';
import 'package:delivery_boy/features/rider/chat/providers/rider_chat_thread_args.dart';
import 'package:delivery_boy/features/rider/chat/views/widgets/rider_chat_thread_sheet.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_delivery_stage.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_me_order_providers.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/order_map_sheet.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_me_order_status.dart';

/// Route overview for an order: the road route through every stop, drawn
/// with the brand marker, plus a compact trip sheet. Turn-by-turn guidance
/// is still handed off to the rider's own Maps app via
/// [ExternalNavigationLauncher].
///
/// Points use the server's coordinates when the order carries them; the rest
/// fall back to geocoding the address text. If the Routes API call fails,
/// the stops are joined with a dashed straight line instead.
class RiderOrderMapScreen extends ConsumerStatefulWidget {
  final RiderMeOrderModel order;

  const RiderOrderMapScreen({super.key, required this.order});

  @override
  ConsumerState<RiderOrderMapScreen> createState() =>
      _RiderOrderMapScreenState();
}

class _RiderOrderMapScreenState extends ConsumerState<RiderOrderMapScreen>
    with SingleTickerProviderStateMixin {
  static const _markerAsset = 'assets/images/mapmarker.png';
  static const _accra = LatLng(5.6037, -0.1870);

  // Sheet sizes as fractions of screen height. The map's bottom padding
  // follows the collapsed size so the fitted route stays above the sheet.
  static const _sheetMin = 0.22;
  static const _sheetInitial = 0.3;
  static const _sheetMax = 0.8;

  late final List<OrderMapStop> _stops = _buildStops(widget.order);
  GoogleMapController? _mapController;
  BitmapDescriptor? _markerIcon;
  RiderRoute? _route;
  bool _resolving = true;
  bool _routeLoading = true;
  // Google only draws the blue "my location" dot once permission is already
  // granted — it never asks itself — so it's switched on after [_ensureLocation].
  bool _locationGranted = false;

  // Draw-on reveal of the route: [_revealed] is the visible prefix of the
  // route, grown along its length (not by point count, which is uneven) so
  // the line traces at a steady speed.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..addListener(_onRevealTick);
  List<double> _cumulative = const [];
  List<LatLng> _revealed = const [];

  @override
  void initState() {
    super.initState();
    _loadMarkerIcon();
    _ensureLocation();
    _resolveStopsAndRoute();
  }

  @override
  void dispose() {
    _reveal.dispose();
    // GoogleMapController owns a platform-side MapView/method-channel pair
    // that outlives the widget unless released explicitly.
    _mapController?.dispose();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────────────────

  List<OrderMapStop> _buildStops(RiderMeOrderModel order) {
    final stops = [
      OrderMapStop(
        label: 'Pickup',
        address: order.pickupAddress,
        kind: OrderMapStopKind.pickup,
        latitude: order.pickupLatitude,
        longitude: order.pickupLongitude,
      ),
    ];

    if (order.isMultiStop) {
      for (final stop in order.stops) {
        stops.add(OrderMapStop(
          label: 'Stop ${stop.sequence ?? stops.length}',
          address: stop.address,
          latitude: stop.latitude,
          longitude: stop.longitude,
          kind: stop.isDelivered
              ? OrderMapStopKind.delivered
              : stop.isFailed
                  ? OrderMapStopKind.failed
                  : OrderMapStopKind.pending,
        ));
      }
    } else {
      stops.add(OrderMapStop(
        label: 'Drop-off',
        address: order.dropoffAddress,
        kind: OrderMapStopKind.pending,
        latitude: order.dropoffLatitude,
        longitude: order.dropoffLongitude,
      ));
    }
    return stops;
  }

  Future<void> _loadMarkerIcon() async {
    try {
      final icon = await BitmapDescriptor.asset(
        const ImageConfiguration(),
        _markerAsset,
        width: 40,
        height: 40,
      );
      if (mounted) setState(() => _markerIcon = icon);
    } catch (e, s) {
      appLogger.e('[OrderMap] marker asset failed to load',
          error: e, stackTrace: s);
    }
  }

  Future<void> _ensureLocation() async {
    final status = await RiderLocationService.ensurePermission();
    if (mounted && RiderLocationService.isGranted(status)) {
      setState(() => _locationGranted = true);
    }
  }

  Future<void> _resolveStopsAndRoute() async {
    await Future.wait(_stops.map((stop) async {
      if (stop.latLng != null) return; // Server coordinates — exact already.
      final address = stop.address;
      if (address == null || address.isEmpty) return;
      final result = await RiderPlacesService.geocodeAddress(address);
      if (result != null) stop.latLng = LatLng(result.$1, result.$2);
    }));
    if (!mounted) return;
    setState(() => _resolving = false);
    _fitCamera();

    final route = await RiderDirectionsService.route(_resolvedPoints);
    if (!mounted) return;
    setState(() {
      _route = route;
      _routeLoading = false;
    });
    if (route != null) _startReveal(route.points);
    // The road route can bulge past the straight-line bounds; refit to it.
    if (route != null) _fitCamera();
  }

  List<LatLng> get _resolvedPoints =>
      _stops.map((s) => s.latLng).whereType<LatLng>().toList();

  /// Where the rider should head now: the pickup until it's collected, then
  /// the first stop that's neither delivered nor failed.
  OrderMapStop? _nextStop(RiderDeliveryStage stage) {
    switch (stage) {
      case RiderDeliveryStage.notStarted:
      case RiderDeliveryStage.arrivedAtPickup:
        return _stops.first;
      case RiderDeliveryStage.pickedUp:
      case RiderDeliveryStage.arrivedAtDropoff:
        return _stops.skip(1).where((s) => !s.isDone).firstOrNull;
      case RiderDeliveryStage.delivered:
      case RiderDeliveryStage.closed:
        return null;
    }
  }

  // ── Map ─────────────────────────────────────────────────────────────────

  Future<void> _fitCamera() async {
    final controller = _mapController;
    final points = _route?.points ?? _resolvedPoints;
    if (controller == null || points.isEmpty) return;

    if (points.length == 1) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
      return;
    }

    var minLat = points.first.latitude, maxLat = minLat;
    var minLng = points.first.longitude, maxLng = minLng;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final w = MediaQuery.sizeOf(context).width;
    await controller.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      w * 0.15,
    ));
  }

  Set<Marker> get _markers => {
        for (final stop in _stops)
          if (stop.latLng != null)
            Marker(
              markerId: MarkerId(stop.label),
              position: stop.latLng!,
              icon: _markerIcon ?? BitmapDescriptor.defaultMarker,
              // Finished stops fade back so the remaining route stands out.
              alpha: stop.isDone ? 0.45 : 1,
              infoWindow: InfoWindow(title: stop.label, snippet: stop.address),
            ),
      };

  /// A dark route line over a wider white casing — the layered look of
  /// modern ride/delivery maps, readable over any road colour. Falls back to
  /// a dashed straight line when no road route is available.
  void _startReveal(List<LatLng> points) {
    if (points.length < 2) return;
    // Respect the OS "reduce motion" setting — show the full route at once.
    if (MediaQuery.of(context).disableAnimations) {
      setState(() => _revealed = points);
      return;
    }
    final cumulative = <double>[0];
    for (var i = 1; i < points.length; i++) {
      cumulative.add(cumulative.last + _distance(points[i - 1], points[i]));
    }
    _cumulative = cumulative;
    _reveal.forward(from: 0);
  }

  void _onRevealTick() {
    final points = _route?.points;
    if (points == null || _cumulative.isEmpty) return;
    final target =
        Curves.easeInOutCubic.transform(_reveal.value) * _cumulative.last;

    // Last fully-covered vertex, then an interpolated tip on the next segment.
    var i = 1;
    while (i < points.length && _cumulative[i] <= target) {
      i++;
    }
    final visible = points.sublist(0, i);
    if (i < points.length) {
      final segment = _cumulative[i] - _cumulative[i - 1];
      final t = segment == 0 ? 0.0 : (target - _cumulative[i - 1]) / segment;
      final a = points[i - 1], b = points[i];
      visible.add(LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      ));
    }
    setState(() => _revealed = visible);
  }

  /// Equirectangular approximation — plenty for relative lengths within a
  /// city-scale route, and far cheaper than haversine per frame.
  static double _distance(LatLng a, LatLng b) {
    final meanLat = (a.latitude + b.latitude) / 2 * math.pi / 180;
    final dx = (b.longitude - a.longitude) * math.cos(meanLat);
    final dy = b.latitude - a.latitude;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// A slim brand-red route over a thin white casing, drawn on progressively
  /// by [_reveal]. Falls back to a dashed straight line when no road route
  /// is available.
  Set<Polyline> get _polylines {
    final route = _route;
    if (route != null && route.points.length > 1) {
      if (_revealed.length < 2) return const {};
      return {
        Polyline(
          polylineId: const PolylineId('route_casing'),
          points: _revealed,
          color: Colors.white,
          width: 6,
          zIndex: 1,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
        Polyline(
          polylineId: const PolylineId('route'),
          points: _revealed,
          color: AppColors.primary,
          width: 4,
          zIndex: 2,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };
    }

    final points = _resolvedPoints;
    if (_routeLoading || points.length < 2) return const {};
    return {
      Polyline(
        polylineId: const PolylineId('route_fallback'),
        points: points,
        color: AppColors.primary,
        width: 3,
        geodesic: true,
        patterns: [PatternItem.dash(18), PatternItem.gap(10)],
      ),
    };
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _navigate(OrderMapStop stop) async {
    final ok = await ExternalNavigationLauncher.launch(
      address: stop.address,
      latitude: stop.latLng?.latitude,
      longitude: stop.latLng?.longitude,
    );
    if (!ok && mounted) {
      final hasTarget =
          stop.latLng != null || (stop.address?.isNotEmpty ?? false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(hasTarget
            ? "Couldn't open a maps app"
            : 'No location for ${stop.label.toLowerCase()} yet'),
      ));
    }
  }

  Future<void> _callCustomer() async {
    final phone = widget.order.customerPhone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openChat() {
    final order = widget.order;
    RiderChatThreadSheet.show(
      context,
      args: RiderChatThreadArgs(
        orderId: order.id,
        peerName: order.customerName,
        peerPhone: order.customerPhone,
      ),
    );
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final stage = ref.watch(riderMeOrdersProvider).stageFor(order);
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: Stack(
        children: [
          Positioned.fill(
            child: _resolving
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _resolvedPoints.isEmpty
                    ? Padding(
                        padding: EdgeInsets.only(bottom: size.height * _sheetInitial),
                        child: _MapUnavailable(w: w),
                      )
                    : GoogleMap(
                        style: kRiderMapStyle,
                        initialCameraPosition: CameraPosition(
                          target: _resolvedPoints.firstOrNull ?? _accra,
                          zoom: 13,
                        ),
                        padding: EdgeInsets.only(
                          top: topInset + w * 0.12,
                          bottom: size.height * _sheetInitial,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                          _fitCamera();
                        },
                        markers: _markers,
                        polylines: _polylines,
                        // Rider's live position — Google's stock blue dot,
                        // never a custom marker; the brand pin is only for
                        // the order's pickup and drop-off points.
                        myLocationEnabled: _locationGranted,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: false,
                      ),
          ),

          // ── Floating controls ──────────────────────────────────────────
          Positioned(
            top: topInset + w * 0.03,
            left: w * 0.04,
            right: w * 0.04,
            child: Row(
              children: [
                _MapFab(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  tooltip: 'Back',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const Spacer(),
                if (_resolvedPoints.isNotEmpty)
                  _MapFab(
                    icon: HugeIcons.strokeRoundedRoute01,
                    tooltip: 'Show whole route',
                    onTap: _fitCamera,
                  ),
              ],
            ),
          ),

          // ── Trip sheet ─────────────────────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: _sheetInitial,
            minChildSize: _sheetMin,
            maxChildSize: _sheetMax,
            snap: true,
            snapSizes: const [_sheetInitial],
            builder: (_, scrollController) => OrderMapSheet(
              scrollController: scrollController,
              reference: order.reference ?? '#${order.id}',
              amount: order.amountFormatted,
              statusLabel: riderMeOrderStatusLabel(order.status),
              statusColor: riderMeOrderStatusColor(order.status),
              route: _route,
              routeLoading: _routeLoading,
              stops: _stops,
              nextStop: _nextStop(stage),
              customerName: order.customerName,
              customerPhone: order.customerPhone,
              onNavigate: _navigate,
              onCall: _callCustomer,
              onChat: _openChat,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapFab({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final size = (w * 0.12).clamp(48.0, 56.0);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: Colors.black26,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.42, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Shown when no point could be placed (bad network, missing/rate-limited
/// key) — the sheet's per-stop Navigate still works, since Maps geocodes
/// free text itself.
class _MapUnavailable extends StatelessWidget {
  final double w;
  const _MapUnavailable({required this.w});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              HugeIcons.strokeRoundedMapsLocation01,
              size: (w * 0.12).clamp(40.0, 56.0),
              color: AppColors.textHint,
            ),
            SizedBox(height: w * 0.03),
            Text(
              'Map preview unavailable',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: (w * 0.038).clamp(13.0, 16.0),
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: w * 0.01),
            Text(
              'Use Navigate below to get directions',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: (w * 0.032).clamp(11.0, 13.0),
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
