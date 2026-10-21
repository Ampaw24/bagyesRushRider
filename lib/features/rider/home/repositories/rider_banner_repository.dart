import 'package:dartz/dartz.dart';
import 'package:gopady_rider/core/errors/failures.dart';
import 'package:gopady_rider/features/rider/home/models/rider_banner_model.dart';

abstract class RiderBannerRepository {
  /// Banners for `placement == 'home'`, sorted by `display_order`.
  Future<Either<Failure, List<RiderBannerModel>>> getBanners();
}
