import 'package:delivery_boy/constant/typedef.dart';
import 'package:delivery_boy/features/rider/wallet/models/rider_wallet_model.dart';

abstract class RiderWalletRepository {
  ResultFuture<RiderWalletModel> getEarnings(String userId);
}
