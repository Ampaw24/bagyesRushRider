import 'package:flutter/widgets.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/features/rider/vehicles/model/vehicle_capture.dart';

/// The families of vehicle the verification flow knows how to guide.
///
/// The server's vehicle types (`GET /vehicle-types`) are admin-managed, so a
/// type is matched by its slug — see [fromTypeSlug] — and anything
/// unrecognised falls back to [other] rather than failing.
enum VehicleKind {
  motorcycle(noun: 'motorbike', icon: HugeIcons.strokeRoundedMotorbike01),
  car(noun: 'car', icon: HugeIcons.strokeRoundedCar01),
  van(noun: 'van', icon: HugeIcons.strokeRoundedVan),
  pickup(noun: 'pickup', icon: HugeIcons.strokeRoundedTruck),
  truck(noun: 'truck', icon: HugeIcons.strokeRoundedTruck),
  bicycle(noun: 'bicycle', icon: HugeIcons.strokeRoundedBicycle01),
  other(noun: 'vehicle', icon: HugeIcons.strokeRoundedMotorbike01);

  const VehicleKind({required this.noun, required this.icon});

  /// Lower-case word used inside instructions, e.g. "your motorbike". The
  /// app says "motorbike" because that is the backend's own label.
  final String noun;
  final IconData icon;

  /// [noun] for a heading, e.g. "Motorbike".
  String get label => '${noun[0].toUpperCase()}${noun.substring(1)}';

  static VehicleKind fromTypeSlug(String? slug) {
    final s = (slug ?? '').toLowerCase();
    // Order matters: "motorcycle" also contains "cycle".
    if (s.contains('motor')) return motorcycle;
    if (s.contains('bicycle')) return bicycle;
    if (s.contains('pickup') || s.contains('pick_up')) return pickup;
    if (s.contains('truck') || s.contains('lorry')) return truck;
    if (s.contains('van')) return van;
    if (s.contains('car')) return car;
    return other;
  }
}

/// What a rider must photograph to verify one kind of vehicle, in capture
/// order.
///
/// Data, not per-vehicle classes: adding a vehicle family means adding a
/// case to [forKind], not another screen. Which of these the rider is
/// actually asked for today is narrowed further by what the API stores —
/// see `VehicleVerificationRepository.supportedCaptureTypes`.
class VehicleVerificationConfiguration {
  final VehicleKind kind;
  final List<VehicleCaptureRequirement> requirements;

  const VehicleVerificationConfiguration._(this.kind, this.requirements);

  factory VehicleVerificationConfiguration.forKind(VehicleKind kind) =>
      switch (kind) {
        VehicleKind.motorcycle => _motorcycle,
        VehicleKind.car => _fourWheeled(kind, body: _carBody),
        VehicleKind.van ||
        VehicleKind.pickup ||
        VehicleKind.truck =>
          _fourWheeled(kind, body: _boxyBody),
        VehicleKind.bicycle => _bicycle,
        VehicleKind.other => _other,
      };

  factory VehicleVerificationConfiguration.forTypeSlug(String? slug) =>
      VehicleVerificationConfiguration.forKind(VehicleKind.fromTypeSlug(slug));

  List<VehicleCaptureRequirement> get requiredCaptures =>
      requirements.where((r) => r.required).toList();

  List<VehicleCaptureRequirement> get optionalCaptures =>
      requirements.where((r) => !r.required).toList();

  VehicleCaptureRequirement? requirementFor(VehicleCaptureType type) {
    for (final r in requirements) {
      if (r.type == type) return r;
    }
    return null;
  }
}

// ── Guide shapes ────────────────────────────────────────────────────────────
// A motorbike is tall and narrow head-on and long side-on, so it gets its
// own proportions instead of a car-shaped box.

const _motorbikeEnd = CaptureGuide(aspectRatio: 0.62, maxWidthFraction: 0.7);
const _motorbikeSide = CaptureGuide(aspectRatio: 1.7);
const _motorbikePlate = CaptureGuide(aspectRatio: 1.5, maxWidthFraction: 0.7);
const _bicycleEnd = CaptureGuide(aspectRatio: 0.5, maxWidthFraction: 0.6);
const _bicycleSide = CaptureGuide(aspectRatio: 1.6);
const _carPlate = CaptureGuide(aspectRatio: 3);
const _identifier = CaptureGuide(aspectRatio: 2.4, maxWidthFraction: 0.8);

typedef _Body = ({CaptureGuide end, CaptureGuide side});

const _Body _carBody = (
  end: CaptureGuide(aspectRatio: 1.4),
  side: CaptureGuide(aspectRatio: 2.2, maxWidthFraction: 0.9),
);
const _Body _boxyBody = (
  end: CaptureGuide(aspectRatio: 1.1),
  side: CaptureGuide(aspectRatio: 2, maxWidthFraction: 0.9),
);

// ── Requirement builders ────────────────────────────────────────────────────

VehicleCaptureRequirement _side(
  VehicleCaptureType type,
  String side,
  String noun,
  CaptureGuide guide, {
  List<String> checks = const ['Both wheels', 'Nothing blocking the view'],
}) =>
    VehicleCaptureRequirement(
      type: type,
      title: '${side[0].toUpperCase()}${side.substring(1)} side',
      instruction: 'Step back and capture the full $side side of your $noun.',
      checks: checks,
      guide: guide,
    );

VehicleCaptureRequirement _plate(String noun, CaptureGuide guide) =>
    VehicleCaptureRequirement(
      type: VehicleCaptureType.registrationPlate,
      title: 'Number plate',
      instruction:
          "Move closer and capture a clear photo of your $noun's number plate.",
      checks: const [
        'Every character readable',
        'Plate centred in the frame',
        'No glare or shadow on it',
      ],
      guide: guide,
    );

VehicleCaptureRequirement _identifierOf(
  VehicleCaptureType type,
  String title,
  String instruction,
) =>
    VehicleCaptureRequirement(
      type: type,
      title: title,
      instruction: instruction,
      checks: const ['Every character readable', 'Taken close and in focus'],
      guide: _identifier,
      required: false,
    );

final _motorcycle = VehicleVerificationConfiguration._(
  VehicleKind.motorcycle,
  [
    const VehicleCaptureRequirement(
      type: VehicleCaptureType.front,
      title: 'Front view',
      instruction:
          'Stand in front of your motorbike and capture the complete motorbike.',
      checks: [
        'Front wheel',
        'Handlebars and headlight',
        'The whole motorbike inside the frame',
      ],
      guide: _motorbikeEnd,
    ),
    const VehicleCaptureRequirement(
      type: VehicleCaptureType.rear,
      title: 'Rear view',
      instruction:
          'Stand behind your motorbike and capture the complete rear view.',
      checks: [
        'Rear wheel and seat',
        'Number plate readable',
        'The whole motorbike inside the frame',
      ],
      guide: _motorbikeEnd,
    ),
    _side(
      VehicleCaptureType.leftSide,
      'left',
      'motorbike',
      _motorbikeSide,
      checks: const [
        'Both wheels',
        'Fuel tank and frame',
        'Nothing blocking it'
      ],
    ),
    _side(
      VehicleCaptureType.rightSide,
      'right',
      'motorbike',
      _motorbikeSide,
      checks: const [
        'Both wheels',
        'Fuel tank and frame',
        'Nothing blocking it'
      ],
    ),
    _plate('motorbike', _motorbikePlate),
    _identifierOf(
      VehicleCaptureType.chassisNumber,
      'Chassis number',
      'Capture the chassis (frame) number stamped on your motorbike.',
    ),
    _identifierOf(
      VehicleCaptureType.engineNumber,
      'Engine number',
      "Capture the number stamped on your motorbike's engine.",
    ),
  ],
);

VehicleVerificationConfiguration _fourWheeled(
  VehicleKind kind, {
  required _Body body,
}) {
  final noun = kind.noun;
  return VehicleVerificationConfiguration._(kind, [
    VehicleCaptureRequirement(
      type: VehicleCaptureType.front,
      title: 'Front view',
      instruction: 'Stand in front of your $noun and capture the full front.',
      checks: const [
        'Headlights and bonnet',
        'The whole front inside the frame'
      ],
      guide: body.end,
    ),
    VehicleCaptureRequirement(
      type: VehicleCaptureType.rear,
      title: 'Rear view',
      instruction: 'Stand behind your $noun and capture the full rear.',
      checks: const [
        'Number plate readable',
        'The whole rear inside the frame'
      ],
      guide: body.end,
    ),
    _side(VehicleCaptureType.leftSide, 'left', noun, body.side),
    _side(VehicleCaptureType.rightSide, 'right', noun, body.side),
    _plate(noun, _carPlate),
  ]);
}

final _bicycle = VehicleVerificationConfiguration._(
  VehicleKind.bicycle,
  [
    const VehicleCaptureRequirement(
      type: VehicleCaptureType.front,
      title: 'Front view',
      instruction:
          'Stand in front of your bicycle and capture the complete bicycle.',
      checks: ['Front wheel and handlebars', 'The whole bicycle in the frame'],
      guide: _bicycleEnd,
    ),
    const VehicleCaptureRequirement(
      type: VehicleCaptureType.leftSide,
      title: 'Side view',
      instruction: 'Step back and capture the full side of your bicycle.',
      checks: ['Both wheels', 'Frame and chain'],
      guide: _bicycleSide,
    ),
    _identifierOf(
      VehicleCaptureType.serialNumber,
      'Serial number',
      'Capture the serial number stamped under the pedals.',
    ),
  ],
);

final _other = VehicleVerificationConfiguration._(
  VehicleKind.other,
  const [
    VehicleCaptureRequirement(
      type: VehicleCaptureType.front,
      title: 'Front view',
      instruction: 'Stand in front of your vehicle and capture the full front.',
      checks: ['The whole vehicle inside the frame'],
      guide: CaptureGuide(aspectRatio: 1),
    ),
    VehicleCaptureRequirement(
      type: VehicleCaptureType.rear,
      title: 'Rear view',
      instruction: 'Stand behind your vehicle and capture the full rear.',
      checks: ['Number plate readable', 'The whole vehicle inside the frame'],
      guide: CaptureGuide(aspectRatio: 1),
    ),
  ],
);
