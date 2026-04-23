import SwiftUI

private struct ThemeProviderKey: EnvironmentKey {
    static let defaultValue: (any ThemeProviding)? = nil
}

public extension EnvironmentValues {
    var theme: (any ThemeProviding)? {
        get { self[ThemeProviderKey.self] }
        set { self[ThemeProviderKey.self] = newValue }
    }
}

public extension View {
    func designKitTheme(_ provider: any ThemeProviding) -> some View {
        environment(\.theme, provider)
    }
}
