import SwiftUI

public struct BrutalistCardModifier: ViewModifier {
    let background: Color
    let borderColor: Color
    let borderWidth: CGFloat
    let padding: CGFloat

    public init(background: Color, borderColor: Color, borderWidth: CGFloat, padding: CGFloat) {
        self.background = background
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.padding = padding
    }

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(background)
            .brutalistBorder(color: borderColor, lineWidth: borderWidth)
    }
}

public extension View {
    func brutalistCard(
        background: Color,
        borderColor: Color,
        borderWidth: CGFloat = 2,
        padding: CGFloat = 16
    ) -> some View {
        modifier(
            BrutalistCardModifier(
                background: background,
                borderColor: borderColor,
                borderWidth: borderWidth,
                padding: padding
            )
        )
    }
}
