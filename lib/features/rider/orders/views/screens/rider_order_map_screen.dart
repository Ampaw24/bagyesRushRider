import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/constant/map_style.dart';
import 'package:delivery_boy/core/services/rider_places_service.dart';
import 'package:delivery_boy/core/utils/external_navigation_launcher.dart';
import 'package:delivery_boy/core/widgets/drag_handle.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';

enum _PointKind { pickup, pending, delivered, failed }

class _RoutePoint {
  final String label;
  final String? address;
  final _PointKind kind;
  LatLng? latLng;

  _RoutePoint({required this.label, required this.address, required this.kind});
}

/// Visual reference map for an order's pickup/delivery points — deliberately
/// not turn-by-turn (no route line, no rerouting, no voice guidance): that's
/// left to [ExternalNavigationLauncher], which hands the rider off to their
/// own Maps app. This screen just answers "where, roughly, am I headed" and
/// offers the same external-navigate action per point for when a rider wants
/// to skip the map entirely.
///
/// The backend sends orders as address strings only, so every marker here is
/// a best-effort geocode of that text — see [RiderPlacesService.geocodeAddress].
/// A point that fails to geocode still gets a working Navigate button, since
/// Maps geocodes free text itself.
class RiderOrderMapScreen extends StatefulWidget {
  final RiderMeOrderModel order;

  const RiderOrderMapScreen({super.key, required this.order});

  @override
  State<RiderOrderMapScreen> createState() => _RiderOrderMapScreenState();
}

class _RiderOrderMapScreenState extends State<RiderOrderMapScreen> {
  late final List<_RoutePoint> _points = _buildPoints(widget.order);
  bool _resolving = true;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _resolvePoints();
  }

  @override
  void dispose() {
    // GoogleMapController owns a platform-side MapView/method-channel pair
    // that outlives the widget unless released explicitly — the widget's
    // own PlatformView teardown does not call this for us.
    _mapController?.dispose();
    super.dispose();
  }

  List<_RoutePoint> _buildPoints(RiderMeOrderModel order) {
    final points = [
      _RoutePoint(
        label: 'Pickup',
        address: order.pickupAddress,
        kind: _PointKind.pickup,
      ),
    ];

    if (order.isMultiStop) {
      for (final stop in order.stops) {
        points.add(_RoutePoint(
          label: 'Stop ${stop.sequence ?? points.length}',
          address: stop.address,
          kind: stop.isDelivered
              ? _PointKind.delivered
              : stop.isFailed
                  ? _PointKind.failed
                  : _PointKind.pending,
        ));
      }
    } else {
      points.add(_RoutePoint(
        label: 'Delivery',
        address: order.dropoffAddress,
        kind: _PointKind.pending,
      ));
    }

    return points;
  }

  Future<void> _resolvePoints() async {
    await Future.wait(_points.map((point) async {
      final address = point.address;
      if (address == null || address.isEmpty) return;
      final result = await RiderPlacesService.geocodeAddress(address);
      if (result != null) point.latLng = LatLng(result.$1, result.$2);
    }));

    if (!mounted) return;
    setState(() => _resolving = false);
    _fitCamera();
  }

  Future<void> _fitCamera() async {
    final controller = _mapController;
    final resolved = _points.map((p) => p.latLng).whereType<LatLng>().toList();
    if (controller == null || resolved.isEmpty) return;

    if (resolved.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(resolved.first, 14),
      );
      return;
    }

    var minLat = resolved.first.latitude, maxLat = resolved.first.latitude;
    var minLng = resolved.first.longitude, maxLng = resolved.first.longitude;
    for (final p in resolved) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }
    await controller.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      64,
    ));
  }

  double _hueFor(_PointKind kind) => switch (kind) {
        _PointKind.pickup => BitmapDescriptor.hueGreen,
        _PointKind.pending => BitmapDescriptor.hueRed,
        _PointKind.delivered => BitmapDescriptor.hueAzure,
        _PointKind.failed => BitmapDescriptor.hueOrange,
      };

  Future<void> _navigate(_RoutePoint point) async {
    final ok = await ExternalNavigationLauncher.launch(
      address: point.address,
      latitude: point.latLng?.latitude,
      longitude: point.latLng?.longitude,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open a maps app")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final w = MediaQuery.sizeOf(context).width;
    final resolvedAny = _points.any((p) => p.latLng != null);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: Text(order.reference ?? '#${order.id}'),
        backgroundColor: AppColors.scaffold,
        elevation: 0,
      ),
      // Fixed 50/50 split — `Expanded(flex:)` rather than a MediaQuery
      // fraction, so it holds exactly half on any screen size/orientation
      // without a manual height computation.
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: _resolving
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : resolvedAny
                    ? GoogleMap(
                        style: kRiderMapStyle,
                        initialCameraPosition: CameraPosition(
                          target: _points
                                  .map((p) => p.latLng)
                                  .whereType<LatLng>()
                                  .firstOrNull ??
                              const LatLng(5.6037, -0.1870),
                          zoom: 13,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                          _fitCamera();
                        },
                        markers: _points
                            .where((p) => p.latLng != null)
                            .map((p) => Marker(
                                  markerId: MarkerId(p.label),
                                  position: p.latLng!,
                                  infoWindow: InfoWindow(
                                    title: p.label,
                                    snippet: p.address,
                                  ),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    _hueFor(p.kind),
                                  ),
                                ))
                            .toSet(),
                        // The rider's own live position — Google's stock blue
                        // dot, deliberately left un-styled so it stays
                        // instantly recognisable against the custom pickup/
                        // delivery pins above.
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: false,
                      )
                    : _MapUnavailable(w: w),
          ),
          Expanded(
            flex: 1,
            child:
                _RoutePointsPanel(points: _points, onNavigate: _navigate, w: w),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fallback when nothing geocoded (bad network, missing/rate-limited key) —
// the route list below still works since Navigate doesn't need a resolved pin.
// ─────────────────────────────────────────────────────────────────────────────

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
                fontFamily: 'Mukta',
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
                fontFamily: 'Mukta',
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

// ─────────────────────────────────────────────────────────────────────────────
// Route points panel — every pickup/stop with a one-tap external Navigate.
// ─────────────────────────────────────────────────────────────────────────────

class _RoutePointsPanel extends StatelessWidget {
  final List<_RoutePoint> points;
  final ValueChanged<_RoutePoint> onNavigate;
  final double w;

  const _RoutePointsPanel({
    required this.points,
    required this.onNavigate,
    required this.w,
  });

  Color _colorFor(_PointKind kind) => switch (kind) {
        _PointKind.pickup => AppColors.success,
        _PointKind.pending => AppColors.primary,
        _PointKind.delivered => AppColors.info,
        _PointKind.failed => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;

    // Rounded-top "sheet" resting on the map, matching this app's other
    // bottom sheets — fixed at half the screen (its parent `Expanded(flex:
    // 1)`), so the list scrolls internally instead of the sheet growing.
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          const DragHandle(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.05),
            child: Row(
              children: [
                Text(
                  'Route',
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: (w * 0.04).clamp(14.0, 17.0),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                w * 0.05,
                h * 0.012,
                w * 0.05,
                h * 0.02,
              ),
              itemCount: points.length,
              separatorBuilder: (_, __) => SizedBox(height: h * 0.012),
              itemBuilder: (_, i) {
                final point = points[i];
                final color = _colorFor(point.kind);
                return Row(
                  children: [
                    Container(
                      width: (w * 0.09).clamp(30.0, 36.0),
                      height: (w * 0.09).clamp(30.0, 36.0),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        HugeIcons.strokeRoundedLocation01,
                        size: (w * 0.045).clamp(16.0, 18.0),
                        color: color,
                      ),
                    ),
                    SizedBox(width: w * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            point.label,
                            style: TextStyle(
                              fontFamily: 'Mukta',
                              fontSize: (w * 0.032).clamp(11.0, 13.0),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textHint,
                            ),
                          ),
                          Text(
                            point.address?.isNotEmpty == true
                                ? point.address!
                                : '-',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Mukta',
                              fontSize: (w * 0.034).clamp(12.0, 14.0),
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: w * 0.02),
                    GestureDetector(
                      onTap: () => onNavigate(point),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: w * 0.03,
                          vertical: h * 0.009,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(w * 0.02),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              HugeIcons.strokeRoundedNavigator02,
                              size: (w * 0.036).clamp(13.0, 15.0),
                              color: Colors.white,
                            ),
                            SizedBox(width: w * 0.012),
                            Text(
                              'Navigate',
                              style: TextStyle(
                                fontFamily: 'Mukta',
                                fontSize: (w * 0.032).clamp(11.0, 13.0),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
