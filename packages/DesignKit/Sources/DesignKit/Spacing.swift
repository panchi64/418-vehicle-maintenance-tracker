import SwiftUI

/// Base-4 spacing scale. Mirror of the existing Checkpoint Spacing enum so the
/// eventual in-place swap is a source-level no-op for the ~694 call sites.
public enum Spacing {
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

public extension View {
    func screenPadding() -> some View {
        padding(.horizontal, Spacing.screenHorizontal)
    }
}
