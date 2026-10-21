import 'package:gopady_rider/constant/typedef.dart';
import 'package:gopady_rider/features/rider/vehicles/model/vehicle_make_model.dart';
import 'package:gopady_rider/features/rider/vehicles/model/vehicle_model_model.dart';
import 'package:gopady_rider/features/rider/vehicles/model/vehicle_type_model.dart';

/// Public, unauthenticated reads of the vehicle catalogue — the cascading
/// type -> make -> model reference data used to constrain the rider signup
/// vehicle picker instead of free text or a hardcoded list.
abstract class VehicleCatalogRepository {
  ResultFuture<List<VehicleTypeModel>> getVehicleTypes();

  ResultFuture<List<VehicleMakeModel>> getVehicleMakes(int vehicleTypeId);

  ResultFuture<List<VehicleModelModel>> getVehicleModels(int vehicleMakeId);
}
