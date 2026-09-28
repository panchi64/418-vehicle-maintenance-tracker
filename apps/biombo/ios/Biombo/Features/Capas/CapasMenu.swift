import SwiftUI

/// Capas (PRODUCT.md §3, V2-Capas): a glass menu that also answers. A title
/// sentence naming which layers have news, Servicios then Del día a día — 7
/// rows, each with a live mini-answer — and the Pintado / Sencillo switch.
struct CapasMenu: View {
    let layers: [LayerDigest]
    let visibleLayers: Set<Layer>
    let isCrisis: Bool
    let isEverydayExpanded: Bool
    let onToggle: (Layer) -> Void
    let onExpandEveryday: () -> Void
    let onWatchList: () -> Void
    let onContribution: () -> Void
    let onSettings: () -> Void

    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.locale) private var locale

    /// The layers scroll when they don't fit; the footer (watch list, Tu
    /// aporte, Ajustes) stays pinned under them, so it's never below the fold.
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ViewThatFits(in: .vertical) {
                content
                ScrollView { content }
                    .scrollIndicatorsFlash(onAppear: true)
            }
            Divider()
                .padding(.horizontal, Spacing.s4)
            footer
        }
        .frame(maxWidth: 320)
        .background {
            // Increase Contrast trades the glass for opaque paper, like the sheet.
            if contrast == .increased {
                RoundedRectangle(cornerRadius: Radius.menu)
                    .fill(Color(.paperSheet))
                    .overlay(RoundedRectangle(cornerRadius: Radius.menu).strokeBorder(Color(.borderStrong), lineWidth: 1))
            }
        }
        .glassEffect(contrast == .increased ? .identity : .regular, in: .rect(cornerRadius: Radius.menu))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Capas", comment: "The layers menu title"))
        .accessibilityAddTraits(.isModal)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Capas", comment: "The layers menu title")
                    .textRole(.footnote)
                    .foregroundStyle(Color(.ink3))
                    .accessibilityAddTraits(.isHeader)
                Text(newsLayers.newsSentence(locale: locale))
                    .textRole(.answerSmall)
                    .foregroundStyle(Color(.ink))
            }
            group(.services, title: LocalizedStringResource("Servicios", comment: "Capas group: power, water, signal and roads"))
            if isCrisis && !isEverydayExpanded {
                collapsedEveryday
            } else {
                group(.everyday, title: LocalizedStringResource("Del día a día", comment: "Capas group: gas, chargers and businesses"))
            }
            Divider()
            MapGroundPicker(isCrisis: isCrisis)
        }
        .padding(Spacing.s4)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 0) {
            footerButton(LocalizedStringResource("Lugares que vigilas", comment: "Title: the watch list"), symbol: "eye", action: onWatchList)
            footerButton(LocalizedStringResource("Tu aporte", comment: "Title: your contributions and level"), symbol: "hand.raised", action: onContribution)
            footerButton(LocalizedStringResource("Ajustes", comment: "Settings screen title"), symbol: "gearshape", action: onSettings)
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.vertical, Spacing.s2)
    }

    private func footerButton(_ title: LocalizedStringResource, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label { Text(title) } icon: { Image(systemName: symbol) }
                .textRole(.subheadline)
                .frame(maxWidth: .infinity, minHeight: Size.target, alignment: .leading)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.tint)
    }

    /// The answer names which visible layers have news, not how many are on.
    private var newsLayers: [Layer] {
        layers.filter { $0.hasNews && visibleLayers.contains($0.layer) }.map(\.layer)
    }

    private func group(_ group: Layer.Group, title: LocalizedStringResource) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .textRole(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color(.ink3))
                .accessibilityAddTraits(.isHeader)
            ForEach(layers.filter { $0.layer.group == group }) { digest in
                CapasRow(digest: digest, isVisible: visibleLayers.contains(digest.layer)) {
                    onToggle(digest.layer)
                }
            }
        }
    }

    /// In crisis, Del día a día is one row until opened (§8).
    private var collapsedEveryday: some View {
        Button(action: onExpandEveryday) {
            HStack(spacing: Spacing.s3) {
                LayerPin(layer: .gas)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Del día a día", comment: "Capas group: gas, chargers and businesses")
                        .textRole(.body)
                        .foregroundStyle(Color(.ink))
                    Text("Mostrar las 3 capas", comment: "Capas, crisis: expand the collapsed everyday layers")
                        .textRole(.footnote)
                        .foregroundStyle(Color(.ink3))
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .foregroundStyle(Color(.ink3))
                    .accessibilityHidden(true)
            }
            .frame(minHeight: Size.target)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
