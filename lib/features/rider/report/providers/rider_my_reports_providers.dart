import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/features/rider/report/models/rider_report_model.dart';
import 'package:delivery_boy/features/rider/report/repositories/rider_report_repository.dart';

enum RiderMyReportsStatus { initial, loading, loaded, error }

class RiderMyReportsState extends Equatable {
  final RiderMyReportsStatus status;
  final List<RiderReportModel> reports;
  final String? errorMessage;

  const RiderMyReportsState({
    this.status = RiderMyReportsStatus.initial,
    this.reports = const [],
    this.errorMessage,
  });

  RiderMyReportsState copyWith({
    RiderMyReportsStatus? status,
    List<RiderReportModel>? reports,
    String? errorMessage,
    bool clearError = false,
  }) =>
      RiderMyReportsState(
        status: status ?? this.status,
        reports: reports ?? this.reports,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [status, reports, errorMessage];
}

class RiderMyReportsNotifier extends Notifier<RiderMyReportsState> {
  @override
  RiderMyReportsState build() => const RiderMyReportsState();

  RiderReportRepository get _repo => sl<RiderReportRepository>();

  Future<void> load() async {
    state =
        state.copyWith(status: RiderMyReportsStatus.loading, clearError: true);
    final result = await _repo.getReports();
    result.fold(
      (f) => state = state.copyWith(
          status: RiderMyReportsStatus.error, errorMessage: f.message),
      (reports) {
        final sorted = [...reports]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        state = state.copyWith(
            status: RiderMyReportsStatus.loaded, reports: sorted);
      },
    );
  }
}

final riderMyReportsProvider =
    NotifierProvider<RiderMyReportsNotifier, RiderMyReportsState>(
        RiderMyReportsNotifier.new);

/// One report's full detail — `GET /rider/me/reports/:id`. Errors surface
/// as the [Failure] itself (see `payoutProvidersProvider` for the same
/// fold-and-throw shape).
final riderReportDetailProvider =
    FutureProvider.autoDispose.family<RiderReportModel, int>((ref, id) async {
  final result = await sl<RiderReportRepository>().getReportById(id);
  return result.fold((failure) => throw failure, (report) => report);
});
