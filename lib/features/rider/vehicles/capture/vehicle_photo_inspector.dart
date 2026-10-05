import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';

/// Things worth retaking for, but never grounds to refuse a photo: the
/// server and its reviewers make the call.
enum PhotoQualityIssue {
  tooDark('This photo looks dark. Retake it in better light if you can.'),
  tooBright('This photo looks washed out. Avoid pointing into bright light.'),
  blurry('This photo may be blurry. Hold the phone steady and retake it.');

  const PhotoQualityIssue(this.message);

  final String message;
}

class PhotoQuality extends Equatable {
  /// Mean luma, 0–255.
  final double brightness;

  /// Mean luma change between neighbouring pixels. Detail and sharp edges
  /// push it up; blur flattens it.
  final double sharpness;

  const PhotoQuality({required this.brightness, required this.sharpness});

  // Brightness bounds match the selfie capture's. The sharpness floor is
  // deliberately low — a warning on a sharp photo of a plain wall costs more
  // trust than a missed warning — and worth tuning against real captures.
  static const _minBrightness = 55.0;
  static const _maxBrightness = 215.0;
  static const _minSharpness = 3.0;

  List<PhotoQualityIssue> get issues => [
        if (brightness < _minBrightness) PhotoQualityIssue.tooDark,
        if (brightness > _maxBrightness) PhotoQualityIssue.tooBright,
        if (sharpness < _minSharpness) PhotoQualityIssue.blurry,
      ];

  @override
  List<Object?> get props => [brightness, sharpness];
}

class VehiclePhotoInspection extends Equatable {
  /// Why the photo can't be sent at all, or null when it can.
  final String? problem;
  final List<PhotoQualityIssue> issues;

  const VehiclePhotoInspection({this.problem, this.issues = const []});

  bool get isUsable => problem == null;

  @override
  List<Object?> get props => [problem, issues];
}

/// Checks a captured photo against the API's rules for `photo` (`image`,
/// `mimes:jpeg,png,jpg`, `max:8192` KB, at most 8000×8000) and for obvious
/// quality problems.
///
/// The file's own bytes decide its format — never its name or extension.
abstract final class VehiclePhotoInspector {
  static const maxBytes = 8192 * 1024;
  static const maxDimension = 8000;

  /// Small enough to decode cheaply on a budget phone, large enough that
  /// blur still shows.
  static const _analysisWidth = 480;

  static const _gone =
      'This photo is no longer on your phone. Please retake it.';

  /// Size and format only — cheap enough to repeat before every upload.
  static Future<String?> fileProblem(String path) async {
    final file = File(path);
    try {
      if (!await file.exists()) return _gone;
      final length = await file.length();
      if (length == 0) {
        return "This photo didn't save properly. Please retake it.";
      }
      if (length > maxBytes) {
        return 'This photo is larger than 8 MB. Please retake it.';
      }
      final header = await file
          .openRead(0, 8)
          .fold<List<int>>([], (bytes, chunk) => bytes..addAll(chunk));
      if (!_isJpeg(header) && !_isPng(header)) {
        return "This isn't a JPEG or PNG photo. Please retake it.";
      }
      return null;
    } on FileSystemException {
      // Removed mid-check — e.g. the OS clearing the app's cache.
      return _gone;
    }
  }

  /// [fileProblem], then a downscaled decode for dimensions and quality.
  static Future<VehiclePhotoInspection> inspect(String path) async {
    final problem = await fileProblem(path);
    if (problem != null) return VehiclePhotoInspection(problem: problem);

    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      buffer = await ui.ImmutableBuffer.fromFilePath(path);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width > maxDimension || descriptor.height > maxDimension) {
        return const VehiclePhotoInspection(
          problem: 'This photo is too large. Please retake it.',
        );
      }
      codec = await descriptor.instantiateCodec(
        targetWidth: math.min(_analysisWidth, descriptor.width),
      );
      image = (await codec.getNextFrame()).image;
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (pixels == null) return const VehiclePhotoInspection();
      return VehiclePhotoInspection(
        issues: measurePhotoQuality(
          pixels.buffer.asUint8List(),
          width: image.width,
          height: image.height,
        ).issues,
      );
    } catch (_) {
      return const VehiclePhotoInspection(
        problem: "This photo couldn't be read. Please retake it.",
      );
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  static bool _isJpeg(List<int> h) =>
      h.length >= 3 && h[0] == 0xFF && h[1] == 0xD8 && h[2] == 0xFF;

  static bool _isPng(List<int> h) =>
      h.length >= 4 &&
      h[0] == 0x89 &&
      h[1] == 0x50 &&
      h[2] == 0x4E &&
      h[3] == 0x47;
}

/// Brightness and sharpness of RGBA pixels, sampled over the central 60%
/// of the frame — where the guide asks for the vehicle — so a plain sky or
/// wall around it doesn't read as blur.
PhotoQuality measurePhotoQuality(
  Uint8List rgba, {
  required int width,
  required int height,
}) {
  double luma(int x, int y) {
    final i = (y * width + x) * 4;
    return 0.299 * rgba[i] + 0.587 * rgba[i + 1] + 0.114 * rgba[i + 2];
  }

  final x0 = (width * 0.2).floor();
  final x1 = (width * 0.8).ceil() - 1;
  final y0 = (height * 0.2).floor();
  final y1 = (height * 0.8).ceil() - 1;
  // About 100 samples per axis whatever the resolution.
  final step = math.max(1, math.min(x1 - x0, y1 - y0) ~/ 100);

  var brightness = 0.0;
  var gradient = 0.0;
  var count = 0;
  for (var y = y0; y < y1; y += step) {
    for (var x = x0; x < x1; x += step) {
      final here = luma(x, y);
      brightness += here;
      gradient += (luma(x + 1, y) - here).abs() + (luma(x, y + 1) - here).abs();
      count++;
    }
  }
  if (count == 0) return const PhotoQuality(brightness: 128, sharpness: 0);
  return PhotoQuality(
      brightness: brightness / count, sharpness: gradient / count);
}
