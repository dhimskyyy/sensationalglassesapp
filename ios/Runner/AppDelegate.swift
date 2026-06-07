import UIKit
import Flutter
import GoogleSignIn
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let apiKey = Bundle.main.object(forInfoDictionaryKey: "MAPS_API_KEY") as? String
    GMSServices.provideAPIKey(apiKey ?? "")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // GOOGLE URL HANDLER
  override func application(_ app: UIApplication,
                            open url: URL,
                            options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

    // Handle Google Sign-In
    if GIDSignIn.sharedInstance.handle(url) {
      return true
    }

    return super.application(app, open: url, options: options)
  }
}
