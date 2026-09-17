import 'package:dio/dio.dart';
import 'package:delivery_boy/core/network/api_endpoints.dart';

/// Raw Dio calls for the public vehicle-catalogue reads. None of these need
/// a bearer token — that's what makes them usable before a rider account
/// exists (see [ApiEndpoints]'s vehicle catalogue section).
class RiderVehicleCatalogApiService {
  final Dio _dio;

  RiderVehicleCatalogApiService(this._dio);

  Future<Response<dynamic>> getVehicleTypes({String? search}) => _dio.get(
        ApiEndpoints.vehicleTypes,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

  /// `vehicleTypeId` is optional server-side, but callers here always pass
  /// it once a type is selected — see the vehicle-catalogue docs' warning
  /// that omitting it mixes makes across every type.
  Future<Response<dynamic>> getVehicleMakes({
    required int vehicleTypeId,
    String? search,
  }) =>
      _dio.get(
        ApiEndpoints.vehicleMakes,
        queryParameters: {
          'vehicle_type_id': vehicleTypeId,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

  /// Models are only reachable through their make — the filter key is
  /// `vehicle_make_id`, not a type id.
  Future<Response<dynamic>> getVehicleModels({
    required int vehicleMakeId,
    String? search,
  }) =>
      _dio.get(
        ApiEndpoints.vehicleModels,
        queryParameters: {
          'vehicle_make_id': vehicleMakeId,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
}
