import 'package:delivery_boy/features/rider/auth/models/rider_user_model.dart';
import 'package:delivery_boy/features/rider/dashboard/views/screens/rider_dashboard_screen.dart'
    show kycStatusFrom;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kycStatusFrom', () {
    test('recognises approved spellings', () {
      expect(kycStatusFrom('approved'), KycStatus.approved);
      expect(kycStatusFrom('verified'), KycStatus.approved);
    });

    test('recognises in-review spellings', () {
      for (final v in [
        'pendingReview',
        'pending_review',
        'under_review',
        'pending',
        'submitted',
      ]) {
        expect(kycStatusFrom(v), KycStatus.pendingReview, reason: v);
      }
    });

    test('recognises rejected spellings', () {
      expect(kycStatusFrom('rejected'), KycStatus.rejected);
      expect(kycStatusFrom('declined'), KycStatus.rejected);
    });

    test('falls back to notStarted rather than over-reporting approval', () {
      // The failure mode that matters: an unknown value must never let an
      // unverified rider go online.
      expect(kycStatusFrom(null), KycStatus.notStarted);
      expect(kycStatusFrom(''), KycStatus.notStarted);
      expect(kycStatusFrom('something_new'), KycStatus.notStarted);
      expect(kycStatusFrom('APPROVED'), KycStatus.notStarted);
    });
  });
}
