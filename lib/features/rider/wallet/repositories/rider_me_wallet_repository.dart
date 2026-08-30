import 'package:delivery_boy/constant/typedef.dart';
import 'package:delivery_boy/features/rider/wallet/models/rider_me_wallet_model.dart';

/// Contract for the `/rider/me/wallet` and `/rider/me/withdrawals` API —
/// see the "v1 / rider" Postman collection (wallet #1-5).
abstract class RiderMeWalletRepository {
  ResultFuture<RiderMeWalletModel> getWallet();
  ResultFuture<List<RiderMeWalletTransactionModel>> getTransactions();
  ResultFuture<List<RiderMeWithdrawalModel>> getWithdrawals();
  ResultFuture<RiderMeWithdrawalModel> requestWithdrawal(num amount);
  ResultFuture<void> cancelWithdrawal(int withdrawalId);
}
