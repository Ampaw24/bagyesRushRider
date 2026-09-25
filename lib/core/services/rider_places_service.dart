import 'package:dio/dio.dart';

import 'package:delivery_boy/constant/map_config.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';

/// Google Geocoding API client.
///
/// Used to turn a GPS fix into a human-readable street address for the home
/// header. Preferred over the platform's own geocoder (`package:geocoding`),
/// which resolves only coarse locality/district names in Ghana.
class RiderPlacesService {
  RiderPlacesService._();

  /// Deliberately NOT `sl<Dio>()`. That instance carries
  /// [RiderDioInterceptor], which attaches `Authorization: Bearer <rider
  /// token>` to every request it sees — an absolute third-party URL is not
  /// exempt. Reusing it would send the rider's session token to Google on
  /// every geocode, and log the request through appLogger besides.
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  static const String _geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';

  /// Returns `results[0].formatted_address`, or null on any failure.
  ///
  /// Never throws: the caller treats a null result as "couldn't name this
  /// place" and falls back, rather than discarding an otherwise-good fix.
  static Future<String?> reverseGeocode(double latitude, double longitude) async {
    if (kMapsApiKey.isEmpty) {
      appLogger.w('[Places] GMAPCODE missing from .env — skipping geocode');
      return null;
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _geocodeUrl,
        queryParameters: {
          'latlng': '$latitude,$longitude',
          'key': kMapsApiKey,
          'language': 'en',
        },
      );

      final data = response.data;
      if (data == null) return null;

      // Google answers HTTP 200 even for OVER_QUERY_LIMIT / REQUEST_DENIED /
      // ZERO_RESULTS, so the status code alone proves nothing.
      final status = data['status'] as String?;
      if (status != 'OK') {
        appLogger.w(
          '[Places] reverseGeocode status: $status '
          '— ${data['error_message'] ?? 'no error_message'}',
        );
        return null;
      }

      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final address =
          ((results.first as Map)['formatted_address'] as String?)?.trim();
      return (address != null && address.isNotEmpty) ? address : null;
    } on DioException catch (e, s) {
      appLogger.e('[Places] reverseGeocode network error', error: e, stackTrace: s);
      return null;
    } catch (e, s) {
      appLogger.e('[Places] reverseGeocode unexpected error',
          error: e, stackTrace: s);
      return null;
    }
  }

  /// Resolves a free-text address to a pin for the order map — the backend
  /// sends orders as address strings only (no lat/lng), so this is the only
  /// way to place a marker. Returns null on any failure; the caller falls
  /// back to an address-only external nav link rather than blocking on this.
  static Future<(double lat, double lng)?> geocodeAddress(
    String address,
  ) async {
    if (kMapsApiKey.isEmpty) {
      appLogger.w('[Places] GMAPCODE missing from .env — skipping geocode');
      return null;
    }
    if (address.trim().isEmpty) return null;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _geocodeUrl,
        queryParameters: {
          'address': address,
          'key': kMapsApiKey,
          'language': 'en',
        },
      );

      final data = response.data;
      if (data == null) return null;

      final status = data['status'] as String?;
      if (status != 'OK') {
        appLogger.w(
          '[Places] geocodeAddress status: $status '
          '— ${data['error_message'] ?? 'no error_message'}',
        );
        return null;
      }

      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final location =
          ((results.first as Map)['geometry'] as Map?)?['location'] as Map?;
      final lat = (location?['lat'] as num?)?.toDouble();
      final lng = (location?['lng'] as num?)?.toDouble();
      return (lat != null && lng != null) ? (lat, lng) : null;
    } on DioException catch (e, s) {
      appLogger.e('[Places] geocodeAddress network error', error: e, stackTrace: s);
      return null;
    } catch (e, s) {
      appLogger.e('[Places] geocodeAddress unexpected error',
          error: e, stackTrace: s);
      return null;
    }
  }
}
