import 'package:equatable/equatable.dart';

/// A vehicle category riders can register with (e.g. Motorbike).
///
/// Source: `GET /vehicle-types` (public — no auth required). Replaces the
/// hardcoded `VehicleType` enum previously used on the signup wizard.
class VehicleTypeModel extends Equatable {
  final int id;
  final String name;
  final String slug;
  final String? description;

  /// Drives whether the signup form must collect `plate_number`.
  final bool requiresPlate;

  /// `small` / `medium` / `large` / `extra_large`.
  final String maxParcelSize;

  /// Pre-formatted display string for [maxParcelSize] (e.g. `"Large"`).
  final String maxParcelSizeLabel;

  final bool isActive;

  /// Server-curated sort order — lists should be sorted by this, not
  /// alphabetically.
  final int displayOrder;

  const VehicleTypeModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.requiresPlate,
    required this.maxParcelSize,
    required this.maxParcelSizeLabel,
    required this.isActive,
    required this.displayOrder,
  });

  /// Heuristic used for a UI affordance only (e.g. showing an electric-vehicle
  /// note) — the API has no dedicated "is electric" field.
  bool get isElectric =>
      name.toLowerCase().contains('electric') ||
      slug.toLowerCase().contains('electric');

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypeModel(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      requiresPlate: json['requires_plate'] == true,
      maxParcelSize: json['max_parcel_size']?.toString() ?? '',
      maxParcelSizeLabel: json['max_parcel_size_label']?.toString() ?? '',
      isActive: json['is_active'] == true,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, slug, requiresPlate, displayOrder];
}
