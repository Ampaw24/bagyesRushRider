import 'dart:async';
import 'dart:convert';

import 'package:delivery_boy/components/orderDetails.component.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/constant/models.dart';
import 'package:delivery_boy/pages/home.dart';
import 'package:delivery_boy/services/app.services.dart';
import 'package:delivery_boy/states/app.state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:location/location.dart' as loc;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

enum Trip { PICKUP, DROPOFF }

class Map extends StatefulWidget {
  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> {
  List<LatLng> polylineCoordinates = [];
  GoogleMapController? mapController;
  BitmapDescriptor? customIcon;
  Set<Marker> markers = Set();
  Trip? trip;
  String googleAPiKey = "AIzaSyA6QwaWqE4gtpQq4tTXGVIxLmeEeVKhYUc";

  StreamSubscription<loc.LocationData>? $location;
  Set<Polyline> polylines = Set();
  LatLng riderCurrentPosition = LatLng(0, -0);
  LatLng destinationLocation = LatLng(0, -0);
  bool loading = false;
  String token = "";
  var order;

  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 1), () {
      loadTrip();
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    $location?.cancel();
  }

  LatLng getPickupCoords(order) {
    try {
      return LatLng(order['pickupLocationCoords']['latitude'],
          order['pickupLocationCoords']['longitude']);
    } catch (e) {
      return LatLng(0, -0);
    }
  }

  LatLng getDestinationCoords(order) {
    try {
      return LatLng(order['deliveryLocationCoords']['latitude'],
          order['deliveryLocationCoords']['longitude']);
    } catch (e) {
      return LatLng(0, -0);
    }
  }

  void loadTrip() {
    try {
      var order = context.read<AppState>().selectedOrder;
      switch (order["tripType"]) {
        case "PICKUP":
          trip = Trip.PICKUP;
          destinationLocation = getPickupCoords(order);
          break;
        case "DESTINATION":
          trip = Trip.DROPOFF;
          destinationLocation = getDestinationCoords(order);
          break;
        default:
          trip = null;
          break;
      }
      setState(() {
        if (trip != null && $location == null) {
          getRiderLocation();
        }
      });
    } catch (err) {}
  }

  String getTrip() {
    switch (trip) {
      case Trip.PICKUP:
        return "Current trip: Pickup";
      default:
        return "Current trip: Destination";
    }
  }

  String getCustomerPhone() {
    try {
      return order['customer']['phone'];
    } catch (e) {
      return '';
    }
  }

  String getCustomerName() {
    try {
      return order['customer']['name'];
    } catch (e) {
      return '';
    }
  }

  _addPolyLine() {
    print(polylineCoordinates);
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id, color: Colors.red, points: polylineCoordinates);
    polylines.add(polyline);
    setState(() {});
  }

  void drawLine() async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: googleAPiKey,
        request: PolylineRequest(
          origin: PointLatLng(
              riderCurrentPosition.latitude, riderCurrentPosition.longitude),
          destination: PointLatLng(
              destinationLocation.latitude, destinationLocation.longitude),
          mode: TravelMode.driving,
        ));
    print(result.errorMessage);
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });

      _addPolyLine();
    }
  }

  void _openPhone() async {
    try {
      var phone = getCustomerPhone();
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phone,
      );
      await launchUrl(launchUri);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _finishTrip() async {
    try {
      $location?.cancel();
      var data = {"orderId": order["_id"]};
      setState(() {
        loading = true;
      });
      var response = await finishTrip(data, token)
          .then((value) => IApiResponse(jsonDecode(value.body)));
      setState(() {
        loading = false;
      });
      if (!response.success) {
        throw Exception(response.message);
      }
      showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Home()),
                          );
                        },
                        child: Text('Okay'))
                  ],
                  title: Text("Congratulations!"),
                  content: Text("Delivery completed successfully")));
    } catch (e) {
      showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Okay'))
                  ],
                  title: Text("Oops! Something went wrong"),
                  content: Text(e.toString())));
    }
  }

  Future<void> _updateRiderLocation() async {
    try {
      var data = {
        "orderId": order["_id"],
        "coords": {
          "latitude": riderCurrentPosition.latitude,
          "longitude": riderCurrentPosition.longitude
        }
      };
      await updateRiderLocation(data, token)
          .then((value) => jsonDecode(value.body));
    } catch (e) {
      print(e.toString());
    }
  }

  getLiveLocation() async {
    try {
      loc.Location location = loc.Location();
      await location.changeSettings(
        accuracy: loc.LocationAccuracy.high,
        distanceFilter: 10.0,
      );
      await location.enableBackgroundMode(enable: true);
      $location = location.onLocationChanged.listen((loc.LocationData locationData) {
        if (locationData.latitude != null && locationData.longitude != null) {
          setState(() {
            riderCurrentPosition =
                LatLng(locationData.latitude!, locationData.longitude!);
            mapController
                ?.animateCamera(CameraUpdate.newLatLng(riderCurrentPosition));
          });
          _updateRiderLocation();
          showMarkers();
        }
      });
    } catch (e) {}
  }

  Future<void> updateTrip(Trip _trip) async {
    try {
      setState(() {
        loading = true;
      });
      var data = {"orderId": order["_id"], "trip": _trip.name};
      var response = await setTrip(data, token)
          .then((value) => IApiResponse(jsonDecode(value.body)));
      setState(() {
        loading = false;
      });
      print(response);
      if (!response.success) {
        throw Exception(response.message);
      }
      context.read<AppState>().pushSelectedOrder(response.data);
      loadTrip();
    } catch (err) {
      showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Okay'))
                  ],
                  title: Text("Oops! Something went wrong"),
                  content: Text(err.toString())));
    }
  }

  void showMarkers() {
    try {
      setState(() {
        markers.add(Marker(
          //add start location marker
          markerId: MarkerId(riderCurrentPosition.toString()),
          position: riderCurrentPosition, //position of marker
          infoWindow: InfoWindow(
            //popup info
            title: 'Your Location',
            snippet: order['pickUpLocation'],
          ),
          icon: BitmapDescriptor.defaultMarker, //Icon for Marker
        ));
        // Pickup location coords;
        markers.add(Marker(
          //add distination location marker // Pickup location
          markerId: MarkerId(destinationLocation.toString()),
          position: destinationLocation, //position of marker
          infoWindow: InfoWindow(
            //popup info
            title: 'Destination',
            snippet: order["deliveryLocation"],
          ),
          icon: BitmapDescriptor.defaultMarker, //Icon for Marker
        ));

        mapController
            ?.animateCamera(CameraUpdate.newLatLng(destinationLocation));

        drawLine();
      });
    } catch (e) {
      print(e);
    }
  }

  void getRiderLocation() async {
    loc.Location location = loc.Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    loc.PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }

    getLiveLocation();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    order = context.read<AppState>().selectedOrder;
    token = context.read<AppState>().token ?? '';

    viewOrderDetail() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          // return object of type Dialog
          return Dialog(
            elevation: 0.0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            child: Wrap(
              children: <Widget>[
                OrderDetailsComponent(
                    child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        updateTrip(Trip.PICKUP);
                      },
                      child: Container(
                        width: width,
                        alignment: Alignment.center,
                        margin: EdgeInsets.all(fixPadding),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 0.5),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Pickup',
                              style: TextStyle(color: Colors.black),
                            ),
                            Icon(Icons.check_circle_outline,
                                color: trip?.index == Trip.PICKUP.index
                                    ? Colors.green
                                    : Colors.grey)
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        updateTrip(Trip.DROPOFF);
                      },
                      child: Container(
                        width: width,
                        alignment: Alignment.center,
                        margin: EdgeInsets.all(fixPadding),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 0.5),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Destination',
                              style: TextStyle(color: Colors.black),
                            ),
                            Icon(Icons.check_circle_outline,
                                color: trip?.index == Trip.DROPOFF.index
                                    ? Colors.green
                                    : Colors.grey)
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: width,
                        alignment: Alignment.center,
                        margin: EdgeInsets.all(fixPadding),
                        padding: EdgeInsets.all(fixPadding),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: Text(
                          'Close',
                          style: wbuttonWhiteTextStyle,
                        ),
                      ),
                    ),
                  ],
                ))
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        title: Text(
          'Map',
          style: headingStyle,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: blackColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      bottomSheet: Wrap(
        children: <Widget>[
          Material(
            elevation: 7.0,
            child: Container(
              padding: EdgeInsets.all(fixPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 80.0,
                        height: 80.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50.0),
                          image: DecorationImage(
                            image: AssetImage('assets/delivery_boy.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      widthSpace,
                      Container(
                        width: width - (fixPadding * 2.0 + 80.0 + 10.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(getCustomerName(), style: headingStyle),
                            heightSpace,
                            Text(getTrip(), style: listItemSubTitleStyle),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: width,
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () => loading ? null : _finishTrip(),
                      child: Container(
                        height: 40.0,
                        width: 100.0,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5.0),
                          color: primaryColor,
                        ),
                        child: loading
                            ? SpinKitCircle(color: Colors.white, size: 10)
                            : Text(
                                'Finish',
                                style: wbuttonWhiteTextStyle,
                              ),
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
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 150.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            FloatingActionButton(
              onPressed: () {
                viewOrderDetail();
              },
              backgroundColor: whiteColor,
              child: Icon(
                Icons.assignment,
                color: primaryColor,
              ),
            ),
            heightSpace,
            FloatingActionButton(
              onPressed: () {
                _openPhone();
              },
              backgroundColor: whiteColor,
              child: Icon(
                Icons.call,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
      body: GoogleMap(
        markers: markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        mapType: MapType.normal,
        zoomGesturesEnabled: true,
        zoomControlsEnabled: false,
        polylines: polylines,
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        initialCameraPosition:
            CameraPosition(target: riderCurrentPosition, zoom: 10),
      ),
    );
  }
}
