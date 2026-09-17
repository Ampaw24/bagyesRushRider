import 'package:equatable/equatable.dart';

/// A specific model under a [VehicleMakeModel] (e.g. CB125F under Honda).
///
/// Source: `GET /vehicle-models?vehicle_make_id=` (public — no auth
/// required). Note the filter key is `vehicle_make_id`, not a type id —
/// models are only reachable through their make. Name uniqueness is scoped
/// to `vehicleMakeId`, not global.
class VehicleModelModel extends Equatable {
  final int id;
  final int vehicleMakeId;
  final String name;
  final String slug;
  final bool isActive;
  final int displayOrder;

  const VehicleModelModel({
    required this.id,
    required this.vehicleMakeId,
    required this.name,
    required this.slug,
    required this.isActive,
    required this.displayOrder,
  });

  factory VehicleModelModel.fromJson(Map<String, dynamic> json) {
    return VehicleModelModel(
      id: json['id'] as int,
      vehicleMakeId: json['vehicle_make_id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      isActive: json['is_active'] == true,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, vehicleMakeId, name, displayOrder];
}
