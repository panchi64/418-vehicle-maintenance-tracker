import SwiftUI

/// The restore-time bar (PRODUCT.md §6.2, §6.3, V2-Outage): elapsed time
/// solid up to a "now" tick, then the official estimate hatched and labelled
/// "estimado". Without an official estimate it is elapsed time only: the
/// solid track ends at the tick, with no remaining track to imply progress.
struct RestoreBar: View {
    let since: Date
    let now: Date
    /// An official estimate only; a community estimate is never a restore time.
    let estimate: DateInterval?

    @State private var rowWidth: CGFloat = 0
    @State private var nowWidth: CGFloat = 0
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            GeometryReader { proxy in
                let width = proxy.size.width
                let nowX = width * fraction
                ZStack(alignment: .leading) {
                    if estimate != nil {
                        Capsule().fill(Color(.vizTrack)).frame(height: 8)
                        // The estimate window: hatched, never solid, since it is only an estimate.
                        Capsule()
                            .strokeBorder(Color(.ink3), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                            .frame(width: max(width - nowX, 0), height: 8)
                            .offset(x: nowX)
                    }
                    UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 4)
                        .fill(Color(.ink2))
                        .frame(width: nowX, height: 8)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(.ink))
                        .frame(width: 2, height: 16)
                        .offset(x: nowX - 2)
                }
                .frame(height: 16)
            }
            .frame(height: 16)
            .accessibilityHidden(true)

            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 2) {
                    startLabel
                    nowLabel
                    endLabel
                }
                .fixedSize(horizontal: false, vertical: true)
            } else if estimate == nil {
                HStack {
                    startLabel
                    Spacer(minLength: Spacing.s2)
                    nowLabel
                }
            } else {
                // "Ahora" sits under the tick; the ends go on their own line so nothing collides.
                nowLabel
                    .fixedSize()
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { nowWidth = $0 }
                    .offset(x: min(max(rowWidth * fraction - nowWidth / 2, 0), max(rowWidth - nowWidth, 0)))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { rowWidth = $0 }
                HStack(alignment: .firstTextBaseline) {
                    startLabel
                    Spacer(minLength: Spacing.s2)
                    endLabel.multilineTextAlignment(.trailing)
                }
            }
        }
        .textRole(.footnote)
        .foregroundStyle(Color(.ink2))
        .accessibilityElement(children: .combine)
    }

    private var startLabel: Text {
        Text("Se fue \(Text(stamp(since)))", comment: "Restore bar start: when service went out, e.g. 'Se fue a las 3:10 p. m.'")
    }

    private var nowLabel: some View {
        Text("Ahora", comment: "Restore bar: the now mark").fontWeight(.semibold).foregroundStyle(Color(.ink))
    }

    @ViewBuilder
    private var endLabel: some View {
        if let estimate {
            // A window people say ("mañana en la tarde"), never a clock time: it is only an estimate.
            Text("\(Text(DayWindow(estimate.end, now: now).text(locale: locale))) (estimado)", comment: "Restore bar end: the official estimate, labelled as an estimate")
        }
    }

    /// Where "now" sits: the end of the bar without an estimate, else its share of the span.
    private var fraction: CGFloat {
        guard let estimate, estimate.end > since else { return 1 }
        let total = estimate.end.timeIntervalSince(since)
        return CGFloat(min(max(now.timeIntervalSince(since) / total, 0.05), 0.95))
    }

    /// When service went out: "a las 3:10 p. m." today, else "el martes, 3:10 p. m.".
    private func stamp(_ date: Date) -> LocalizedStringResource {
        PuertoRico.calendar.isDate(date, inSameDayAs: now)
            ? LocalizedStringResource("a las \(date.islandClock(locale: locale))", comment: "Restore bar time today, e.g. 'a las 3:10 p. m.'")
            : LocalizedStringResource("el \(date.island(.dateTime.weekday(.wide).hour().minute(), locale: locale))", comment: "Restore bar time on another day, e.g. 'el martes, 3:10 p. m.'")
    }
}
