import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/features/rider/legal/models/legal_document_model.dart';
import 'package:delivery_boy/features/rider/legal/repositories/legal_document_repository.dart';

/// The current rider agreement — `GET /rider-agreement`, public. Errors
/// surface as the [Failure] itself (same fold-and-throw shape as
/// `payoutProvidersProvider`).
final riderAgreementProvider =
    FutureProvider.autoDispose<LegalDocumentModel>((ref) async {
  final result = await sl<LegalDocumentRepository>().getRiderAgreement();
  return result.fold((failure) => throw failure, (doc) => doc);
});
