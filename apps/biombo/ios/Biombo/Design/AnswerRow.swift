import SwiftUI

/// A row in either grammar (PRODUCT.md §3): a place row (name → trailing
/// answer) or an event row (a sentence, no trailing value). One primary, one
/// secondary line of at most two atoms (distance and the trust suffix), and
/// at most one trailing value. At accessibility sizes the value moves under
/// the primary.
struct AnswerRow: View {
    let row: NearbyRow
    let grammar: NearbySection.Grammar
    let now: Date
    /// A trust atom the row's answer alone can't state (a disputed owner post).
    var trustOverride: TrustSuffix?
    /// A trailing value other than the answer's own ("Fila: 20 min" instead of a price).
    var value: LocalizedStringResource?
    var action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.locale) private var locale
    @Environment(\.priceUnit) private var unit
    @ScaledMetric(relativeTo: .body) private var pinSize = Size.listPin

    var body: some View {
        Button(action: action) {
            HStack(alignment: dynamicTypeSize.isAccessibilitySize ? .top : .center, spacing: Spacing.s3) {
                LayerPin(layer: row.layer, glyph: glyph, size: pinSize)
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: Spacing.s1) {
                        main
                        trailing
                    }
                    Spacer(minLength: 0)
                } else {
                    main
                    Spacer(minLength: Spacing.s2)
                    trailing
                }
            }
            .padding(.vertical, Spacing.s2)
            .frame(minHeight: Size.target)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private var main: some View {
        VStack(alignment: .leading, spacing: 2) {
            primary
                .textRole(grammar == .event ? .headline : .body)
                .foregroundStyle(Color(.ink))
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
            secondary
        }
    }

    /// One line, always in one order: distance, then the trust atom ("1.4 km ·
    /// Sin verificar · hace 2 h"). A promoted atom gains weight, not position.
    private var secondary: some View {
        let trust = self.trust
        let distance = GlanceNumbers.distance(meters: row.distance, locale: locale)
        let atom = Text("\(Image(systemName: trust.symbol))\u{00A0}\(Text(trust.text(locale: locale)))", comment: "A trust atom inline: its symbol, then its phrase, kept together")
            .foregroundStyle(Color(trust.ink))
            .fontWeight(trust.isPromoted ? .medium : .regular)
        return Text("\(distance) · \(atom)", comment: "A row's secondary line: the distance, then the trust atom")
            .textRole(.footnote)
            .foregroundStyle(Color(.ink2))
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var trailing: some View {
        switch (grammar, row.item) {
        case (.place, .place(let answer)):
            Text(value ?? answer.valueText(unit: unit, locale: locale))
                .textRole(.value)
                .foregroundStyle(Color(.ink))
        default:
            Image(systemName: "chevron.forward")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(.ink3))
                .accessibilityHidden(true)
        }
    }

    private var primary: Text {
        switch (grammar, row.item) {
        case (.place, .place(let answer)): Text(verbatim: answer.place.name)
        case (.event, .place(let answer)): Text(answer.eventSentence)
        case (_, .area(let status)): Text(status.sentence)
        }
    }

    private var glyph: String {
        switch row.item {
        case .place(let answer): answer.glyph
        case .area(let status): status.glyph
        }
    }

    private var trust: TrustSuffix {
        if let trustOverride { return trustOverride }
        return switch row.item {
        case .place(let answer): TrustSuffix(answer, now: now)
        case .area(let status): TrustSuffix(status, now: now)
        }
    }
}
