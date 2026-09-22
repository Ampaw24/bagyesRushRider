import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/network/request_error_message.dart';
import 'package:delivery_boy/features/rider/legal/models/legal_document_model.dart';
import 'package:delivery_boy/features/rider/legal/repositories/legal_document_repository.dart';
import 'package:delivery_boy/features/rider/legal/services/legal_document_api_service.dart';

class LegalDocumentRepositoryImpl implements LegalDocumentRepository {
  final LegalDocumentApiService _api;

  LegalDocumentRepositoryImpl(this._api);

  @override
  Future<Either<Failure, LegalDocumentModel>> getRiderAgreement() =>
      _run(() async {
        final response = await _api.getRiderAgreement();
        return LegalDocumentModel.fromJson(_asMap(response.data));
      });

  /// Unwraps a Laravel API Resource envelope (`{"data": {...}}`); falls
  /// back to the raw body if it isn't wrapped.
  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return raw['data'] as Map<String, dynamic>;
    }
    return (raw as Map?)?.cast<String, dynamic>() ?? const {};
  }

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on DioException catch (e) {
      return Left(ServerFailure(dioErrorMessage(e)));
    } catch (e, s) {
      return Left(ServerFailure(unexpectedErrorMessage(e, s)));
    }
  }
}
