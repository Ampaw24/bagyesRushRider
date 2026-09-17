import 'package:equatable/equatable.dart';

/// A manufacturer under a [VehicleTypeModel] (e.g. Honda under Motorbike).
///
/// Source: `GET /vehicle-makes?vehicle_type_id=` (public — no auth
/// required). Name uniqueness is scoped to `vehicleTypeId`, not global.
class VehicleMakeModel extends Equatable {
  final int id;
  final int vehicleTypeId;
  final String name;
  final String slug;
  final bool isActive;
  final int displayOrder;

  const VehicleMakeModel({
    required this.id,
    required this.vehicleTypeId,
    required this.name,
    required this.slug,
    required this.isActive,
    required this.displayOrder,
  });

  factory VehicleMakeModel.fromJson(Map<String, dynamic> json) {
    return VehicleMakeModel(
      id: json['id'] as int,
      vehicleTypeId: json['vehicle_type_id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      isActive: json['is_active'] == true,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, vehicleTypeId, name, displayOrder];
}
