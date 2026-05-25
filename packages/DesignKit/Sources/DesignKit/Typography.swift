import SwiftUI

public extension DesignKitFonts {
    enum Weight {
        case light, regular, medium, bold

        var postScriptName: String {
            switch self {
            case .light: return "JetBrainsMono-Light"
            case .regular: return "JetBrainsMono-Regular"
            case .medium: return "JetBrainsMono-Medium"
            case .bold: return "JetBrainsMono-Bold"
            }
        }

        init(_ swiftUI: Font.Weight) {
            switch swiftUI {
            case .ultraLight, .thin, .light: self = .light
            case .medium, .semibold: self = .medium
            case .bold, .heavy, .black: self = .bold
            default: self = .regular
            }
        }
    }

    /// Fixed-size JetBrains Mono. Use when the type scale is not Dynamic-Type-aware.
    static func jetBrainsMono(_ weight: Weight, size: CGFloat) -> Font {
        registerAll()
        return .custom(weight.postScriptName, size: size)
    }

    /// Dynamic-Type JetBrains Mono. Scales with the user's text size preference.
    static func jetBrainsMono(_ weight: Weight, textStyle: Font.TextStyle) -> Font {
        registerAll()
        return .custom(weight.postScriptName, size: textStyle.defaultSize, relativeTo: textStyle)
    }
}

extension Font.TextStyle {
    /// Default point size matching SwiftUI's system semantic sizes (used as the base
    /// for `.custom(_:size:relativeTo:)` so Dynamic Type scaling stays correct).
    var defaultSize: CGFloat {
        switch self {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline, .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        @unknown default: return 17
        }
    }
}
