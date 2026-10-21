import 'package:dartz/dartz.dart';
import 'package:gopady_rider/core/errors/failures.dart';
import 'package:gopady_rider/features/rider/notifications/models/rider_notification_model.dart';

abstract class RiderNotificationRepository {
  Future<Either<Failure, List<RiderNotificationModel>>> getNotifications();
  Future<Either<Failure, void>> markRead(String id);
  Future<Either<Failure, void>> markAllRead();
  Future<Either<Failure, void>> deleteNotification(String id);
}
