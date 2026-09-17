import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/features/rider/profile/data/rider_document_types.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';

/// Which verification documents are uploaded, keyed by [RiderDocumentType.key].
///
/// Backs the profile completeness UI on the home, profile and onboarding
/// screens — kept in one place so they can never disagree with each other or
/// with [RiderDocumentUploadScreen] about what's still outstanding.
class RiderDocumentCompletionNotifier extends AsyncNotifier<Map<String, bool>> {
  @override
  Future<Map<String, bool>> build() async {
    final profileNotifier = ref.read(riderMeProfileProvider.notifier);
    await profileNotifier.load();
    final profile = ref.read(riderMeProfileProvider).profile;

    final result = <String, bool>{};
    for (final doc in riderDocumentTypes) {
      if (doc.key == 'selfie') {
        result[doc.key] = profile?.photoUrl != null && profile!.photoUrl!.isNotEmpty;
        continue;
      }
      final uploaded = await profileNotifier.getDocument(doc.key);
      result[doc.key] = uploaded?.url != null && uploaded!.url!.isNotEmpty;
    }
    return result;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

final riderDocumentCompletionProvider =
    AsyncNotifierProvider<RiderDocumentCompletionNotifier, Map<String, bool>>(
        RiderDocumentCompletionNotifier.new);
