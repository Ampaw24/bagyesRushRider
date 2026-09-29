import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:delivery_boy/constant/map_config.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';

/// A road-following route through an order's points.
class RiderRoute {
  final List<LatLng> points;
  final int distanceMeters;
  final Duration duration;

  const RiderRoute({
    required this.points,
    required this.distanceMeters,
    required this.duration,
  });
}

/// Google Routes API (`computeRoutes`) client — the successor to the legacy
/// Directions API, which new Cloud projects can no longer enable.
///
/// Uses [kMapsApiKey] (the `.env` web-service key), so the **Routes API**
/// must be enabled on that key's project alongside Geocoding.
class RiderDirectionsService {
  RiderDirectionsService._();

  /// Own Dio for the same reason as [RiderPlacesService]: the shared
  /// instance attaches the rider's bearer token to every request, and that
  /// must never be sent to Google.
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static const String _url =
      'https://routes.googleapis.com/directions/v2:computeRoutes';

  /// Routes from the first stop to the last, through the rest in order.
  /// Returns null on any failure — callers fall back to a straight line.
  static Future<RiderRoute?> route(List<LatLng> stops) async {
    if (stops.length < 2) return null;
    if (kMapsApiKey.isEmpty) {
      appLogger.w('[Routes] GMAPCODE missing from .env — skipping route');
      return null;
    }

    Map<String, dynamic> waypoint(LatLng p) => {
          'location': {
            'latLng': {'latitude': p.latitude, 'longitude': p.longitude},
          },
        };

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _url,
        options: Options(headers: {
          'X-Goog-Api-Key': kMapsApiKey,
          'X-Goog-FieldMask':
              'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline',
        }),
        data: {
          'origin': waypoint(stops.first),
          'destination': waypoint(stops.last),
          if (stops.length > 2)
            'intermediates':
                stops.sublist(1, stops.length - 1).map(waypoint).toList(),
          'travelMode': 'DRIVE',
          'routingPreference': 'TRAFFIC_AWARE',
          'languageCode': 'en',
        },
      );

      final routes = response.data?['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        appLogger.w('[Routes] no route returned');
        return null;
      }

      final route = routes.first as Map<String, dynamic>;
      final encoded =
          (route['polyline'] as Map<String, dynamic>?)?['encodedPolyline']
              as String?;
      if (encoded == null || encoded.isEmpty) return null;

      final points = PolylinePoints()
          .decodePolyline(encoded)
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      // Duration arrives as a protobuf string, e.g. "1234s".
      final seconds = int.tryParse(
            (route['duration'] as String? ?? '').replaceAll('s', ''),
          ) ??
          0;

      return RiderRoute(
        points: points,
        distanceMeters: (route['distanceMeters'] as num?)?.toInt() ?? 0,
        duration: Duration(seconds: seconds),
      );
    } on DioException catch (e, s) {
      appLogger.e(
        '[Routes] computeRoutes failed: ${e.response?.data ?? e.message}',
        error: e,
        stackTrace: s,
      );
      return null;
    } catch (e, s) {
      appLogger.e('[Routes] unexpected error', error: e, stackTrace: s);
      return null;
    }
  }
}
