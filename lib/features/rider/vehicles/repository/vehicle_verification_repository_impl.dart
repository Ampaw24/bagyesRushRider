import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/network/api_error_parser.dart';
import 'package:delivery_boy/core/network/request_error_message.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_capture.dart';
import 'package:delivery_boy/features/rider/vehicles/repository/vehicle_verification_repository.dart';
import 'package:delivery_boy/features/rider/vehicles/service/rider_vehicle_photo_api_service.dart';

const _sessionExpired = 'Your session has expired. Please sign in again.';
const _unavailable =
    "Vehicle photos can't be saved right now. Please update the app and try again.";
const _conflict = 'Vehicle already registered. This vehicle appears to be '
    'linked to another rider account — contact support if you believe '
    'this is incorrect.';
const _serverDown =
    'Something went wrong on our end. Please try again shortly.';

class VehicleVerificationRepositoryImpl
    implements VehicleVerificationRepository {
  final RiderVehiclePhotoApiService _api;

  VehicleVerificationRepositoryImpl(this._api);

  @override
  Future<Either<Failure, RiderMeProfileModel?>> uploadPhoto(
    VehicleCaptureType type,
    String filePath, {
    void Function(double fraction)? onProgress,
  }) =>
      _run(
          type,
          () => _api.uploadPhoto(
                side: type.apiKey,
                filePath: filePath,
                onSendProgress: onProgress == null
                    ? null
                    : (sent, total) {
                        if (total > 0) onProgress(sent / total);
                      },
              ));

  @override
  Future<Either<Failure, RiderMeProfileModel?>> deletePhoto(
    VehicleCaptureType type,
  ) =>
      _run(type, () => _api.deletePhoto(type.apiKey));

  Future<Either<Failure, RiderMeProfileModel?>> _run(
    VehicleCaptureType type,
    Future<Response<dynamic>> Function() send,
  ) async {
    if (!VehicleVerificationRepository.supportedCaptureTypes.contains(type)) {
      return const Left(ServerFailure(_unavailable));
    }
    try {
      final response = await send();
      return Right(_profileFrom(response.data));
    } on DioException catch (e) {
      return Left(_failureFrom(e));
    } catch (e, s) {
      return Left(ServerFailure(unexpectedErrorMessage(e, s)));
    }
  }

  /// The profile from `{success, data: {...}}`, or null if the body isn't
  /// one — the docs only promise the `data.vehicle.photos` part of it.
  RiderMeProfileModel? _profileFrom(dynamic body) {
    final data = body is Map ? body['data'] : null;
    if (data is! Map) return null;
    final profile = RiderMeProfileModel.fromJson(data.cast<String, dynamic>());
    return profile.id == null ? null : profile;
  }

  /// Fixed wording for the statuses whose body is unhelpful to a rider —
  /// a 404's "The route … could not be found", a 5xx's exception text — and
  /// for a 409, whose body could name the other account.
  Failure _failureFrom(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) return const SessionExpiredFailure(_sessionExpired);
    if (status == 404) return const ServerFailure(_unavailable);
    if (status == 409) return const ServerFailure(_conflict);
    if (status != null && status >= 500) {
      return const ServerFailure(_serverDown);
    }

    // A 422 carries `errors.photo[0]`, which dioErrorMessage prefers.
    final message = dioErrorMessage(e);
    final fieldErrors = apiFieldErrorsFrom(e.response?.data);
    return fieldErrors == null
        ? ServerFailure(message)
        : ValidationFailure(message, fieldErrors);
  }
}
