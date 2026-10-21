import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gopady_rider/core/di/service_locator.dart';
import 'package:gopady_rider/core/services/user_session_manager.dart';
import 'package:gopady_rider/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:gopady_rider/features/rider/profile/providers/rider_me_profile_providers.dart';

/// The rider's profile photo URL, or null when they have none — the single
/// source for every avatar in the app, so they always agree.
///
/// Sources, freshest first:
/// 1. `GET /rider/me` — also patched straight after a photo upload.
/// 2. The user from this run's login/registration.
/// 3. The persisted session, so the photo shows on a cold start before
///    `/rider/me` has loaded.
final riderAvatarUrlProvider = Provider<String?>((ref) {
  final fromRiderMe =
      ref.watch(riderMeProfileProvider.select((s) => s.profile?.photoUrl));
  if (fromRiderMe != null) return fromRiderMe;

  final fromAuth =
      ref.watch(riderAuthProvider.select((s) => s.user?.profilePhotoUrl));
  return fromAuth ?? sl<UserSessionManager>().profilePhotoUrl;
});
