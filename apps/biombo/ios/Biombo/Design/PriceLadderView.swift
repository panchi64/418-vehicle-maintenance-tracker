import SwiftUI

/// The price ladder (V2-Station "¿Buen precio?"): a track with DACO's
/// reference (a tick for the brand, a band for the island range), the
/// nearby stations as hollow dots and this station as the solid one. Shape
/// and words carry it, never colour; VoiceOver reads one sentence.
struct PriceLadderView: View {
    let ladder: PriceLadder

    @Environment(\.locale) private var locale
    @Environment(\.priceUnit) private var unit
    @ScaledMetric(relativeTo: .caption) private var labelHeight: CGFloat = 18
    @State private var thisWidth: CGFloat = 0
    @State private var referenceWidth: CGFloat = 0

    var body: some View {
        let height = labelHeight * 2 + 34
        GeometryReader { proxy in
            let width = proxy.size.width
            let trackY = labelHeight + 17
            ZStack(alignment: .topLeading) {
                Capsule()
                    .fill(Color(.vizTrack))
                    .frame(width: width, height: 4)
                    .position(x: width / 2, y: trackY)
                reference(width: width, trackY: trackY)
                ForEach(Array(ladder.others.enumerated()), id: \.offset) { _, price in
                    Circle()
                        .fill(Color(.paperRaised))
                        .overlay(Circle().strokeBorder(Color(.ink3), lineWidth: 1.5))
                        .frame(width: 9, height: 9)
                        .position(x: x(price.centsPerLitre, width), y: trackY)
                }
                Circle()
                    .fill(Color(.ink))
                    .overlay(Circle().strokeBorder(Color(.paperRaised), lineWidth: 2))
                    .frame(width: 16, height: 16)
                    .position(x: x(ladder.this.centsPerLitre, width), y: trackY)
                label(Text("Esta · \(GlanceNumbers.price(ladder.this, unit: unit, locale: locale))", comment: "Price ladder: this station's mark, with its price"), weight: .semibold)
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { thisWidth = $0 }
                    .position(x: clamped(x(ladder.this.centsPerLitre, width), width, label: thisWidth), y: trackY + 10 + labelHeight / 2 + 4)
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(ladder.spokenSummary(unit: unit, locale: locale)))
    }

    @ViewBuilder
    private func reference(width: CGFloat, trackY: CGFloat) -> some View {
        if let cents = ladder.referenceCents {
            let low = x(cents.lowerBound, width)
            let high = x(cents.upperBound, width)
            if high - low < 3 {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(.ink))
                    .frame(width: 3, height: 22)
                    .position(x: low, y: trackY)
            } else {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.vizBand))
                    .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(Color(.ink), lineWidth: 2))
                    .frame(width: high - low, height: 14)
                    .position(x: (low + high) / 2, y: trackY)
            }
            label(referenceText(cents), weight: .regular)
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { referenceWidth = $0 }
                .position(x: clamped((low + high) / 2, width, label: referenceWidth), y: labelHeight / 2)
        }
    }

    private func referenceText(_ cents: ClosedRange<Double>) -> Text {
        let low = GlanceNumbers.price(FuelPrice(grade: ladder.this.grade, centsPerLitre: cents.lowerBound), unit: unit, locale: locale)
        let high = GlanceNumbers.price(FuelPrice(grade: ladder.this.grade, centsPerLitre: cents.upperBound), unit: unit, locale: locale)
        return low == high
            ? Text("\(Text(ladder.referenceLabel)) \(low)", comment: "Price ladder: DACO's reference label, then its price")
            : Text("\(Text(ladder.referenceLabel)) \(low)–\(high)", comment: "Price ladder: DACO's range label, then its low and high prices")
    }

    private func label(_ text: Text, weight: Font.Weight) -> some View {
        text
            .textRole(.viz)
            .fontWeight(weight)
            .foregroundStyle(Color(weight == .semibold ? .ink : .ink2))
            .lineLimit(1)
            .fixedSize()
    }

    private func x(_ cents: Double, _ width: CGFloat) -> CGFloat {
        CGFloat(ladder.position(cents)) * width
    }

    /// Keeps a centred label, at its measured width, inside the track's ends.
    private func clamped(_ x: CGFloat, _ width: CGFloat, label: CGFloat) -> CGFloat {
        let half = label / 2
        guard width > label else { return width / 2 }
        return min(max(x, half), width - half)
    }
}
