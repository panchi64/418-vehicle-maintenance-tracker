import SwiftUI

public struct GridOverlay: View {
    let color: Color
    let spacing: CGFloat
    let lineWidth: CGFloat

    public init(color: Color, spacing: CGFloat = 16, lineWidth: CGFloat = 0.5) {
        self.color = color
        self.spacing = spacing
        self.lineWidth = lineWidth
    }

    public var body: some View {
        GeometryReader { geo in
            Path { path in
                for x in stride(from: 0, to: geo.size.width, by: spacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
            }
            .stroke(color, lineWidth: lineWidth)
        }
        .allowsHitTesting(false)
    }
}
