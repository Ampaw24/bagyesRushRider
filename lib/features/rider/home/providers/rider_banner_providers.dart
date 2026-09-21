import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/features/rider/home/models/rider_banner_model.dart';
import 'package:delivery_boy/features/rider/home/repositories/rider_banner_repository.dart';

enum RiderBannersStatus { initial, loading, loaded, error }

class RiderBannersState extends Equatable {
  final RiderBannersStatus status;
  final List<RiderBannerModel> banners;
  final String? errorMessage;

  const RiderBannersState({
    this.status = RiderBannersStatus.initial,
    this.banners = const [],
    this.errorMessage,
  });

  RiderBannersState copyWith({
    RiderBannersStatus? status,
    List<RiderBannerModel>? banners,
    String? errorMessage,
    bool clearError = false,
  }) =>
      RiderBannersState(
        status: status ?? this.status,
        banners: banners ?? this.banners,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [status, banners, errorMessage];
}

class RiderBannersNotifier extends Notifier<RiderBannersState> {
  @override
  RiderBannersState build() => const RiderBannersState();

  RiderBannerRepository get _repo => sl<RiderBannerRepository>();

  Future<void> load() async {
    state =
        state.copyWith(status: RiderBannersStatus.loading, clearError: true);
    final result = await _repo.getBanners();
    result.fold(
      (f) => state = state.copyWith(
          status: RiderBannersStatus.error, errorMessage: f.message),
      (banners) => state = state.copyWith(
          status: RiderBannersStatus.loaded, banners: banners),
    );
  }
}

final riderBannersProvider =
    NotifierProvider<RiderBannersNotifier, RiderBannersState>(
        RiderBannersNotifier.new);
