import CoreText
import Foundation

public enum DesignKitFonts {
    public static func registerAll() {
        registrationToken
    }

    private static let registrationToken: Void = {
        let bundle = Bundle.module
        let urls = (bundle.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [])
            + (bundle.urls(forResourcesWithExtension: "otf", subdirectory: nil) ?? [])
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()
}
