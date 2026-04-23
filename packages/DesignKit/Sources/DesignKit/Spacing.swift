import SwiftUI

/// Base-4 spacing scale. Mirrors Checkpoint's current Spacing enum exactly.
/// Apps provide their own `screenPadding()` modifier to avoid overload
/// collisions with pre-existing app-local extensions.
public enum DKSpacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let listItem: CGFloat = 12
    public static let md: CGFloat = 16
    public static let screenHorizontal: CGFloat = 20
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 48
    public static let tabBarOffset: CGFloat = 56
}
