import Foundation

/// The App Group the app shares with its widgets and Controls. The app
/// writes the widget snapshot; the extension only reads it. A Control's
/// tap leaves a pending screen here for the app to take.
///
/// Compiled into both the app and the widget extension, so everything is
/// `nonisolated` and means the same in both.
nonisolated enum SharedContainer {
    static let groupID = "group.com.418-studio.biombo"

    /// nil only when the App Group entitlement is missing.
    static var defaults: UserDefaults? { UserDefaults(suiteName: groupID) }
}
