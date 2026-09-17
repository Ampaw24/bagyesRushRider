import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_make_model.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_model_model.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_type_model.dart';
import 'package:delivery_boy/features/rider/vehicles/repository/vehicle_catalog_repository.dart';

// ── Status ────────────────────────────────────────────────────────────────────

enum _LoadStatus { initial, loading, loaded, error }

// ── State ─────────────────────────────────────────────────────────────────────

class VehicleCatalogState extends Equatable {
  final List<VehicleTypeModel> types;
  final List<VehicleMakeModel> makes;
  final List<VehicleModelModel> models;

  final _LoadStatus typesStatus;
  final _LoadStatus makesStatus;
  final _LoadStatus modelsStatus;

  final String? typesError;
  final String? makesError;
  final String? modelsError;

  const VehicleCatalogState({
    this.types = const [],
    this.makes = const [],
    this.models = const [],
    this.typesStatus = _LoadStatus.initial,
    this.makesStatus = _LoadStatus.initial,
    this.modelsStatus = _LoadStatus.initial,
    this.typesError,
    this.makesError,
    this.modelsError,
  });

  bool get isLoadingTypes => typesStatus == _LoadStatus.loading;
  bool get isLoadingMakes => makesStatus == _LoadStatus.loading;
  bool get isLoadingModels => modelsStatus == _LoadStatus.loading;

  VehicleCatalogState copyWith({
    List<VehicleTypeModel>? types,
    List<VehicleMakeModel>? makes,
    List<VehicleModelModel>? models,
    _LoadStatus? typesStatus,
    _LoadStatus? makesStatus,
    _LoadStatus? modelsStatus,
    String? typesError,
    String? makesError,
    String? modelsError,
  }) {
    return VehicleCatalogState(
      types: types ?? this.types,
      makes: makes ?? this.makes,
      models: models ?? this.models,
      typesStatus: typesStatus ?? this.typesStatus,
      makesStatus: makesStatus ?? this.makesStatus,
      modelsStatus: modelsStatus ?? this.modelsStatus,
      typesError: typesError,
      makesError: makesError,
      modelsError: modelsError,
    );
  }

  @override
  List<Object?> get props => [
        types,
        makes,
        models,
        typesStatus,
        makesStatus,
        modelsStatus,
        typesError,
        makesError,
        modelsError,
      ];
}

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Drives the cascading Type -> Make -> Model picker on the rider signup
/// wizard. Backed entirely by the public vehicle-catalogue endpoints — no
/// hardcoded lists.
class VehicleCatalogNotifier extends Notifier<VehicleCatalogState> {
  @override
  VehicleCatalogState build() => const VehicleCatalogState();

  VehicleCatalogRepository get _repo => sl<VehicleCatalogRepository>();

  Future<void> loadTypes() async {
    if (state.typesStatus == _LoadStatus.loading) return;
    state = state.copyWith(typesStatus: _LoadStatus.loading, typesError: null);

    try {
      final result = await _repo.getVehicleTypes();
      result.fold(
        (failure) => state = state.copyWith(
          typesStatus: _LoadStatus.error,
          typesError: failure.message,
        ),
        (types) => state = state.copyWith(
          typesStatus: _LoadStatus.loaded,
          types: types,
        ),
      );
    } catch (e) {
      // Guards against anything thrown before the repository's own
      // try/catch runs (e.g. a DI misconfiguration) — without this, such a
      // failure would leave the UI stuck on a spinner forever instead of
      // surfacing a retryable error.
      state = state.copyWith(
        typesStatus: _LoadStatus.error,
        typesError: e.toString(),
      );
    }
  }

  /// Clears makes and models — call whenever the selected vehicle type
  /// changes so a stale make/model from a different type can't linger as
  /// "selected".
  Future<void> loadMakes(int vehicleTypeId) async {
    state = state.copyWith(
      makesStatus: _LoadStatus.loading,
      makesError: null,
      makes: const [],
      models: const [],
      modelsStatus: _LoadStatus.initial,
    );

    try {
      final result = await _repo.getVehicleMakes(vehicleTypeId);
      result.fold(
        (failure) => state = state.copyWith(
          makesStatus: _LoadStatus.error,
          makesError: failure.message,
        ),
        (makes) => state = state.copyWith(
          makesStatus: _LoadStatus.loaded,
          makes: makes,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        makesStatus: _LoadStatus.error,
        makesError: e.toString(),
      );
    }
  }

  /// Clears models — call whenever the selected make changes.
  Future<void> loadModels(int vehicleMakeId) async {
    state = state.copyWith(
      modelsStatus: _LoadStatus.loading,
      modelsError: null,
      models: const [],
    );

    try {
      final result = await _repo.getVehicleModels(vehicleMakeId);
      result.fold(
        (failure) => state = state.copyWith(
          modelsStatus: _LoadStatus.error,
          modelsError: failure.message,
        ),
        (models) => state = state.copyWith(
          modelsStatus: _LoadStatus.loaded,
          models: models,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        modelsStatus: _LoadStatus.error,
        modelsError: e.toString(),
      );
    }
  }

  void clearMakesAndModels() {
    state = state.copyWith(
      makes: const [],
      models: const [],
      makesStatus: _LoadStatus.initial,
      modelsStatus: _LoadStatus.initial,
    );
  }

  void clearModels() {
    state = state.copyWith(models: const [], modelsStatus: _LoadStatus.initial);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final vehicleCatalogProvider =
    NotifierProvider<VehicleCatalogNotifier, VehicleCatalogState>(
  VehicleCatalogNotifier.new,
);
