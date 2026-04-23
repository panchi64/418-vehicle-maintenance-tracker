import SwiftUI

public enum TouchTarget {
    public static let minimum: CGFloat = 44
}

public extension View {
    func touchTarget(_ size: CGFloat = TouchTarget.minimum) -> some View {
        frame(minWidth: size, minHeight: size)
    }
}
