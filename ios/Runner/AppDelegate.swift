import UIKit
import Flutter
import GoogleSignIn
import FBSDKCoreKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let apiKey = Bundle.main.object(forInfoDictionaryKey: "MAPS_API_KEY") as? String
    GMSServices.provideAPIKey(apiKey ?? "")

    // Facebook
    ApplicationDelegate.shared.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // GOOGLE & FACEBOOK URL HANDLER
  override func application(_ app: UIApplication,
                            open url: URL,
                            options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

    // Handle Google Sign-In
    if GIDSignIn.sharedInstance.handle(url) {
      return true
    }

    // Handle Facebook Login
    let handled = ApplicationDelegate.shared.application(
      app,
      open: url,
      sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
      annotation: options[UIApplication.OpenURLOptionsKey.annotation]
    )
    if handled {
      return true
    }

    return super.application(app, open: url, options: options)
  }
}
