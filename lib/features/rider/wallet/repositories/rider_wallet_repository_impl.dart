import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/features/rider/wallet/models/rider_wallet_model.dart';
import 'package:delivery_boy/features/rider/wallet/repositories/rider_wallet_repository.dart';
import 'package:delivery_boy/features/rider/wallet/services/rider_wallet_api_service.dart';

class RiderWalletRepositoryImpl implements RiderWalletRepository {
  final RiderWalletApiService _api;

  RiderWalletRepositoryImpl(this._api);

  @override
  Future<Either<Failure, RiderWalletModel>> getEarnings(String userId) =>
      _run(() async {
        final response = await _api.getEarnings(userId);
        final body = response.data as Map<String, dynamic>;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Failed to load earnings');
        }
        return RiderWalletModel.fromJson(body['data'] as Map<String, dynamic>);
      });

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ??
          e.message ??
          'Request failed';
      return Left(ServerFailure(msg));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
