import 'package:equatable/equatable.dart';

import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_capture.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_verification_configuration.dart';

/// The vehicle a rider delivers with, read from `/rider/me`'s `vehicle`
/// object.
///
/// The API holds one vehicle per rider today. Keeping it as its own value —
/// rather than reading profile fields across the app — is what lets a list
/// of these replace it if riders ever register more than one.
class RiderVehicle extends Equatable {
  final VehicleKind kind;

  /// The server's own label for the type, e.g. "Motorbike".
  final String? typeLabel;
  final String? make;
  final String? model;
  final String? colour;
  final int? year;
  final String? plateNumber;

  /// `owned` or `authorised`. Kept apart from verification: a vehicle can be
  /// verified while the rider's authority to use it is still being checked.
  final String? ownership;
  final String? ownershipLabel;

  /// Photo URLs the server holds, by capture.
  final Map<VehicleCaptureType, String> photos;

  const RiderVehicle({
    required this.kind,
    this.typeLabel,
    this.make,
    this.model,
    this.colour,
    this.year,
    this.plateNumber,
    this.ownership,
    this.ownershipLabel,
    this.photos = const {},
  });

  factory RiderVehicle.fromProfile(RiderMeProfileModel profile) {
    return RiderVehicle(
      kind: VehicleKind.fromTypeSlug(profile.vehicleType),
      typeLabel: profile.vehicleTypeLabel,
      make: profile.vehicleMake,
      model: profile.vehicleModel,
      colour: profile.vehicleColour,
      year: profile.vehicleYear,
      plateNumber: profile.plateNumber,
      ownership: profile.vehicleOwnership,
      ownershipLabel: profile.vehicleOwnershipLabel,
      photos: {
        for (final type in VehicleCaptureType.values)
          if (profile.vehiclePhotos[type.apiKey] case final url?) type: url,
      },
    );
  }

  /// "Honda CB125", falling back to the type ("Motorbike").
  String get displayName {
    final name = [make, model].whereType<String>().join(' ');
    if (name.isNotEmpty) return name;
    return typeLabel ?? 'Your ${kind.noun}';
  }

  /// "Motorbike · Black · 2021" — whatever is known.
  String get details =>
      [typeLabel, colour, year?.toString()].whereType<String>().join(' · ');

  @override
  List<Object?> get props => [
        kind,
        typeLabel,
        make,
        model,
        colour,
        year,
        plateNumber,
        ownership,
        photos,
      ];
}
