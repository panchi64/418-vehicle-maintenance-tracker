import SwiftUI

/// The glass control stack at the top trailing edge (V2 boards): Capas,
/// Mi ubicación and Reportar aquí. No floating action button. A long press
/// on Reportar aquí offers the three reports that fit where you stand, so
/// one of them goes out without opening anything (PRODUCT.md §10).
struct MapControls: View {
    /// The one-tap reports in reach where you stand, for the long press.
    let quickReports: QuickReports
    let onCapas: () -> Void
    let onLocate: () -> Void
    let onReport: () -> Void
    let onQuickReport: (ReportKind) -> Void

    var body: some View {
        VStack(spacing: 0) {
            button("square.3.layers.3d", title: LocalizedStringResource("Capas", comment: "Map control: open the layers menu"), action: onCapas)
            Divider().frame(width: Size.control * 0.6)
            button("location.fill", title: LocalizedStringResource("Mi ubicación", comment: "Map control: centre the map on you"), isTinted: true, action: onLocate)
            Divider().frame(width: Size.control * 0.6)
            reportButton
        }
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: Size.control / 2))
    }

    private var reportTitle: LocalizedStringResource {
        LocalizedStringResource("Reportar aquí", comment: "Map control: report something where you are")
    }

    /// A tap opens Quick Report; a long press is a native menu of the reports in reach.
    @ViewBuilder
    private var reportButton: some View {
        if quickReports.kinds.isEmpty {
            button("exclamationmark.bubble", title: reportTitle, action: onReport)
        } else {
            Menu {
                // Where they land first, as Quick Report's title says it.
                Section {
                    ForEach(quickReports.kinds, id: \.self) { kind in
                        Button { onQuickReport(kind) } label: {
                            Label { Text(kind.verb) } icon: { Image(systemName: kind.menuSymbol) }
                        }
                    }
                } header: {
                    Text(quickReports.title)
                }
            } label: {
                glyph("exclamationmark.bubble", isTinted: false)
            } primaryAction: {
                onReport()
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(reportTitle))
            .accessibilityHint(Text("Mantén presionado para reportar con un toque.", comment: "VoiceOver hint: long-press Reportar aquí for one-tap reports"))
            .accessibilityShowsLargeContentViewer {
                Label { Text(reportTitle) } icon: { Image(systemName: "exclamationmark.bubble") }
            }
        }
    }

    private func button(_ symbol: String, title: LocalizedStringResource, isTinted: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            glyph(symbol, isTinted: isTinted)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
        // The glyph stops growing to fit the 48pt stack; a long press shows it large, with its name.
        .accessibilityShowsLargeContentViewer {
            Label { Text(title) } icon: { Image(systemName: symbol) }
        }
    }

    private func glyph(_ symbol: String, isTinted: Bool) -> some View {
        Image(systemName: symbol)
            .font(.title3.weight(.medium))
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .foregroundStyle(isTinted ? AnyShapeStyle(.tint) : AnyShapeStyle(Color(.ink)))
            .frame(width: Size.control, height: Size.control)
            .contentShape(.rect)
    }
}

/// The long press's reports and the title that says where they land.
struct QuickReports {
    let kinds: [ReportKind]
    /// "Reportar en Pueblo Viejo".
    let title: LocalizedStringResource
}

extension ReportKind {
    /// A menu item's symbol: the pin glyph, or the layer's own where the glyph is a bare mark.
    var menuSymbol: String {
        glyph == "exclamationmark" || glyph == "xmark" ? "exclamationmark.triangle" : glyph
    }
}
