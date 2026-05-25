import UIKit

enum CompanionAppLauncher {
    private static let biomboScheme = URL(string: "biombo://")!

    /// nil until Biombo ships on the App Store — guards against sending users
    /// to a 404 when Biombo isn't installed.
    private static let biomboAppStoreURL: URL? = nil

    @MainActor
    static func openBiombo() {
        let app = UIApplication.shared
        if app.canOpenURL(biomboScheme) {
            app.open(biomboScheme, options: [:], completionHandler: nil)
            return
        }
        if let fallback = biomboAppStoreURL {
            app.open(fallback, options: [:], completionHandler: nil)
        }
    }
}
