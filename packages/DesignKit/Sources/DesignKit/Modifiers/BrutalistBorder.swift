import SwiftUI

public struct BrutalistBorderModifier: ViewModifier {
    let color: Color
    let lineWidth: CGFloat

    public init(color: Color, lineWidth: CGFloat) {
        self.color = color
        self.lineWidth = lineWidth
    }

    public func body(content: Content) -> some View {
        content.overlay(
            Rectangle().strokeBorder(color, lineWidth: lineWidth)
        )
    }
}

public extension View {
    func brutalistBorder(color: Color, lineWidth: CGFloat = 2) -> some View {
        modifier(BrutalistBorderModifier(color: color, lineWidth: lineWidth))
    }
}
