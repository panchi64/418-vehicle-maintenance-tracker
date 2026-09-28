import SwiftUI

/// Quick Report's first screen (direction §3.6): the answer first — where
/// the report lands, with Cambiar — then three one-tap verbs as 56pt rows
/// and "Otra cosa…". At most five targets before any choice.
struct QuickReportMenu: View {
    let context: ReportContext
    let hasChoices: Bool
    let onPick: (ReportKind) -> Void
    let onChange: () -> Void
    let onOther: () -> Void

    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            contextLine
            VStack(alignment: .leading, spacing: 0) {
                RowList(elements: context.oneTap, isInset: true) { kind in
                    PinChoiceRow(layer: kind.layer, glyph: kind.glyph, title: Text(kind.verb)) { onPick(kind) }
                        .disabled(context.target(for: kind)?.isInReach != true)
                }
                RowDivider()
                // A plain mark: it's about any layer, not the lead's.
                PinChoiceRow(
                    layer: nil,
                    glyph: "ellipsis",
                    title: Text("Otra cosa…", comment: "Quick Report: report something not listed"),
                    accessory: .forward,
                    action: onOther
                )
            }
            .insetGroup()
            Text("Un toque lo envía. Puedes deshacerlo.", comment: "Quick Report footer: one tap sends, and it can be undone")
                .textRole(.footnote)
                .foregroundStyle(Color(.ink2))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// "Estás dentro de un área sin luz. · Oficial · LUMA", then where, with Cambiar.
    private var contextLine: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(context.leadSentence(locale: locale))
                .textRole(.body)
                .foregroundStyle(Color(.ink))
                .fixedSize(horizontal: false, vertical: true)
            if let outage = context.outage, context.standsInOutage {
                VerificationBadge(label: outage.label)
            }
            if let line = context.whereLine(locale: locale) {
                HStack(spacing: Spacing.s2) {
                    Text(line)
                        .textRole(.footnote)
                        .foregroundStyle(Color(.ink2))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: Spacing.s2)
                    if hasChoices {
                        Button(action: onChange) {
                            Text("Cambiar", comment: "Quick Report: pick another place in reach")
                                .textRole(.subheadline)
                                .frame(minHeight: Size.target)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.tint)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}
