import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/features/rider/auth/models/rider_user_model.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_form_data.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_submission_result.dart';
import 'package:delivery_boy/features/rider/kyc/repositories/kyc_repository.dart';
import 'package:delivery_boy/features/rider/kyc/services/kyc_api_service.dart';
import 'package:intl/intl.dart';

class KycRepositoryImpl implements KycRepository {
  final KycApiService _api;

  KycRepositoryImpl(this._api);

  @override
  Future<Either<Failure, KycSubmissionResult>> submitKyc({
    required KycFormData formData,
    required Map<String, String> uploadedDocUrls,
  }) =>
      _run(() async {
        final identity = formData.identity;
        final license = formData.license;
        final vehicle = formData.vehicle;

        final payload = {
          // Identity
          'nationalId': identity.nationalId,
          'dateOfBirth': identity.dateOfBirth != null
              ? DateFormat('yyyy-MM-dd').format(identity.dateOfBirth!)
              : null,
          'address': identity.address,
          // License
          'licenseNumber': license.licenseNumber,
          'licenseExpiry': license.expiryDate != null
              ? DateFormat('yyyy-MM-dd').format(license.expiryDate!)
              : null,
          // Vehicle
          'vehicleType': vehicle.vehicleType,
          'vehicleBrand': vehicle.brand,
          'vehicleModel': vehicle.model,
          'plateNumber': vehicle.plateNumber,
          'vehicleColor': vehicle.color,
          // Document remote URLs
          ...uploadedDocUrls,
        };

        final response = await _api.submitKyc(payload);
        final body = response.data as Map<String, dynamic>;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'KYC submission failed');
        }
        return KycSubmissionResult(
          success: true,
          status: KycStatus.pendingReview,
          message: body['message'] as String?,
        );
      });

  @override
  Future<Either<Failure, KycStatus>> getKycStatus(String userId) =>
      _run(() async {
        final response = await _api.getKycStatus(userId);
        final body = response.data as Map<String, dynamic>;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Failed to get KYC status');
        }
        final statusStr = body['data']?['kycStatus'] as String?;
        return _parseStatus(statusStr);
      });

  @override
  Future<Either<Failure, String>> uploadDoc({
    required String docKey,
    required String filePath,
  }) =>
      _run(() async {
        final file = File(filePath);
        final formData = FormData.fromMap({
          'docKey': docKey,
          'file': await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        });
        final response = await _api.uploadKycDoc(formData);
        final body = response.data as Map<String, dynamic>;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Document upload failed');
        }
        // Backend returns the remote URL of the uploaded file
        return body['url'] as String? ?? body['data']?['url'] as String? ?? '';
      });

  KycStatus _parseStatus(String? value) {
    switch (value) {
      case 'pendingReview':
        return KycStatus.pendingReview;
      case 'approved':
        return KycStatus.approved;
      case 'rejected':
        return KycStatus.rejected;
      default:
        return KycStatus.notStarted;
    }
  }

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ??
          e.message ??
          'Request failed';
      return Left(ServerFailure(msg));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
