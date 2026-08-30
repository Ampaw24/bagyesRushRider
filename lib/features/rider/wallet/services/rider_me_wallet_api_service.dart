import 'package:dio/dio.dart';
import 'package:delivery_boy/core/network/api_endpoints.dart';

/// Raw Dio calls for the `/rider/me/wallet` and `/rider/me/withdrawals`
/// API — see the "v1 / rider" Postman collection (wallet #1-5).
class RiderMeWalletApiService {
  final Dio _dio;

  RiderMeWalletApiService(this._dio);

  Future<Response<dynamic>> getWallet() =>
      _dio.get(ApiEndpoints.riderMeWallet);

  Future<Response<dynamic>> getTransactions() =>
      _dio.get(ApiEndpoints.riderMeWalletTransactions);

  Future<Response<dynamic>> getWithdrawals() =>
      _dio.get(ApiEndpoints.riderMeWithdrawals);

  Future<Response<dynamic>> requestWithdrawal(num amount) =>
      _dio.post(ApiEndpoints.riderMeWithdrawals, data: {'amount': amount});

  Future<Response<dynamic>> cancelWithdrawal(int id) =>
      _dio.patch(ApiEndpoints.riderMeWithdrawalCancel(id));
}
