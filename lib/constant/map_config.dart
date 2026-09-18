import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Google Maps **web-service** key, sourced from `.env` (key `GMAPCODE`),
/// loaded in `main()` before this getter is first read.
///
/// Deliberately distinct from the Maps *SDK* key hardcoded in
/// `AndroidManifest.xml` / `AppDelegate.swift`: those are app-restricted
/// render keys tied to a package name + signing certificate. A web-service
/// call (Geocoding) carries no app signature, so an app-restricted key
/// answers `REQUEST_DENIED` — this key must be unrestricted or IP-restricted
/// instead, with the Geocoding API enabled on its project.
String get kMapsApiKey => dotenv.env['GMAPCODE'] ?? '';
