import SwiftUI
import DesignKit

struct PriceAnnotationView: View {
    @Environment(\.theme) private var theme
    let price: CachedFuelPrice

    var body: some View {
        VStack(spacing: 2) {
            if let regular = price.regularPrice {
                Text(Formatters.priceString(regular))
                    .font(theme.font(.caption, weight: .bold))
                    .foregroundStyle(theme.backgroundPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(annotationColor)
            }
            Triangle()
                .fill(annotationColor)
                .frame(width: 8, height: 6)
        }
        .brutalistBorder(color: theme.backgroundPrimary, lineWidth: 2)
    }

    private var annotationColor: Color {
        switch price.freshness {
        case .fresh: return theme.accent
        case .aging: return theme.accentMuted
        case .stale: return theme.textTertiary
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
