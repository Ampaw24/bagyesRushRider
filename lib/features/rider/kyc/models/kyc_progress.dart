import 'package:equatable/equatable.dart';

import 'package:delivery_boy/features/rider/kyc/models/kyc_section.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';

enum KycSectionState {
  /// The server still needs something from this section.
  actionRequired,

  /// Nothing outstanding.
  done,

  /// Nothing required, but not filled in either (e.g. no profile photo on a
  /// backend that doesn't demand one).
  optional,
}

/// Where one [KycSection] stands, derived purely from `/rider/me`.
class KycSectionProgress extends Equatable {
  final KycSection section;

  /// Server field keys from `missing_profile_fields` in this section.
  final List<String> missingFields;

  /// Document slugs the server marks required but not yet uploaded.
  final List<String> pendingDocuments;

  /// Whether the section has content, for sections the server may not
  /// require at all.
  final bool isFilled;

  const KycSectionProgress({
    required this.section,
    this.missingFields = const [],
    this.pendingDocuments = const [],
    this.isFilled = true,
  });

  int get outstandingCount => missingFields.length + pendingDocuments.length;

  KycSectionState get state {
    if (outstandingCount > 0) return KycSectionState.actionRequired;
    return isFilled ? KycSectionState.done : KycSectionState.optional;
  }

  bool get needsAction => state == KycSectionState.actionRequired;

  /// "2 details · 1 document", for the checklist row.
  String get summary {
    final parts = [
      if (missingFields.isNotEmpty)
        '${missingFields.length} ${missingFields.length == 1 ? 'detail' : 'details'}',
      if (pendingDocuments.isNotEmpty)
        '${pendingDocuments.length} ${pendingDocuments.length == 1 ? 'document' : 'documents'}',
    ];
    return parts.join(' · ');
  }

  @override
  List<Object?> get props => [section, missingFields, pendingDocuments, isFilled];
}

/// The rider's verification checklist.
///
/// Built only from what `/rider/me` reports — `missing_profile_fields`, the
/// `documents` map and `is_profile_complete` — so the home card, profile
/// badge, checklist and go-online gate can never disagree with each other
/// or with the backend.
class KycProgress extends Equatable {
  final List<KycSectionProgress> sections;

  /// The server's own verdict; the only thing that gates submission.
  final bool isProfileComplete;

  final String? status;
  final String? statusLabel;
  final String? rejectionReason;
  final bool canGoOnline;
  final List<String> expiredCredentials;
  final List<String> expiringCredentials;

  const KycProgress({
    required this.sections,
    required this.isProfileComplete,
    this.status,
    this.statusLabel,
    this.rejectionReason,
    this.canGoOnline = false,
    this.expiredCredentials = const [],
    this.expiringCredentials = const [],
  });

  factory KycProgress.fromProfile(RiderMeProfileModel profile) {
    final missing = <KycSection, List<String>>{};
    for (final field in profile.missingProfileFields) {
      // `documents` is the aggregate flag; the per-slug map below is the
      // detail, so it's the one that places items in sections.
      if (field == 'documents') continue;
      missing.putIfAbsent(KycSection.forField(field), () => []).add(field);
    }

    final pendingDocs = <KycSection, List<String>>{};
    for (final entry in profile.documents.entries) {
      if (entry.value.required && !entry.value.uploaded) {
        pendingDocs
            .putIfAbsent(KycSection.forDocument(entry.key), () => [])
            .add(entry.key);
      }
    }

    final sections = [
      for (final section in KycSection.values)
        if (section != KycSection.other ||
            missing.containsKey(section) ||
            pendingDocs.containsKey(section))
          KycSectionProgress(
            section: section,
            missingFields: missing[section] ?? const [],
            pendingDocuments: pendingDocs[section] ?? const [],
            isFilled: section != KycSection.photo || profile.photoUrl != null,
          ),
    ];

    return KycProgress(
      sections: sections,
      isProfileComplete: profile.isProfileComplete,
      status: profile.status,
      statusLabel: profile.statusLabel,
      rejectionReason: profile.rejectionReason,
      canGoOnline: profile.canGoOnline,
      expiredCredentials: profile.expiredCredentials,
      expiringCredentials: profile.expiringCredentials,
    );
  }

  int get completedCount => sections.where((s) => !s.needsAction).length;

  int get totalCount => sections.length;

  double get fraction => totalCount == 0 ? 1 : completedCount / totalCount;

  int get outstandingSectionCount => totalCount - completedCount;

  bool get isRejected => status == 'rejected' || rejectionReason != null;

  bool get isApproved => canGoOnline || status == 'approved';

  /// Submission is the server's call: every section can look done while it
  /// still reports the profile incomplete.
  bool get canSubmitForReview => isProfileComplete && !isApproved;

  KycSectionProgress progressOf(KycSection section) =>
      sections.firstWhere(
        (s) => s.section == section,
        orElse: () => KycSectionProgress(section: section),
      );

  /// The first section still needing action after [after], wrapping round
  /// to the start — the guided flow's "Continue" target. Null when nothing
  /// is outstanding.
  KycSection? nextSectionNeedingAction({KycSection? after}) {
    final pending =
        sections.where((s) => s.needsAction).map((s) => s.section).toList();
    if (pending.isEmpty) return null;
    if (after == null) return pending.first;
    return pending.firstWhere(
      (s) => s.index > after.index,
      orElse: () => pending.first,
    );
  }

  @override
  List<Object?> get props => [
        sections,
        isProfileComplete,
        status,
        rejectionReason,
        canGoOnline,
        expiredCredentials,
        expiringCredentials,
      ];
}
