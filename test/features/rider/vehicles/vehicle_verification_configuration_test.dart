import 'package:delivery_boy/features/rider/vehicles/model/vehicle_capture.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_verification_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('motorcycle', () {
    final config = VehicleVerificationConfiguration.forKind(VehicleKind.motorcycle);

    test('requires front, rear, both sides and the plate, in that order', () {
      expect(config.requiredCaptures.map((r) => r.type), [
        VehicleCaptureType.front,
        VehicleCaptureType.rear,
        VehicleCaptureType.leftSide,
        VehicleCaptureType.rightSide,
        VehicleCaptureType.registrationPlate,
      ]);
    });

    test('chassis and engine numbers are optional', () {
      expect(config.optionalCaptures.map((r) => r.type), [
        VehicleCaptureType.chassisNumber,
        VehicleCaptureType.engineNumber,
      ]);
    });

    test('every instruction talks about a motorbike, never a car', () {
      for (final r in config.requirements) {
        expect(r.instruction, contains('motorbike'), reason: r.title);
        expect(r.instruction, isNot(contains('car')), reason: r.title);
      }
    });

    test('framing is tall head-on and wide side-on', () {
      expect(config.requirementFor(VehicleCaptureType.front)!.guide.isPortrait,
          isTrue);
      expect(config.requirementFor(VehicleCaptureType.rear)!.guide.isPortrait,
          isTrue);
      expect(
          config.requirementFor(VehicleCaptureType.leftSide)!.guide.isPortrait,
          isFalse);
    });

    test('the rear view asks for a readable number plate', () {
      expect(
        config.requirementFor(VehicleCaptureType.rear)!.checks,
        contains('Number plate readable'),
      );
    });
  });

  group('car', () {
    final config = VehicleVerificationConfiguration.forKind(VehicleKind.car);

    test('uses the same framework with car wording and car framing', () {
      expect(config.requiredCaptures.map((r) => r.type), [
        VehicleCaptureType.front,
        VehicleCaptureType.rear,
        VehicleCaptureType.leftSide,
        VehicleCaptureType.rightSide,
        VehicleCaptureType.registrationPlate,
      ]);
      expect(config.optionalCaptures, isEmpty);
      final front = config.requirementFor(VehicleCaptureType.front)!;
      expect(front.instruction, contains('your car'));
      expect(front.guide.isPortrait, isFalse);
    });
  });

  test('bicycle requires front and side; serial number is optional', () {
    final config = VehicleVerificationConfiguration.forKind(VehicleKind.bicycle);
    expect(config.requiredCaptures.map((r) => r.type),
        [VehicleCaptureType.front, VehicleCaptureType.leftSide]);
    expect(config.optionalCaptures.single.type, VehicleCaptureType.serialNumber);
  });

  test('every kind has a front capture and at least one required step', () {
    for (final kind in VehicleKind.values) {
      final config = VehicleVerificationConfiguration.forKind(kind);
      expect(config.requiredCaptures, isNotEmpty, reason: kind.name);
      expect(config.requirementFor(VehicleCaptureType.front), isNotNull,
          reason: kind.name);
      expect(config.kind, kind);
    }
  });

  group('server vehicle-type slugs', () {
    const cases = {
      'motorbike': VehicleKind.motorcycle,
      'electric_motorbike': VehicleKind.motorcycle,
      'motorcycle': VehicleKind.motorcycle,
      'bicycle': VehicleKind.bicycle,
      'pickup': VehicleKind.pickup,
      'pickup_truck': VehicleKind.pickup,
      'truck': VehicleKind.truck,
      'van': VehicleKind.van,
      'car': VehicleKind.car,
    };
    for (final MapEntry(key: slug, value: kind) in cases.entries) {
      test('$slug → ${kind.name}', () {
        expect(VehicleKind.fromTypeSlug(slug), kind);
      });
    }

    test('an unknown or missing type falls back to a generic vehicle', () {
      expect(VehicleKind.fromTypeSlug('hovercraft'), VehicleKind.other);
      expect(VehicleKind.fromTypeSlug(null), VehicleKind.other);

      final config = VehicleVerificationConfiguration.forTypeSlug('hovercraft');
      expect(config.requiredCaptures.map((r) => r.type),
          [VehicleCaptureType.front, VehicleCaptureType.rear]);
      expect(config.requirements.first.instruction, contains('your vehicle'));
    });
  });

  test('the API side for the rear photo is "back"', () {
    expect(VehicleCaptureType.rear.apiKey, 'back');
    expect(VehicleCaptureType.front.apiKey, 'front');
  });
}
