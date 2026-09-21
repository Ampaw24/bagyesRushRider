import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/features/rider/report/models/rider_report_flow_args.dart';
import 'package:delivery_boy/features/rider/report/models/rider_report_model.dart';
import 'package:delivery_boy/features/rider/report/repositories/rider_report_repository.dart';
import 'package:delivery_boy/features/rider/shared/rider_me_action_status.dart';

/// The steps of the report wizard, in order. A given run only shows a
/// subset — see [RiderReportFormState.steps].
enum RiderReportWizardStep { targetType, orderLink, reason, details }

/// Human-readable fallback for [RiderReportFormState.targetName] when the
/// rider picks a category but skips (or has no) order to link — a rider
/// has no vendor/customer id or name outside of an order, so this is the
/// only identity a `general`-adjacent report can carry.
String _defaultTargetName(RiderReportTargetType type) => switch (type) {
      RiderReportTargetType.vendor => 'Vendor',
      RiderReportTargetType.customer => 'Customer',
      RiderReportTargetType.orderIssue => 'Order issue',
      RiderReportTargetType.general => 'General',
    };

class RiderReportFormState extends Equatable {
  final bool targetTypeLocked;

  /// Whether the target fields arrived pre-filled from a contextual entry
  /// point (e.g. an order's detail sheet) — when true, the order-link step
  /// is skipped entirely regardless of category.
  final bool targetLocked;

  final int stepIndex;

  final RiderReportTargetType? targetType;
  final int? orderId;
  final String? targetName;
  final String? targetImageUrl;
  final String? targetPhone;

  final String? reasonCode;
  final String? reasonLabel;

  final RiderReportReasonCatalog? reasonCatalog;
  final bool reasonsLoading;
  final String? reasonsError;

  final String description;
  final List<File> photos;

  final RiderMeActionStatus submitStatus;
  final String? errorMessage;
  final RiderReportModel? submittedReport;

  const RiderReportFormState({
    required this.targetTypeLocked,
    required this.targetLocked,
    this.stepIndex = 0,
    this.targetType,
    this.orderId,
    this.targetName,
    this.targetImageUrl,
    this.targetPhone,
    this.reasonCode,
    this.reasonLabel,
    this.reasonCatalog,
    this.reasonsLoading = false,
    this.reasonsError,
    this.description = '',
    this.photos = const [],
    this.submitStatus = RiderMeActionStatus.idle,
    this.errorMessage,
    this.submittedReport,
  });

  factory RiderReportFormState.start(RiderReportFlowArgs args) {
    final hasTarget = args.targetName != null && args.targetName!.isNotEmpty;
    return RiderReportFormState(
      targetTypeLocked: args.targetType != null,
      targetLocked: hasTarget,
      targetType: args.targetType,
      orderId: args.orderId,
      targetName: args.targetName,
      targetImageUrl: args.targetImageUrl,
      targetPhone: args.targetPhone,
    );
  }

  List<RiderReportWizardStep> get steps => [
        if (!targetTypeLocked) RiderReportWizardStep.targetType,
        if (!targetLocked && (targetType?.needsOrderLink ?? true))
          RiderReportWizardStep.orderLink,
        RiderReportWizardStep.reason,
        RiderReportWizardStep.details,
      ];

  RiderReportWizardStep get currentStep => steps[stepIndex];
  bool get isFirstStep => stepIndex == 0;
  bool get isLastStep => stepIndex == steps.length - 1;
  double get progress => (stepIndex + 1) / steps.length;

  bool get hasReason => reasonCode != null;
  bool get canSubmit =>
      targetType != null && hasReason && description.trim().length >= 10;

  /// The reason options for the current [targetType], flattened from the
  /// fetched [reasonCatalog].
  List<RiderReportReasonOption> get currentReasons =>
      targetType == null || reasonCatalog == null
          ? const []
          : reasonCatalog!.forTargetType(targetType!);

  RiderReportFormState copyWith({
    int? stepIndex,
    RiderReportTargetType? targetType,
    int? orderId,
    String? targetName,
    String? targetImageUrl,
    String? targetPhone,
    String? reasonCode,
    String? reasonLabel,
    RiderReportReasonCatalog? reasonCatalog,
    bool? reasonsLoading,
    String? reasonsError,
    bool clearReasonsError = false,
    String? description,
    List<File>? photos,
    RiderMeActionStatus? submitStatus,
    String? errorMessage,
    bool clearErrorMessage = false,
    RiderReportModel? submittedReport,
  }) =>
      RiderReportFormState(
        targetTypeLocked: targetTypeLocked,
        targetLocked: targetLocked,
        stepIndex: stepIndex ?? this.stepIndex,
        targetType: targetType ?? this.targetType,
        orderId: orderId ?? this.orderId,
        targetName: targetName ?? this.targetName,
        targetImageUrl: targetImageUrl ?? this.targetImageUrl,
        targetPhone: targetPhone ?? this.targetPhone,
        reasonCode: reasonCode ?? this.reasonCode,
        reasonLabel: reasonLabel ?? this.reasonLabel,
        reasonCatalog: reasonCatalog ?? this.reasonCatalog,
        reasonsLoading: reasonsLoading ?? this.reasonsLoading,
        reasonsError:
            clearReasonsError ? null : (reasonsError ?? this.reasonsError),
        description: description ?? this.description,
        photos: photos ?? this.photos,
        submitStatus: submitStatus ?? this.submitStatus,
        errorMessage:
            clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
        submittedReport: submittedReport ?? this.submittedReport,
      );

  @override
  List<Object?> get props => [
        targetTypeLocked,
        targetLocked,
        stepIndex,
        targetType,
        orderId,
        targetName,
        targetImageUrl,
        targetPhone,
        reasonCode,
        reasonLabel,
        reasonCatalog,
        reasonsLoading,
        reasonsError,
        description,
        photos,
        submitStatus,
        errorMessage,
        submittedReport,
      ];
}

/// Screen-scoped — one fresh instance per report-flow push (mirrors
/// `RiderChatThreadNotifier`), not shared app-wide: the wizard always
/// starts clean for whatever [RiderReportFlowArgs] the entry point passed.
class RiderReportFormNotifier extends AutoDisposeFamilyNotifier<
    RiderReportFormState, RiderReportFlowArgs> {
  RiderReportRepository get _repo => sl<RiderReportRepository>();

  @override
  RiderReportFormState build(RiderReportFlowArgs args) {
    Future.microtask(loadReasons);
    return RiderReportFormState.start(args);
  }

  Future<void> loadReasons() async {
    state = state.copyWith(reasonsLoading: true, clearReasonsError: true);
    final result = await _repo.getReportReasons();
    result.fold(
      (f) => state =
          state.copyWith(reasonsLoading: false, reasonsError: f.message),
      (catalog) => state = state.copyWith(
          reasonCatalog: catalog,
          reasonsLoading: false,
          clearReasonsError: true),
    );
  }

  void selectTargetType(RiderReportTargetType type) {
    state = state.copyWith(
      targetType: type,
      targetName: _defaultTargetName(type),
      orderId: null,
      targetPhone: null,
      reasonCode: null,
      reasonLabel: null,
    );
    goNext();
  }

  /// [orderId] null means "skip — not linking a specific order".
  void selectOrderLink({
    int? orderId,
    required String targetName,
    String? targetPhone,
  }) {
    state = state.copyWith(
      orderId: orderId,
      targetName: targetName,
      targetPhone: targetPhone,
    );
    goNext();
  }

  void selectReason({required String code, required String label}) {
    state = state.copyWith(reasonCode: code, reasonLabel: label);
  }

  void updateDescription(String value) =>
      state = state.copyWith(description: value);

  static const _maxPhotos = 5;

  void addPhotos(List<File> files) {
    final room = _maxPhotos - state.photos.length;
    if (room <= 0) return;
    state = state.copyWith(photos: [...state.photos, ...files.take(room)]);
  }

  void removePhoto(int index) {
    final updated = [...state.photos]..removeAt(index);
    state = state.copyWith(photos: updated);
  }

  void goNext() {
    if (!state.isLastStep)
      state = state.copyWith(stepIndex: state.stepIndex + 1);
  }

  void goBack() {
    if (!state.isFirstStep)
      state = state.copyWith(stepIndex: state.stepIndex - 1);
  }

  Future<bool> submit() async {
    if (!state.canSubmit) return false;
    state = state.copyWith(
        submitStatus: RiderMeActionStatus.inProgress, clearErrorMessage: true);
    final result = await _repo.submitReport(
      targetType: state.targetType!,
      orderId: state.orderId,
      targetName: state.targetName ?? _defaultTargetName(state.targetType!),
      targetPhone: state.targetPhone,
      reasonCode: state.reasonCode!,
      reasonLabel: state.reasonLabel!,
      description: state.description.trim(),
      attachments: state.photos,
    );
    return result.fold(
      (f) {
        state = state.copyWith(
          submitStatus: RiderMeActionStatus.error,
          errorMessage: f.message,
        );
        return false;
      },
      (report) {
        state = state.copyWith(
          submitStatus: RiderMeActionStatus.success,
          submittedReport: report,
        );
        return true;
      },
    );
  }
}

final riderReportFormProvider = NotifierProvider.autoDispose
    .family<RiderReportFormNotifier, RiderReportFormState, RiderReportFlowArgs>(
  RiderReportFormNotifier.new,
);
