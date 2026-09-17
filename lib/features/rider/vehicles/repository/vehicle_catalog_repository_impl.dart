import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/network/api_error_parser.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_make_model.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_model_model.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_type_model.dart';
import 'package:delivery_boy/features/rider/vehicles/repository/vehicle_catalog_repository.dart';
import 'package:delivery_boy/features/rider/vehicles/service/rider_vehicle_catalog_api_service.dart';

class VehicleCatalogRepositoryImpl implements VehicleCatalogRepository {
  final RiderVehicleCatalogApiService _api;

  VehicleCatalogRepositoryImpl(this._api);

  @override
  Future<Either<Failure, List<VehicleTypeModel>>> getVehicleTypes() =>
      _run(() async {
        final response = await _api.getVehicleTypes();
        final list = _dataListOf(response)
            .map((e) => VehicleTypeModel.fromJson(e))
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        return list;
      });

  @override
  Future<Either<Failure, List<VehicleMakeModel>>> getVehicleMakes(
    int vehicleTypeId,
  ) =>
      _run(() async {
        final response =
            await _api.getVehicleMakes(vehicleTypeId: vehicleTypeId);
        final list = _dataListOf(response)
            .map((e) => VehicleMakeModel.fromJson(e))
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        return list;
      });

  @override
  Future<Either<Failure, List<VehicleModelModel>>> getVehicleModels(
    int vehicleMakeId,
  ) =>
      _run(() async {
        final response =
            await _api.getVehicleModels(vehicleMakeId: vehicleMakeId);
        final list = _dataListOf(response)
            .map((e) => VehicleModelModel.fromJson(e))
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        return list;
      });

  // ── Parsing ─────────────────────────────────────────────────────────────

  /// Unwraps the `{success, message, data: {items: [...], pagination: {...}}}`
  /// envelope shared by all three public list endpoints.
  List<Map<String, dynamic>> _dataListOf(Response<dynamic> response) {
    final raw = (response.data as Map).cast<String, dynamic>();
    final data = raw['data'];
    final items = data is Map ? data['items'] : data;
    if (items is! List) return const [];
    return items.cast<Map<String, dynamic>>();
  }

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on DioException catch (e) {
      final msg = apiMessageFrom(e.response?.data) ??
          e.message ??
          'Failed to load vehicle catalogue';
      return Left(ServerFailure(msg));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
