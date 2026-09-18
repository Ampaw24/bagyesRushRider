import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:delivery_boy/constant/typedef.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/network/api_error_parser.dart';
import 'package:delivery_boy/core/network/request_error_message.dart';
import 'package:delivery_boy/features/rider/notifications/repositories/device_token_repository.dart';
import 'package:delivery_boy/features/rider/notifications/services/device_token_api_service.dart';

class DeviceTokenRepositoryImpl implements DeviceTokenRepository {
  final DeviceTokenApiService _api;

  DeviceTokenRepositoryImpl(this._api);

  @override
  ResultFuture<void> register({
    required String token,
    required String platform,
    required String deviceName,
  }) =>
      _run(() => _api.register(
            token: token,
            platform: platform,
            deviceName: deviceName,
          ));

  @override
  ResultFuture<void> unregister({required String token}) =>
      _run(() => _api.unregister(token: token));

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on DioException catch (e) {
      final data = e.response?.data;
      // The server's per-field message when there is one; never Dio's
      // developer text (see dioErrorMessage).
      final msg = dioErrorMessage(e);

      final fieldErrors = apiFieldErrorsFrom(data);
      if (fieldErrors != null) {
        return Left(ValidationFailure(msg, fieldErrors));
      }
      return Left(ServerFailure(msg));
    } catch (e, s) {
      return Left(ServerFailure(unexpectedErrorMessage(e, s)));
    }
  }
}
