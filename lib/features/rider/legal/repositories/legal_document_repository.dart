import 'package:gopady_rider/constant/typedef.dart';
import 'package:gopady_rider/features/rider/legal/models/legal_document_model.dart';

abstract class LegalDocumentRepository {
  ResultFuture<LegalDocumentModel> getRiderAgreement();
}
