import SwiftUI

/// One primary verb under an answer ("Abrir en…", "Vigilar", "Reportar").
struct Verb: Identifiable {
    let id: String
    let title: LocalizedStringResource
    let symbol: String
    /// A toggled verb ("Vigilando") reads as pressed.
    var isOn = false
    let action: () -> Void
}

/// 2–3 verbs under the answer (PRODUCT.md §3 "Verbs under the answer"): the
/// first is the one filled button; the rest are bordered. Symbol over word
/// in equal columns; at accessibility sizes they stack as full-width rows.
struct VerbBar: View {
    let verbs: [Verb]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Spacing.s2))
            : AnyLayout(HStackLayout(spacing: Spacing.s2))
        layout {
            ForEach(Array(verbs.prefix(3).enumerated()), id: \.element.id) { index, verb in
                VerbButton(verb: verb, isPrimary: index == 0, isStacked: dynamicTypeSize.isAccessibilitySize)
            }
        }
    }
}

private struct VerbButton: View {
    let verb: Verb
    let isPrimary: Bool
    let isStacked: Bool

    @Environment(\.theme) private var theme
    /// Every symbol sits in the same box, so the words line up across verbs.
    @ScaledMetric(relativeTo: .title3) private var iconHeight: CGFloat = 26

    var body: some View {
        Button(action: verb.action) {
            label
                .frame(maxWidth: .infinity, minHeight: Size.reportTarget)
                .padding(.horizontal, Spacing.s2)
                .foregroundStyle(isPrimary ? theme.onAccentFill : theme.accent)
                .background(background, in: .rect(cornerRadius: Radius.medium))
                .contrastEdge(always: !isPrimary)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(verb.isOn ? .isSelected : [])
    }

    @ViewBuilder
    private var label: some View {
        if isStacked {
            Label { Text(verb.title) } icon: { Image(systemName: verb.symbol) }
                .textRole(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Spacing.s2)
        } else {
            VStack(spacing: 2) {
                Image(systemName: verb.symbol)
                    .font(.title3)
                    .frame(height: iconHeight)
                    .accessibilityHidden(true)
                Text(verb.title)
                    .textRole(.footnote)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, Spacing.s1)
        }
    }

    private var background: Color {
        if isPrimary { return theme.accentFill }
        return verb.isOn ? Color(.fillStrong) : Color(.paperRaised)
    }
}
