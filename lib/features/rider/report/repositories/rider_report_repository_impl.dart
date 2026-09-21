import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/network/api_error_parser.dart';
import 'package:delivery_boy/core/network/request_error_message.dart';
import 'package:delivery_boy/features/rider/report/models/rider_report_model.dart';
import 'package:delivery_boy/features/rider/report/repositories/rider_report_repository.dart';
import 'package:delivery_boy/features/rider/report/services/rider_report_api_service.dart';

class RiderReportRepositoryImpl implements RiderReportRepository {
  final RiderReportApiService _api;

  RiderReportRepositoryImpl(this._api);

  @override
  Future<Either<Failure, List<RiderReportModel>>> getReports() =>
      _run(() async {
        final response = await _api.getReports();
        return _asList(response.data)
            .map((e) => RiderReportModel.fromJson(e))
            .toList();
      });

  @override
  Future<Either<Failure, RiderReportModel>> getReportById(int id) =>
      _run(() async {
        final response = await _api.getReportById(id);
        return RiderReportModel.fromJson(_asMap(response.data));
      });

  @override
  Future<Either<Failure, RiderReportReasonCatalog>> getReportReasons() =>
      _run(() async {
        final response = await _api.getReportReasons();
        return RiderReportReasonCatalog.fromJson(_asMap(response.data));
      });

  @override
  Future<Either<Failure, RiderReportModel>> submitReport({
    required RiderReportTargetType targetType,
    int? orderId,
    required String targetName,
    String? targetPhone,
    required String reasonCode,
    required String reasonLabel,
    required String description,
    List<File> attachments = const [],
  }) =>
      _run(() async {
        final response = await _api.submitReport(
          targetType: targetType,
          orderId: orderId,
          targetName: targetName,
          targetPhone: targetPhone,
          reasonCode: reasonCode,
          reasonLabel: reasonLabel,
          description: description,
          attachments: attachments,
        );
        return RiderReportModel.fromJson(_asMap(response.data));
      });

  /// Unwraps a Laravel API Resource envelope (`{"data": {...}}`); falls
  /// back to the raw body if it isn't wrapped.
  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return raw['data'] as Map<String, dynamic>;
    }
    return (raw as Map?)?.cast<String, dynamic>() ?? const {};
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

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on DioException catch (e) {
      final msg = dioErrorMessage(e);
      final fieldErrors = apiFieldErrorsFrom(e.response?.data);
      if (fieldErrors != null) {
        return Left(ValidationFailure(msg, fieldErrors));
      }
      return Left(ServerFailure(msg));
    } catch (e, s) {
      return Left(ServerFailure(unexpectedErrorMessage(e, s)));
    }
  }
}
