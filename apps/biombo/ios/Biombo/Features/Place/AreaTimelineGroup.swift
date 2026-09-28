import SwiftUI

/// "¿Cómo ha ido?" in an outage's depth (V2-Outage): a headline that says
/// who spoke first, then each moment as a clock time and what happened.
struct AreaTimelineGroup: View {
    let timeline: AreaTimeline
    let now: Date

    @Environment(\.locale) private var locale
    /// The stamps share one column, so the events line up.
    @ScaledMetric(relativeTo: .caption) private var stampWidth: CGFloat = 76

    var body: some View {
        SectionGroup(title: LocalizedStringResource("¿Cómo ha ido?", comment: "Depth section: the outage's timeline")) {
            if let headline = timeline.headline(locale: locale) {
                Text(headline)
                    .textRole(.headline)
                    .foregroundStyle(Color(.ink))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Spacing.s3)
                RowDivider(isInset: false)
            }
            RowList(elements: timeline.entries) { entry in
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.s3) {
                        stamp(entry).frame(minWidth: stampWidth, alignment: .leading)
                        Text(entry.title).textRole(.body).foregroundStyle(Color(.ink))
                        Spacer(minLength: 0)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.title).textRole(.body).foregroundStyle(Color(.ink))
                        stamp(entry)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: Size.target, alignment: .leading)
                .accessibilityElement(children: .combine)
            }
        }
    }

    /// A clock time today, else the age ("ayer").
    private func stamp(_ entry: AreaTimeline.Entry) -> some View {
        let isClock = entry.event != .latestConfirmation && PuertoRico.calendar.isDate(entry.date, inSameDayAs: now)
        let text = isClock ? Text(verbatim: entry.date.islandClock(locale: locale)) : Text(AgePhrase(since: entry.date, now: now).text(locale: locale))
        return text
            .textRole(.viz)
            .foregroundStyle(Color(.ink2))
    }
}
