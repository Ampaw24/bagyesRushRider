import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:delivery_boy/constant/asset_images.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_order_model.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_orders_providers.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_order_detail_sheet.dart';
import 'package:delivery_boy/features/rider/tracking/providers/rider_tracking_providers.dart';
import 'package:hugeicons/hugeicons.dart';

// Google Maps API key — move to env/config before production
const _kGoogleMapsApiKey = 'AIzaSyA6QwaWqE4gtpQq4tTXGVIxLmeEeVKhYUc';

enum _TripType { pickup, dropoff }

class RiderMapScreen extends ConsumerStatefulWidget {
  const RiderMapScreen({super.key});

  @override
  ConsumerState<RiderMapScreen> createState() => _RiderMapScreenState();
}

class _RiderMapScreenState extends ConsumerState<RiderMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _polylineCoordinates = [];
  _TripType? _tripType;
  LatLng _destination = const LatLng(0, 0);
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTrip());
  }

  RiderOrderModel? get _order =>
      ref.read(activeOrdersProvider).selectedOrder;

  void _loadTrip() {
    final order = _order;
    if (order == null) return;

    switch (order.tripType) {
      case 'PICKUP':
        _tripType = _TripType.pickup;
        _destination = order.pickupLocationCoords != null
            ? LatLng(order.pickupLocationCoords!.latitude,
                order.pickupLocationCoords!.longitude)
            : const LatLng(0, 0);
        break;
      case 'DESTINATION':
        _tripType = _TripType.dropoff;
        _destination = order.deliveryLocationCoords != null
            ? LatLng(order.deliveryLocationCoords!.latitude,
                order.deliveryLocationCoords!.longitude)
            : const LatLng(0, 0);
        break;
      default:
        _tripType = null;
    }

    if (_tripType != null) {
      ref
          .read(riderTrackingProvider.notifier)
          .startTracking(orderId: order.id);
    }
  }

  String get _tripLabel {
    switch (_tripType) {
      case _TripType.pickup:
        return 'Current trip: Pickup';
      default:
        return 'Current trip: Destination';
    }
  }

  Future<void> _drawPolyline(LatLng origin) async {
    _polylineCoordinates = [];
    final polylinePoints = PolylinePoints();
    final result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: _kGoogleMapsApiKey,
      request: PolylineRequest(
        origin: PointLatLng(origin.latitude, origin.longitude),
        destination:
            PointLatLng(_destination.latitude, _destination.longitude),
        mode: TravelMode.driving,
      ),
    );
    if (result.points.isNotEmpty) {
      for (final point in result.points) {
        _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.red,
            points: _polylineCoordinates,
          ),
        };
      });
    }
  }

  void _updateMarkers(LatLng riderPos) {
    final order = _order;
    setState(() {
      _markers = {
        Marker(
          markerId: MarkerId(riderPos.toString()),
          position: riderPos,
          infoWindow: InfoWindow(
            title: 'Your Location',
            snippet: order?.pickUpLocation ?? '',
          ),
        ),
        Marker(
          markerId: MarkerId(_destination.toString()),
          position: _destination,
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: order?.deliveryLocation ?? '',
          ),
        ),
      };
      _mapController?.animateCamera(
          CameraUpdate.newLatLng(_destination));
    });
    _drawPolyline(riderPos);
  }

  Future<void> _openPhone() async {
    final phone = _order?.customer?.phone ?? '';
    if (phone.isEmpty) return;
    try {
      await launchUrl(Uri(scheme: 'tel', path: phone));
    } catch (_) {}
  }

  Future<void> _finishTrip() async {
    final order = _order;
    if (order == null) return;

    setState(() => _loading = true);
    ref.read(riderTrackingProvider.notifier).stopTracking();

    final ok = await ref
        .read(activeOrdersProvider.notifier)
        .finishTrip({'orderId': order.id});

    setState(() => _loading = false);

    if (!mounted) return;
    if (ok) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Congratulations!'),
          content: const Text('Delivery completed successfully'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/dashboard');
              },
              child: const Text('Okay'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to finish trip. Try again.')),
      );
    }
  }

  Future<void> _updateTrip(_TripType tripType) async {
    final order = _order;
    if (order == null) return;

    setState(() => _loading = true);
    final ok = await ref.read(activeOrdersProvider.notifier).setTrip({
      'orderId': order.id,
      'trip': tripType == _TripType.pickup ? 'PICKUP' : 'DESTINATION',
    });
    setState(() => _loading = false);

    if (!mounted) return;
    if (ok) {
      setState(() {
        _tripType = tripType;
        _destination = tripType == _TripType.pickup
            ? (order.pickupLocationCoords != null
                ? LatLng(order.pickupLocationCoords!.latitude,
                    order.pickupLocationCoords!.longitude)
                : const LatLng(0, 0))
            : (order.deliveryLocationCoords != null
                ? LatLng(order.deliveryLocationCoords!.latitude,
                    order.deliveryLocationCoords!.longitude)
                : const LatLng(0, 0));
      });
      final riderPos = ref.read(riderTrackingProvider).position;
      _updateMarkers(riderPos);
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Oops! Something went wrong'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Okay'),
            ),
          ],
        ),
      );
    }
  }

  void _showOrderDetail() {
    final order = _order;
    if (order == null) return;
    final width = MediaQuery.sizeOf(context).width;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Wrap(
          children: [
            RiderOrderDetailSheet(
              order: order,
              actionButton: Column(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _updateTrip(_TripType.pickup);
                    },
                    child: Container(
                      width: width,
                      alignment: Alignment.center,
                      margin: EdgeInsets.all(fixPadding),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 0.5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pickup',
                              style: TextStyle(color: Colors.black)),
                          Icon(
                            HugeIcons.strokeRoundedCheckmarkCircle01,
                            color: _tripType == _TripType.pickup
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _updateTrip(_TripType.dropoff);
                    },
                    child: Container(
                      width: width,
                      alignment: Alignment.center,
                      margin: EdgeInsets.all(fixPadding),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 0.5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Destination',
                              style: TextStyle(color: Colors.black)),
                          Icon(
                            HugeIcons.strokeRoundedCheckmarkCircle01,
                            color: _tripType == _TripType.dropoff
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: width,
                      alignment: Alignment.center,
                      margin: EdgeInsets.all(fixPadding),
                      padding: EdgeInsets.all(fixPadding),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text('Close', style: wbuttonWhiteTextStyle),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final trackingState = ref.watch(riderTrackingProvider);
    final riderPos = trackingState.position;

    // Update markers whenever position changes
    ref.listen<RiderTrackingState>(riderTrackingProvider, (prev, next) {
      if (prev?.position != next.position) {
        _mapController?.animateCamera(
            CameraUpdate.newLatLng(next.position));
        _updateMarkers(next.position);
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text('Map', style: headingStyle),
          leading: IconButton(
            icon: Icon(HugeIcons.strokeRoundedArrowLeft01, color: blackColor),
            onPressed: () => context.pop(),
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 150),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: 'order_detail',
                onPressed: _showOrderDetail,
                backgroundColor: whiteColor,
                child: Icon(HugeIcons.strokeRoundedClipboard, color: primaryColor),
              ),
              heightSpace,
              FloatingActionButton(
                heroTag: 'call',
                onPressed: _openPhone,
                backgroundColor: whiteColor,
                child: Icon(HugeIcons.strokeRoundedCall, color: primaryColor),
              ),
            ],
          ),
        ),
        bottomSheet: Wrap(
          children: [
            Material(
              elevation: 7,
              child: Container(
                padding: EdgeInsets.all(fixPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            image: const DecorationImage(
                              image: AssetImage(AssetImages.deliveryBoy),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        widthSpace,
                        SizedBox(
                          width: width - (fixPadding * 2 + 80 + 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _order?.customer?.name ?? '',
                                style: headingStyle,
                              ),
                              heightSpace,
                              Text(_tripLabel, style: listItemSubTitleStyle),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: width,
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: _loading ? null : _finishTrip,
                        child: Container(
                          height: 40,
                          width: 100,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: _loading
                              ? const SpinKitCircle(
                                  color: Colors.white, size: 10)
                              : Text('Finish', style: wbuttonWhiteTextStyle),
                        ),
                      ),
                    ),
                    heightSpace,
                  ],
                ),
              ),
            ),
          ],
        ),
        body: GoogleMap(
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          mapType: MapType.normal,
          zoomGesturesEnabled: true,
          zoomControlsEnabled: false,
          polylines: _polylines,
          onMapCreated: (controller) => _mapController = controller,
          initialCameraPosition: CameraPosition(target: riderPos, zoom: 10),
        ),
      ),
    );
  }
}
