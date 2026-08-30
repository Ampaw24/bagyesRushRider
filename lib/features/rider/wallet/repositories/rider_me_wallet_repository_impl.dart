import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/features/rider/wallet/models/rider_me_wallet_model.dart';
import 'package:delivery_boy/features/rider/wallet/repositories/rider_me_wallet_repository.dart';
import 'package:delivery_boy/features/rider/wallet/services/rider_me_wallet_api_service.dart';

class RiderMeWalletRepositoryImpl implements RiderMeWalletRepository {
  final RiderMeWalletApiService _api;

  RiderMeWalletRepositoryImpl(this._api);

  @override
  Future<Either<Failure, RiderMeWalletModel>> getWallet() => _run(() async {
        final response = await _api.getWallet();
        return RiderMeWalletModel.fromJson(_asMap(response.data));
      });

  @override
  Future<Either<Failure, List<RiderMeWalletTransactionModel>>>
      getTransactions() => _run(() async {
            final response = await _api.getTransactions();
            return _asList(response.data)
                .map((e) => RiderMeWalletTransactionModel.fromJson(e))
                .toList();
          });

  @override
  Future<Either<Failure, List<RiderMeWithdrawalModel>>> getWithdrawals() =>
      _run(() async {
        final response = await _api.getWithdrawals();
        return _asList(response.data)
            .map((e) => RiderMeWithdrawalModel.fromJson(e))
            .toList();
      });

  @override
  Future<Either<Failure, RiderMeWithdrawalModel>> requestWithdrawal(
          num amount) =>
      _run(() async {
        final response = await _api.requestWithdrawal(amount);
        return RiderMeWithdrawalModel.fromJson(_asMap(response.data));
      });

  @override
  Future<Either<Failure, void>> cancelWithdrawal(int withdrawalId) =>
      _run(() => _api.cancelWithdrawal(withdrawalId));

  /// Unwraps a Laravel API Resource envelope (`{"data": {...}}`); falls
  /// back to the raw body if it isn't wrapped.
  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return raw['data'] as Map<String, dynamic>;
    }
    return (raw as Map?)?.cast<String, dynamic>() ?? const {};
  }

  /// Unwraps a Laravel paginated/plain collection envelope
  /// (`{"data": [...]}`); falls back to a bare JSON array.
  List<Map<String, dynamic>> _asList(dynamic raw) {
    final list = (raw is Map<String, dynamic> ? raw['data'] : raw) as List?;
    return (list ?? const [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }

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
