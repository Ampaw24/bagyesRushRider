/// Base URL for the Laravel v1 API.
///
/// Override at build time without touching source:
///   flutter run --dart-define=BASE_URL=http://host:port/api/v1
const String kBaseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'http://31.187.74.65:8085/api/v1',
);
