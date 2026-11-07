import UIKit
import Capacitor

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationCenter.default.post(name: .capacitorDidRegisterForRemoteNotifications, object: deviceToken)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationCenter.default.post(name: .capacitorDidFailToRegisterForRemoteNotifications, object: error)
    }

    func applicationWillResignActive(_ application: UIApplication) {}
    func applicationDidEnterBackground(_ application: UIApplication) {}
    func applicationWillEnterForeground(_ application: UIApplication) {}
    func applicationDidBecomeActive(_ application: UIApplication) {}
    func applicationWillTerminate(_ application: UIApplication) {}

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if openLyamfi(url) { return true }
        return ApplicationDelegateProxy.shared.application(app, open: url, options: options)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if let url = userActivity.webpageURL, openLyamfi(url) { return true }
        return ApplicationDelegateProxy.shared.application(application, continue: userActivity,
                                                            restorationHandler: restorationHandler)
    }

    private func openLyamfi(_ url: URL) -> Bool {
        let path: String
        if url.scheme == "https", url.host == "lyamfi.lovable.app" {
            path = url.path + (url.query.map { "?" + $0 } ?? "")
        } else if url.scheme == "lyamfi" {
            let hostPath = url.host.map { "/" + $0 } ?? ""
            path = (url.path.isEmpty ? hostPath : hostPath + url.path) + (url.query.map { "?" + $0 } ?? "")
        } else {
            return false
        }
        let allowed = #"^/(dashboard|bourse|portefeuille|classement|academie|actualites|simulateurs|macroeconomie)([/?].*)?$"#
        guard path.range(of: allowed, options: .regularExpression) != nil,
              let target = URL(string: "https://lyamfi.lovable.app" + path),
              let bridge = window?.rootViewController as? CAPBridgeViewController,
              let webView = bridge.webView else {
            return false
        }
        webView.load(URLRequest(url: target))
        return true
    }
}
