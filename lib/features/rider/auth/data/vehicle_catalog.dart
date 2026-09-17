/// A single make+model a rider can pick on the Vehicle Specs step.
class VehicleCatalogEntry {
  final String make;
  final String model;

  const VehicleCatalogEntry({required this.make, required this.model});
}

/// Placeholder vehicle catalog for the signup wizard's Vehicle Specs step —
/// constrains Make/Model/Year to known values instead of letting the rider
/// type anything in.
///
/// Segregated into its own class so the dummy ~20-entry lists per category
/// can later be swapped for a real backend-fetched catalog (e.g. a
/// `GET /vehicles/catalog` call) without touching the screen that consumes
/// it — callers only depend on [entriesFor]/[makesFor]/[modelsFor]/[years].
abstract final class VehicleCatalog {
  /// Standard fuel motorcycles.
  static const List<VehicleCatalogEntry> motorcycles = [
    VehicleCatalogEntry(make: 'Honda', model: 'CB125F'),
    VehicleCatalogEntry(make: 'Honda', model: 'CB150R'),
    VehicleCatalogEntry(make: 'Honda', model: 'Wave 110'),
    VehicleCatalogEntry(make: 'Yamaha', model: 'YBR125'),
    VehicleCatalogEntry(make: 'Yamaha', model: 'Crux'),
    VehicleCatalogEntry(make: 'Yamaha', model: 'AG 100'),
    VehicleCatalogEntry(make: 'TVS', model: 'StaR City+'),
    VehicleCatalogEntry(make: 'TVS', model: 'HLX 125'),
    VehicleCatalogEntry(make: 'TVS', model: 'Apache RTR 160'),
    VehicleCatalogEntry(make: 'Bajaj', model: 'Boxer 100'),
    VehicleCatalogEntry(make: 'Bajaj', model: 'CT 100'),
    VehicleCatalogEntry(make: 'Bajaj', model: 'Pulsar 150'),
    VehicleCatalogEntry(make: 'Haojue', model: 'HJ125-11'),
    VehicleCatalogEntry(make: 'Haojue', model: 'DK150'),
    VehicleCatalogEntry(make: 'Suzuki', model: 'GD110'),
    VehicleCatalogEntry(make: 'Suzuki', model: 'AX100'),
    VehicleCatalogEntry(make: 'Kawasaki', model: 'KLX150'),
    VehicleCatalogEntry(make: 'Sinoki', model: 'SK110'),
    VehicleCatalogEntry(make: 'Qlink', model: 'Skyline 200'),
    VehicleCatalogEntry(make: 'Royal', model: 'TS 100'),
  ];

  /// Electric motorcycles/scooters — includes real African e-mobility
  /// brands (Spiro, Ampersand, Roam) alongside global ones, since this app
  /// operates in Ghana.
  static const List<VehicleCatalogEntry> electricMotorcycles = [
    VehicleCatalogEntry(make: 'Spiro', model: 'Boda Electric'),
    VehicleCatalogEntry(make: 'Spiro', model: 'Fumba'),
    VehicleCatalogEntry(make: 'Ampersand', model: 'Gen2'),
    VehicleCatalogEntry(make: 'Roam', model: 'Air'),
    VehicleCatalogEntry(make: 'Opibus', model: 'Elektrik Boda'),
    VehicleCatalogEntry(make: 'Yadea', model: 'T9'),
    VehicleCatalogEntry(make: 'Yadea', model: 'G5'),
    VehicleCatalogEntry(make: 'Okinawa', model: 'Praise Pro'),
    VehicleCatalogEntry(make: 'Okinawa', model: 'Ridge+'),
    VehicleCatalogEntry(make: 'Ampere', model: 'Zeal'),
    VehicleCatalogEntry(make: 'Ampere', model: 'Magnus'),
    VehicleCatalogEntry(make: 'NIU', model: 'NQi GT'),
    VehicleCatalogEntry(make: 'NIU', model: 'MQi+'),
    VehicleCatalogEntry(make: 'Super Soco', model: 'TC Max'),
    VehicleCatalogEntry(make: 'Super Soco', model: 'CPx'),
    VehicleCatalogEntry(make: 'Gogoro', model: 'S2'),
    VehicleCatalogEntry(make: 'Zero Motorcycles', model: 'FXE'),
    VehicleCatalogEntry(make: 'Segway', model: 'E110S'),
    VehicleCatalogEntry(make: 'Ola Electric', model: 'S1 Pro'),
    VehicleCatalogEntry(make: 'GenZe', model: '2.0'),
  ];

  static List<VehicleCatalogEntry> entriesFor({required bool isElectric}) =>
      isElectric ? electricMotorcycles : motorcycles;

  static List<String> makesFor({required bool isElectric}) {
    final makes =
        entriesFor(isElectric: isElectric).map((e) => e.make).toSet().toList();
    makes.sort();
    return makes;
  }

  static List<String> modelsFor({
    required bool isElectric,
    required String make,
  }) {
    final models = entriesFor(isElectric: isElectric)
        .where((e) => e.make == make)
        .map((e) => e.model)
        .toList();
    models.sort();
    return models;
  }

  /// The last [count] years, newest first — registration years aren't tied
  /// to a specific make/model in this placeholder catalog.
  static List<int> years({int count = 20}) {
    final current = DateTime.now().year;
    return List.generate(count, (i) => current - i);
  }
}
