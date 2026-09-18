import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/network/api_error_parser.dart';
import 'package:delivery_boy/core/network/request_error_message.dart';
import 'package:delivery_boy/core/utils/json_utils.dart';
import 'package:delivery_boy/features/rider/profile/models/payout_provider_model.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/profile/repositories/rider_me_profile_repository.dart';
import 'package:delivery_boy/features/rider/profile/services/rider_me_profile_api_service.dart';

class RiderMeProfileRepositoryImpl implements RiderMeProfileRepository {
  final RiderMeProfileApiService _api;

  RiderMeProfileRepositoryImpl(this._api);

  @override
  Future<Either<Failure, RiderMeProfileModel>> getMe() => _run(() async {
        final response = await _api.getMe();
        return RiderMeProfileModel.fromJson(_asMap(response.data));
      });

  @override
  Future<Either<Failure, RiderMeProfileModel>> updateProfile(
          Map<String, dynamic> data) =>
      _run(() async {
        final response = await _api.updateProfile(data);
        return RiderMeProfileModel.fromJson(_asMap(response.data));
      });

  @override
  Future<Either<Failure, void>> acceptAgreement({
    required bool acceptTerms,
    required bool consentToVerification,
    String? termsVersion,
  }) =>
      _run(() => _api.acceptAgreement(
            acceptTerms: acceptTerms,
            consentToVerification: consentToVerification,
            termsVersion: termsVersion,
          ));

  @override
  Future<Either<Failure, void>> setAvailability(bool isOnline) =>
      _run(() => _api.setAvailability(isOnline));

  @override
  Future<Either<Failure, RiderMeDocumentModel>> uploadDocument({
    required String type,
    required String filePath,
  }) =>
      _run(() async {
        final response =
            await _api.uploadDocument(type: type, filePath: filePath);
        return RiderMeDocumentModel.fromJson(
          _asMap(response.data),
          fallbackType: type,
        );
      });

  @override
  Future<Either<Failure, RiderMeDocumentModel>> getDocument(String type) =>
      _run(() async {
        final response = await _api.getDocument(type);
        return RiderMeDocumentModel.fromJson(
          _asMap(response.data),
          fallbackType: type,
        );
      });

  @override
  Future<Either<Failure, void>> updateLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speedKph,
    int? accuracyM,
  }) =>
      _run(() => _api.updateLocation(
            latitude: latitude,
            longitude: longitude,
            heading: heading,
            speedKph: speedKph,
            accuracyM: accuracyM,
          ));

  @override
  Future<Either<Failure, void>> updateLocationBatch(
    List<RiderMeLocationPing> pings,
  ) =>
      _run(() => _api.updateLocationBatch(pings));

  @override
  Future<Either<Failure, RiderMeProfileModel>> updatePayout({
    required String currentPassword,
    int? payoutProviderId,
    String? accountNumber,
    String? accountName,
    int? momoProviderId,
    String? mobileMoneyNumber,
  }) =>
      _run(() async {
        final response = await _api.updatePayout(
          currentPassword: currentPassword,
          payoutProviderId: payoutProviderId,
          accountNumber: accountNumber,
          accountName: accountName,
          momoProviderId: momoProviderId,
          mobileMoneyNumber: mobileMoneyNumber,
        );
        return RiderMeProfileModel.fromJson(_asMap(response.data));
      });

  @override
  Future<Either<Failure, String?>> uploadPhoto(String filePath) =>
      _run(() async {
        final response = await _api.uploadPhoto(filePath);
        final body = _asMap(response.data);
        return nonEmptyString(body['profile_photo_url']) ??
            nonEmptyString(body['photo_url']) ??
            nonEmptyString(body['url']);
      });

  @override
  Future<Either<Failure, void>> submitForReview() =>
      _run(() => _api.submitForReview());

  @override
  Future<Either<Failure, List<PayoutProviderModel>>> getPayoutProviders() =>
      _run(() async {
        final response = await _api.getPayoutProviders();
        final raw = response.data;
        final list = raw is Map ? raw['data'] : raw;
        if (list is! List) return const <PayoutProviderModel>[];
        return list
            .whereType<Map>()
            .map((e) => PayoutProviderModel.fromJson(e.cast<String, dynamic>()))
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      });

  /// Unwraps a Laravel API Resource envelope (`{"data": {...}}`); falls
  /// back to the raw body if it isn't wrapped.
  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return raw['data'] as Map<String, dynamic>;
    }
    return (raw as Map?)?.cast<String, dynamic>() ?? const {};
  }

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
