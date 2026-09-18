import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_section.dart';
import 'package:delivery_boy/features/rider/kyc/providers/kyc_providers.dart';

/// Behaviour shared by every checklist step: validate, save, place a 422's
/// messages on the fields that caused them, then carry the rider on to the
/// next step still needing action.
mixin KycSectionFormMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final formKey = GlobalKey<FormState>();
  Map<String, String> _serverErrors = const {};

  KycSection get section;

  /// Server field keys this form shows inline. A rejection naming any other
  /// field also gets a dialog, so it's never silently lost.
  Set<String> get inlineErrorFields => section.fields;

  /// The server's message for [field], until the rider edits it.
  String? serverError(String field) => _serverErrors[field];

  void clearServerError(String field) {
    if (!_serverErrors.containsKey(field)) return;
    setState(() => _serverErrors = {..._serverErrors}..remove(field));
  }

  /// Validates, runs [save], and moves on when it succeeds.
  Future<void> submit(Future<Failure?> Function() save) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_serverErrors.isNotEmpty) setState(() => _serverErrors = const {});
    if (!(formKey.currentState?.validate() ?? true)) return;

    final failure = await save();
    if (!mounted) return;
    if (failure != null) {
      showFailure(failure);
      return;
    }
    HapticFeedback.lightImpact();
    continueToNextStep();
  }

  void showFailure(Failure failure) {
    var placedInline = false;
    if (failure is ValidationFailure) {
      setState(() => _serverErrors = {
            for (final e in failure.errors.entries)
              if (e.value.isNotEmpty) e.key: e.value.first,
          });
      formKey.currentState?.validate();
      placedInline = failure.errors.keys.every(inlineErrorFields.contains);
    }
    if (!placedInline) {
      CustomDialog.showError(
        context: context,
        title: "Couldn't Save",
        subtitle: failure.message,
      );
    }
  }

  /// Stays put if this step still needs something, otherwise opens the next
  /// step needing action — or the checklist, to submit, when none remain.
  void continueToNextStep() {
    final progress = ref.read(kycProgressProvider);
    if (progress == null) {
      context.go(AppRoutes.kyc);
      return;
    }

    final current = progress.progressOf(section);
    if (current.needsAction) {
      final remaining = [...current.missingFields, ...current.pendingDocuments]
          .map(kycLabel)
          .join(', ');
      CustomDialog.showInfo(
        context: context,
        title: 'Almost There',
        subtitle: 'Still needed for this step: $remaining.',
      );
      return;
    }

    final next = progress.nextSectionNeedingAction(after: section);
    if (next == null) {
      context.go(AppRoutes.kyc);
    } else {
      context.pushReplacement(AppRoutes.kycSection(next.slug));
    }
  }
}

final _apiDate = DateFormat('yyyy-MM-dd');

/// The API's date format, e.g. `2031-05-20`.
String kycApiDate(DateTime date) => _apiDate.format(date);

/// Parses the API's dates (plain or ISO timestamps); null when unset.
DateTime? kycParseDate(String? value) =>
    value == null ? null : DateTime.tryParse(value)?.toLocal();
