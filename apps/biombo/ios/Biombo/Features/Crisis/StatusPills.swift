import SwiftUI

/// What the whole app is in, as small glass pills in the map's nav area
/// (V2-Crisis: "not above the answer", N1): crisis mode (§8), then no
/// connection or a weak one (§4.6). The answer stays the sheet's first
/// content. Each pill opens what it means; its detail is the VoiceOver hint.
struct StatusPills: View {
    let isCrisis: Bool
    let connection: ConnectionState
    let pending: Int
    let onOpen: (SheetRoute) -> Void

    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            if isCrisis {
                pill(symbol: "exclamationmark.bubble", title: CrisisCopy.pillTitle, hint: CrisisCopy.pillHint) { onOpen(.crisis) }
            }
            if !connection.isOnline {
                pill(symbol: connection.symbol, title: connection.title, hint: connection.detail(pending: pending, locale: locale)) { onOpen(.outbox) }
            }
        }
    }

    private func pill(symbol: String, title: LocalizedStringResource, hint: LocalizedStringResource, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label { Text(title) } icon: { Image(systemName: symbol).accessibilityHidden(true) }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(.ink))
                .lineLimit(1)
                .fixedSize()
                .padding(.leading, Spacing.s3)
                .padding(.trailing, Spacing.s4)
                .frame(minHeight: Size.target)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .capsule)
        // Like the control stack, the pill stops growing; a long press shows it large.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityHint(Text(hint))
        .accessibilityShowsLargeContentViewer {
            Label { Text(title) } icon: { Image(systemName: symbol) }
        }
    }
}
