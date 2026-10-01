import UIKit
import Flutter
import GoogleMaps
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Read from the project .env (bundled as a Flutter asset for
    // flutter_dotenv), so the Maps SDK key can never drift from it — edit
    // G_CLIENTID_IOS there, not here.
    if let mapsApiKey = Self.dotenvValue("G_CLIENTID_IOS") {
      GMSServices.provideAPIKey(mapsApiKey)
    } else {
      NSLog("[Maps] G_CLIENTID_IOS missing from .env — Google Maps will not load")
    }

    // Lets flutter_local_notifications present alerts while the app is in
    // the foreground. FlutterAppDelegate already conforms to the protocol.
    //
    // Deliberately no FirebaseApp.configure() here — firebase_core does it
    // via GeneratedPluginRegistrant, and configuring twice is the classic
    // "default app already exists" crash.
    // Conditional cast, not a plain `= self`: which protocols
    // FlutterAppDelegate conforms to varies by Flutter version, and this
    // must not become a compile error on an SDK bump. Registered before
    // GeneratedPluginRegistrant so firebase_messaging can still take over.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// One value from the bundled `.env` asset. Splits on the first `=` and
  /// strips matching surrounding quotes, the same way flutter_dotenv and
  /// android/app/build.gradle read the file.
  private static func dotenvValue(_ key: String) -> String? {
    let assetKey = FlutterDartProject.lookupKey(forAsset: ".env")
    guard let path = Bundle.main.path(forResource: assetKey, ofType: nil),
          let contents = try? String(contentsOfFile: path, encoding: .utf8)
    else { return nil }

    for rawLine in contents.components(separatedBy: .newlines) {
      let line = rawLine.trimmingCharacters(in: .whitespaces)
      guard !line.hasPrefix("#"), let separator = line.firstIndex(of: "=") else { continue }
      guard line[..<separator].trimmingCharacters(in: .whitespaces) == key else { continue }

      var value = line[line.index(after: separator)...].trimmingCharacters(in: .whitespaces)
      if value.count >= 2, let first = value.first, first == "\"" || first == "'",
         value.last == first {
        value = String(value.dropFirst().dropLast())
      }
      return value.isEmpty ? nil : value
    }
    return nil
  }
}
