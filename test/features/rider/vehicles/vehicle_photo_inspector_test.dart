import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:delivery_boy/features/rider/vehicles/capture/vehicle_photo_inspector.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// RGBA pixels whose luma at (x, y) is [luma].
Uint8List _pixels(int w, int h, int Function(int x, int y) luma) {
  final bytes = Uint8List(w * h * 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      final v = luma(x, y);
      bytes[i] = v;
      bytes[i + 1] = v;
      bytes[i + 2] = v;
      bytes[i + 3] = 255;
    }
  }
  return bytes;
}

List<PhotoQualityIssue> _issues(int Function(int x, int y) luma) =>
    measurePhotoQuality(_pixels(200, 300, luma), width: 200, height: 300)
        .issues;

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('vehicle_photo_'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<String> write(String name, List<int> bytes) async {
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  group('fileProblem', () {
    test('accepts JPEG and PNG by their bytes', () async {
      expect(
        await VehiclePhotoInspector.fileProblem(
            await write('a.jpg', [0xFF, 0xD8, 0xFF, 0xE1, 0, 0])),
        isNull,
      );
      expect(
        await VehiclePhotoInspector.fileProblem(
            await write('b.png', [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A])),
        isNull,
      );
    });

    test('a .jpg name does not make a PDF a photo', () async {
      final path = await write('fake.jpg', '%PDF-1.7'.codeUnits);
      expect(await VehiclePhotoInspector.fileProblem(path),
          contains("isn't a JPEG or PNG"));
    });

    test('rejects a missing or empty file', () async {
      expect(await VehiclePhotoInspector.fileProblem('${dir.path}/gone.jpg'),
          contains('no longer on your phone'));
      expect(await VehiclePhotoInspector.fileProblem(await write('e.jpg', [])),
          contains("didn't save properly"));
    });

    test('rejects anything over the API\'s 8 MB limit', () async {
      final path = await write('big.jpg', [0xFF, 0xD8, 0xFF]);
      // Extended sparsely, so the test doesn't write 8 MB.
      File(path).openSync(mode: FileMode.append)
        ..truncateSync(VehiclePhotoInspector.maxBytes + 1)
        ..closeSync();
      expect(await VehiclePhotoInspector.fileProblem(path),
          contains('larger than 8 MB'));
    });
  });

  group('measurePhotoQuality', () {
    test('a detailed, evenly lit photo has no issues', () {
      expect(_issues((x, y) => (x + y).isEven ? 40 : 210), isEmpty);
    });

    test('flags a dark photo', () {
      expect(_issues((x, y) => (x + y).isEven ? 5 : 60),
          [PhotoQualityIssue.tooDark]);
    });

    test('flags a washed-out photo', () {
      expect(_issues((x, y) => (x + y).isEven ? 200 : 255),
          [PhotoQualityIssue.tooBright]);
    });

    test('flags a featureless (blurred) photo as possibly blurry', () {
      expect(_issues((x, y) => 120 + (x ~/ 50)), [PhotoQualityIssue.blurry]);
    });

    test('a plain background around a detailed vehicle is not blurry', () {
      // Flat everywhere except the central area, which is detailed.
      final issues = _issues((x, y) {
        final inCentre = x > 50 && x < 150 && y > 75 && y < 225;
        return inCentre && (x + y).isEven ? 30 : 180;
      });
      expect(issues, isEmpty);
    });
  });

  testWidgets('inspect decodes a real image and reports its quality',
      (tester) async {
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawRect(
        const ui.Rect.fromLTWH(0, 0, 64, 96),
        ui.Paint()..color = const Color(0xFF0A0A0A),
      );
      final image = await recorder.endRecording().toImage(64, 96);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final path = await write('dark.png', png!.buffer.asUint8List());

      final inspection = await VehiclePhotoInspector.inspect(path);
      expect(inspection.isUsable, isTrue);
      expect(inspection.issues, contains(PhotoQualityIssue.tooDark));

      final broken = await write('broken.jpg', [0xFF, 0xD8, 0xFF, 0, 1, 2]);
      final unreadable = await VehiclePhotoInspector.inspect(broken);
      expect(unreadable.isUsable, isFalse);
    });
  });
}
