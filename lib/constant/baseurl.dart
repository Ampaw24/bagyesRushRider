import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Base URL for the Laravel v1 API.
///
/// Sourced from `.env` (key `DEV_BASE_URL`), loaded in `main()` before this
/// getter is first read. Override per-environment by editing `.env` —
/// never hardcode a host here.
String get kBaseUrl => dotenv.env['DEV_BASE_URL']!;

/// `.env` key `APPVERSION` — shown on the splash screen.
String get kAppVersion => dotenv.env['APPVERSION']!;
