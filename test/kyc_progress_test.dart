import 'dart:convert';

import 'package:delivery_boy/features/rider/auth/models/rider_user_model.dart';
import 'package:delivery_boy/features/rider/dashboard/views/screens/rider_dashboard_screen.dart'
    show riderKycStatusProvider;
import 'package:delivery_boy/features/rider/kyc/models/kyc_progress.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_section.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/rider_me_incomplete.dart';

Map<String, dynamic> _data() =>
    (jsonDecode(riderMeIncompleteJson) as Map<String, dynamic>)['data']
        as Map<String, dynamic>;

RiderMeProfileModel _profile([void Function(Map<String, dynamic>)? edit]) {
  final json = _data();
  edit?.call(json);
  return RiderMeProfileModel.fromJson(json);
}

class _Loaded extends RiderMeProfileNotifier {
  _Loaded(this.profile);
  final RiderMeProfileModel profile;

  @override
  RiderMeProfileState build() => RiderMeProfileState(
        status: RiderMeProfileStatus.loaded,
        profile: profile,
      );
}

KycStatus _statusFor(RiderMeProfileModel profile) {
  final container = ProviderContainer(overrides: [
    riderMeProfileProvider.overrideWith(() => _Loaded(profile)),
  ]);
  addTearDown(container.dispose);
  return container.read(riderKycStatusProvider);
}

void main() {
  group('RiderMeProfileModel.fromJson (nested /rider/me shape)', () {
    test('flattens the nested groups', () {
      final p = _profile();
      expect(p.plateNumber, 'GR42');
      expect(p.vehicleTypeId, 1);
      expect(p.vehicleYear, 2025);
      expect(p.vehicleOwnership, 'owned');
      expect(p.idType, 'ghana_card');
      expect(p.idNumber, isNull);
      expect(p.city, 'Accra');
      expect(p.photoUrl, startsWith('https://api.bagyesrushdelivery.com/'));
    });

    test('reads the server’s completeness and gate', () {
      final p = _profile();
      expect(p.status, 'pending_review');
      expect(p.isProfileComplete, isFalse);
      expect(p.canGoOnline, isFalse);
      expect(p.missingProfileFields, hasLength(15));
      expect(p.documents, hasLength(10));
      expect(p.documents['rider_permit']!.required, isFalse);
      expect(p.payout.isConfigured, isFalse);
      expect(p.agreementNeedsReacceptance, isTrue);
    });
  });

  group('KycProgress.fromProfile', () {
    test('groups the server’s missing fields into steps', () {
      final progress = KycProgress.fromProfile(_profile());
      List<String> missingIn(KycSection s) =>
          progress.progressOf(s).missingFields;

      expect(missingIn(KycSection.personal),
          ['date_of_birth', 'residential_address']);
      expect(missingIn(KycSection.identity), ['id_number']);
      expect(missingIn(KycSection.licence), hasLength(3));
      expect(missingIn(KycSection.vehicle),
          ['vehicle_make_id', 'vehicle_model_id']);
      expect(missingIn(KycSection.insurance), hasLength(3));
      expect(missingIn(KycSection.emergencyContact), hasLength(3));
      expect(missingIn(KycSection.payout), ['payout_details']);
    });

    test('counts a step done only when the server has nothing outstanding',
        () {
      final progress = KycProgress.fromProfile(_profile());

      // Only the photo is done; every document is already uploaded.
      expect(progress.progressOf(KycSection.photo).state, KycSectionState.done);
      expect(progress.completedCount, 1);
      expect(progress.totalCount, 8, reason: 'no "other" step without extras');
      expect(
        progress.sections.every((s) => s.pendingDocuments.isEmpty),
        isTrue,
      );
      expect(progress.canSubmitForReview, isFalse);
    });

    test('puts a required, missing document in its own step', () {
      final progress = KycProgress.fromProfile(_profile((json) {
        (json['documents'] as Map)['drivers_licence_back'] = {
          'uploaded': false,
          'required': true,
        };
      }));

      expect(
        progress.progressOf(KycSection.licence).pendingDocuments,
        ['drivers_licence_back'],
      );
    });

    test('surfaces requirements the app doesn’t know as "other"', () {
      final progress = KycProgress.fromProfile(_profile((json) {
        (json['missing_profile_fields'] as List).add('tax_clearance');
        (json['documents'] as Map)['police_report'] = {
          'uploaded': false,
          'required': true,
        };
      }));

      final other = progress.progressOf(KycSection.other);
      expect(other.missingFields, ['tax_clearance']);
      expect(other.pendingDocuments, ['police_report']);
      expect(progress.totalCount, 9);
    });

    test('guides through outstanding steps in order, wrapping round', () {
      final progress = KycProgress.fromProfile(_profile());

      expect(progress.nextSectionNeedingAction(), KycSection.personal);
      expect(
        progress.nextSectionNeedingAction(after: KycSection.personal),
        KycSection.identity,
      );
      expect(
        progress.nextSectionNeedingAction(after: KycSection.payout),
        KycSection.personal,
      );
    });

    test('is ready to submit once the server says complete', () {
      final progress = KycProgress.fromProfile(_profile((json) {
        json['is_profile_complete'] = true;
        json['missing_profile_fields'] = <String>[];
      }));

      expect(progress.nextSectionNeedingAction(), isNull);
      expect(progress.canSubmitForReview, isTrue);
    });
  });

  group('riderKycStatusProvider', () {
    test('an incomplete profile is not "under review", whatever its status',
        () {
      expect(_statusFor(_profile()), KycStatus.notStarted);
    });

    test('a complete pending profile is under review', () {
      final status = _statusFor(_profile((json) {
        json['is_profile_complete'] = true;
        json['missing_profile_fields'] = <String>[];
      }));
      expect(status, KycStatus.pendingReview);
    });

    test('the server’s go-online gate means approved', () {
      final status = _statusFor(_profile((json) {
        json['can_go_online'] = true;
      }));
      expect(status, KycStatus.approved);
    });

    test('a rejection is reported even while incomplete', () {
      final status = _statusFor(_profile((json) {
        json['status'] = 'rejected';
      }));
      expect(status, KycStatus.rejected);
    });
  });
}
