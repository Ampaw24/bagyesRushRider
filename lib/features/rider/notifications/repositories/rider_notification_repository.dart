import 'package:dartz/dartz.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/features/rider/notifications/models/rider_notification_model.dart';

abstract class RiderNotificationRepository {
  Future<Either<Failure, List<RiderNotificationModel>>> getNotifications();
  Future<Either<Failure, void>> markRead(String id);
  Future<Either<Failure, void>> markAllRead();
  Future<Either<Failure, void>> deleteNotification(String id);
}
