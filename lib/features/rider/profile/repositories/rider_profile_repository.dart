import 'package:dio/dio.dart';
import 'package:delivery_boy/constant/typedef.dart';
import 'package:delivery_boy/features/rider/auth/models/rider_user_model.dart';

abstract class RiderProfileRepository {
  ResultFuture<RiderUserModel> getProfile(String userId);
  ResultFuture<RiderUserModel> updateCourier(Map<String, dynamic> data);
  ResultFuture<RiderUserModel> uploadDoc(FormData formData);
}
