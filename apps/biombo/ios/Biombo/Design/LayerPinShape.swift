import SwiftUI

/// Each layer's pin silhouette, so layers differ by shape and never by colour
/// alone: teardrop gas, hexagon power, drop water, circle signal, diamond
/// roads, rounded square chargers, awning businesses. Drawn in a 28-unit box
/// and scaled; the same marks lead list rows and Capas rows.
nonisolated struct LayerPinShape: Shape {
    let layer: Layer

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 28
        let transform = CGAffineTransform(translationX: rect.minX, y: rect.minY).scaledBy(x: scale, y: scale)
        return unitPath.applying(transform)
    }

    /// Where the glyph sits, as a fraction of the height (the teardrop's bulb is high, the drop's low).
    var glyphCenter: Double {
        switch layer {
        case .gas: 11.6 / 28
        case .water: 16.7 / 28
        case .businesses: 15 / 28
        default: 0.5
        }
    }

    /// The point that touches the map: the tip of a teardrop or drop, otherwise the centre.
    var tip: UnitPoint {
        switch layer {
        case .gas: UnitPoint(x: 0.5, y: 25.5 / 28)
        default: .center
        }
    }

    private var unitPath: Path {
        var path = Path()
        func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
        switch layer {
        case .gas:
            path.move(to: p(14, 2.5))
            path.addCurve(to: p(23.5, 11.6), control1: p(19.2, 2.5), control2: p(23.5, 6.5))
            path.addCurve(to: p(14, 25.5), control1: p(23.5, 17.8), control2: p(14, 25.5))
            path.addCurve(to: p(4.5, 11.6), control1: p(14, 25.5), control2: p(4.5, 17.8))
            path.addCurve(to: p(14, 2.5), control1: p(4.5, 6.5), control2: p(8.8, 2.5))
        case .water:
            path.move(to: p(14, 2.8))
            path.addCurve(to: p(22.2, 16.7), control1: p(17.9, 8.1), control2: p(22.2, 12.1))
            path.addArc(center: p(14, 16.7), radius: 8.2, startAngle: .zero, endAngle: .degrees(180), clockwise: false)
            path.addCurve(to: p(14, 2.8), control1: p(5.8, 12.1), control2: p(10.1, 8.1))
        case .power:
            path.addLines([p(14, 2.5), p(24, 8.3), p(24, 19.7), p(14, 25.5), p(4, 19.7), p(4, 8.3)])
        case .roads:
            path.addLines([p(14, 2.5), p(25.5, 14), p(14, 25.5), p(2.5, 14)])
        case .signal:
            path.addEllipse(in: CGRect(x: 3.5, y: 3.5, width: 21, height: 21))
        case .chargers:
            path.addRoundedRect(in: CGRect(x: 4, y: 4, width: 20, height: 20), cornerSize: CGSize(width: 4.5, height: 4.5))
        case .businesses:
            path.move(to: p(4, 7.5))
            path.addLine(to: p(6, 4))
            path.addLine(to: p(22, 4))
            path.addLine(to: p(24, 7.5))
            path.addLine(to: p(24, 20))
            path.addArc(center: p(20, 20), radius: 4, startAngle: .zero, endAngle: .degrees(90), clockwise: false)
            path.addLine(to: p(8, 24))
            path.addArc(center: p(8, 20), radius: 4, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        }
        path.closeSubpath()
        return path
    }
}

/// A layer mark: the silhouette in its wash with a pen contour and the glyph.
struct LayerPin: View {
    let layer: Layer
    /// The status glyph; the layer's own symbol when nil.
    var glyph: String?
    var size: CGFloat = Size.listPin
    /// Map pins carry a halo so they lift off any ground.
    var hasHalo = false
    var isSelected = false

    var body: some View {
        let shape = LayerPinShape(layer: layer)
        ZStack {
            if hasHalo {
                shape.stroke(Color(isSelected ? .pinSelected : .pinHalo), lineWidth: isSelected ? 5 : 3)
            }
            shape.fill(Color(layer.wash))
            shape.stroke(Color(layer.edge), lineWidth: Size.contour)
            Image(systemName: glyph ?? layer.symbol)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(Color(layer.glyph))
                .position(x: size / 2, y: size * shape.glyphCenter)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        ForEach(Layer.allCases, id: \.self) { LayerPin(layer: $0, size: 40, hasHalo: true) }
    }
    .padding()
}
