import 'package:equatable/equatable.dart';

/// One view of a vehicle a rider can be asked to photograph.
///
/// [apiKey] is the name the backend uses for it — today only `front` and
/// `back` exist (`/rider/me/vehicle-photos/:side`); the rest follow the same
/// snake_case convention so they slot in when the API grows.
enum VehicleCaptureType {
  front('front'),
  rear('back'),
  leftSide('left_side'),
  rightSide('right_side'),
  registrationPlate('registration_plate'),
  chassisNumber('chassis_number'),
  engineNumber('engine_number'),
  serialNumber('serial_number');

  const VehicleCaptureType(this.apiKey);

  final String apiKey;
}

/// Shape of the on-screen framing guide for one capture, as proportions of
/// the camera preview rather than pixels.
class CaptureGuide extends Equatable {
  /// Width ÷ height of the guide. Below 1 is a tall frame (a motorbike seen
  /// head-on), above 1 a wide one (any vehicle side-on).
  final double aspectRatio;

  /// Largest share of the preview's width the guide may take.
  final double maxWidthFraction;

  const CaptureGuide({required this.aspectRatio, this.maxWidthFraction = 0.86});

  bool get isPortrait => aspectRatio < 1;

  @override
  List<Object?> get props => [aspectRatio, maxWidthFraction];
}

/// What the rider must capture for one step, and how to guide them.
class VehicleCaptureRequirement extends Equatable {
  final VehicleCaptureType type;
  final String title;

  /// Full sentence shown under the camera, e.g. "Stand behind your motorbike
  /// and capture the complete rear view."
  final String instruction;

  /// What should be visible in the photo — shown as a short checklist.
  final List<String> checks;

  final bool required;
  final CaptureGuide guide;

  const VehicleCaptureRequirement({
    required this.type,
    required this.title,
    required this.instruction,
    required this.guide,
    this.checks = const [],
    this.required = true,
  });

  @override
  List<Object?> get props =>
      [type, title, instruction, checks, required, guide];
}
