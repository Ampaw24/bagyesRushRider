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
    GMSServices.provideAPIKey("AIzaSyA6QwaWqE4gtpQq4tTXGVIxLmeEeVKhYUc")

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
}
