import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/network/request_error_message.dart';
import 'package:delivery_boy/features/rider/home/models/rider_banner_model.dart';
import 'package:delivery_boy/features/rider/home/repositories/rider_banner_repository.dart';
import 'package:delivery_boy/features/rider/home/services/rider_banner_api_service.dart';

class RiderBannerRepositoryImpl implements RiderBannerRepository {
  final RiderBannerApiService _api;

  RiderBannerRepositoryImpl(this._api);

  @override
  Future<Either<Failure, List<RiderBannerModel>>> getBanners() async {
    try {
      final response = await _api.getBanners();
      final banners = _asList(response.data)
          .map((e) => RiderBannerModel.fromJson(e))
          .where((b) => b.placement == 'home')
          .toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      return Right(banners);
    } on DioException catch (e) {
      return Left(ServerFailure(dioErrorMessage(e)));
    } catch (e, s) {
      return Left(ServerFailure(unexpectedErrorMessage(e, s)));
    }
  }

  /// Unwraps a Laravel paginated collection envelope
  /// (`{"data": {"items": [...], "pagination": {...}}}`), a plain
  /// collection envelope (`{"data": [...]}`), or a bare JSON array.
  List<Map<String, dynamic>> _asList(dynamic raw) {
    final data = raw is Map<String, dynamic> ? raw['data'] : raw;
    final list = data is Map<String, dynamic> ? data['items'] : data;
    return (list is List ? list : const [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }
}
