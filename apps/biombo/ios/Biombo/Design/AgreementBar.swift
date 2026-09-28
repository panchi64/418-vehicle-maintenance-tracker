import SwiftUI

/// The agreement bar (PRODUCT.md §3 "Compare with shapes"): who says what,
/// as lengths. Each part has its own fill pattern and a legend line with a
/// symbol and words, so it never rests on colour. VoiceOver reads the legend.
struct AgreementBar: View {
    struct Part: Identifiable {
        enum Pattern {
            case solid
            case dashed
            case dotted
        }

        let id: String
        let count: Int
        let pattern: Pattern
        let symbol: String
        let label: LocalizedStringResource
    }

    let parts: [Part]

    var body: some View {
        let shown = parts.filter { $0.count > 0 }
        let total = max(shown.reduce(0) { $0 + $1.count }, 1)
        VStack(alignment: .leading, spacing: Spacing.s2) {
            GeometryReader { proxy in
                HStack(spacing: 2) {
                    ForEach(shown) { part in
                        segment(part.pattern)
                            .frame(width: max((proxy.size.width - CGFloat(shown.count - 1) * 2) * CGFloat(part.count) / CGFloat(total), 4))
                    }
                }
            }
            .frame(height: 10)
            .accessibilityHidden(true)
            ForEach(shown) { part in
                Label {
                    Text(part.label)
                } icon: {
                    Image(systemName: part.symbol).accessibilityHidden(true)
                }
                .textRole(.footnote)
                .foregroundStyle(Color(.ink2))
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func segment(_ pattern: Part.Pattern) -> some View {
        let shape = RoundedRectangle(cornerRadius: 3)
        switch pattern {
        case .solid:
            shape.fill(Color(.ink2))
        case .dashed:
            shape.fill(Color(.vizTrack))
                .overlay(shape.strokeBorder(Color(.ink2), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3])))
        case .dotted:
            shape.fill(Color(.vizTrack))
                .overlay(shape.strokeBorder(Color(.ink3), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [0.5, 3])))
        }
    }
}
