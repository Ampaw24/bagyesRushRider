import 'package:delivery_boy/constant/typedef.dart';
import 'package:delivery_boy/features/rider/legal/models/legal_document_model.dart';

abstract class LegalDocumentRepository {
  ResultFuture<LegalDocumentModel> getRiderAgreement();
}
