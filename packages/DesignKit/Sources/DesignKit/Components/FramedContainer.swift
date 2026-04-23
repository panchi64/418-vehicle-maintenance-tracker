import SwiftUI

public struct FramedContainer<Content: View>: View {
    let frameColor: Color
    let frameWidth: CGFloat
    let backgroundColor: Color
    let content: Content

    public init(
        frameColor: Color,
        frameWidth: CGFloat = 35,
        backgroundColor: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.frameColor = frameColor
        self.frameWidth = frameWidth
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    public var body: some View {
        ZStack {
            frameColor.ignoresSafeArea()
            content
                .background(backgroundColor)
                .padding(frameWidth)
        }
    }
}
