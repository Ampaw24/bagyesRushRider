import 'package:delivery_boy/constant/typedef.dart';

abstract class RiderTrackingRepository {
  ResultFuture<void> updateLocation(Map<String, dynamic> data);
}
