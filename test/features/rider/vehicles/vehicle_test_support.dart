import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_capture.dart';
import 'package:delivery_boy/features/rider/vehicles/repository/vehicle_verification_repository.dart';

import '../../../fixtures/rider_me_incomplete.dart';

const frontUrl = 'https://cdn.example.com/vehicles/front.jpg';
const backUrl = 'https://cdn.example.com/vehicles/back.jpg';

/// The real `/rider/me` fixture's `data`, with [edit] applied.
Map<String, dynamic> riderMeData([void Function(Map<String, dynamic>)? edit]) {
  final data = (jsonDecode(riderMeIncompleteJson)
      as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  edit?.call(data);
  return data;
}

/// A rider profile with the given vehicle photos (API side → URL) and
/// account state.
RiderMeProfileModel riderProfile({
  int id = 1,
  Map<String, String?> photos = const {},
  String status = 'pending_review',
  bool canGoOnline = false,
  String? rejectionReason,
  String vehicleType = 'motorbike',
  String vehicleTypeLabel = 'Motorbike',
  String? make,
  String? model,
  int? makeId,
  int? modelId,
}) =>
    RiderMeProfileModel.fromJson(riderMeData((json) {
      json['id'] = id;
      json['status'] = status;
      json['can_go_online'] = canGoOnline;
      json['rejection_reason'] = rejectionReason;
      final vehicle = json['vehicle'] as Map<String, dynamic>;
      vehicle['type'] = vehicleType;
      vehicle['type_label'] = vehicleTypeLabel;
      vehicle['photos'] = photos;
      vehicle['make'] = make;
      vehicle['model'] = model;
      vehicle['make_id'] = makeId;
      vehicle['model_id'] = modelId;
    }));

/// `/rider/me` as a fake server holds it; [load] re-reads it.
class FakeProfileServer {
  FakeProfileServer(this.current);
  RiderMeProfileModel current;
  int loads = 0;
}

class ServerBackedProfile extends RiderMeProfileNotifier {
  ServerBackedProfile(this.server);
  final FakeProfileServer server;

  @override
  RiderMeProfileState build() => RiderMeProfileState(
        status: RiderMeProfileStatus.loaded,
        profile: server.current,
      );

  @override
  Future<void> load() async {
    server.loads++;
    state = state.copyWith(profile: server.current);
  }

  void signInAs(RiderMeProfileModel profile) {
    server.current = profile;
    state = state.copyWith(profile: profile);
  }
}

/// Records calls and answers each from [respond] — by default, the server
/// storing the photo and returning the updated profile.
class FakeVehicleRepo implements VehicleVerificationRepository {
  FakeVehicleRepo(this.server);

  final FakeProfileServer server;
  final uploads = <VehicleCaptureType>[];
  final deletes = <VehicleCaptureType>[];

  /// Overrides the result for an upload of the given type.
  final Map<VehicleCaptureType, Either<Failure, RiderMeProfileModel?>>
      uploadResults = {};

  /// When set, uploads wait for it — to observe the in-flight state.
  Completer<void>? gate;

  /// Completes when the first upload request is made.
  final firstUpload = Completer<void>();

  @override
  Future<Either<Failure, RiderMeProfileModel?>> uploadPhoto(
    VehicleCaptureType type,
    String filePath, {
    void Function(double fraction)? onProgress,
  }) async {
    uploads.add(type);
    if (!firstUpload.isCompleted) firstUpload.complete();
    onProgress?.call(0.5);
    await gate?.future;
    final override = uploadResults[type];
    if (override != null) return override;
    server.current = _withPhoto(server.current, type.apiKey, '$type.jpg');
    return Right(server.current);
  }

  @override
  Future<Either<Failure, RiderMeProfileModel?>> deletePhoto(
    VehicleCaptureType type,
  ) async {
    deletes.add(type);
    server.current = _withPhoto(server.current, type.apiKey, null);
    return Right(server.current);
  }
}

RiderMeProfileModel _withPhoto(
  RiderMeProfileModel profile,
  String side,
  String? url,
) {
  final photos = <String, String?>{...profile.vehiclePhotos, side: url};
  return riderProfile(
    id: profile.id!,
    photos: photos,
    status: profile.status ?? 'pending_review',
    canGoOnline: profile.canGoOnline,
    rejectionReason: profile.rejectionReason,
    makeId: profile.vehicleMakeId,
    modelId: profile.vehicleModelId,
  );
}

/// A file starting with JPEG's magic bytes — enough for the upload checks,
/// which read the header rather than trusting the name.
Future<String> tempJpeg(Directory dir, String name) async {
  final file = File('${dir.path}/$name.jpg');
  await file.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0, 0, 0x10, 0x4A, 0x46]);
  return file.path;
}
