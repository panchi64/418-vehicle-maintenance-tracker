import SwiftUI

/// Paso 1 (Flows-Onboarding1): what Biombo is, answered first.
/// The painted island has no high-contrast variant, so as on the map it
/// stays away with Increase Contrast, and at accessibility sizes it gives
/// its room to the words.
struct WelcomePage: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s5) {
            if contrast != .increased, !typeSize.isAccessibilitySize {
                Image(.paintedIsland)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text(verbatim: "Biombo")
                    .textRole(.wordmark)
                    .foregroundStyle(Color(.ink))
                    .accessibilityAddTraits(.isHeader)
                Text("Lo que pasa en la isla, en un mapa", comment: "First run: what Biombo is, in one line")
                    .textRole(.answer)
                    .foregroundStyle(Color(.ink))
                Text("Vecinos y fuentes oficiales reportan cómo está todo ahora mismo. Tú ves solo lo reciente.", comment: "First run: who reports, and that only recent reports show")
                    .textRole(.body)
                    .foregroundStyle(Color(.ink2))
            }
            .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: Spacing.s4) {
                FeatureLine(
                    symbol: Layer.gas.symbol,
                    title: Layer.gas.title,
                    text: LocalizedStringResource("Lo que pagan tus vecinos, al lado de la referencia de DACO.", comment: "First run: what the gas layer shows")
                )
                FeatureLine(
                    symbol: Layer.power.symbol,
                    title: LocalizedStringResource("Luz, agua y señal", comment: "First run: the utility layers, together"),
                    text: LocalizedStringResource("Avisos de LUMA y la AAA, y lo que ven en tu calle.", comment: "First run: what the utility layers show")
                )
                FeatureLine(
                    symbol: Layer.roads.symbol,
                    title: Layer.roads.title,
                    text: LocalizedStringResource("Inundaciones, derrumbes y cierres mientras están pasando.", comment: "First run: what the roads layer shows")
                )
            }
        }
    }
}

/// Paso 2 (Flows-Onboarding2): which layers the map draws, and whether to
/// watch a place somewhere else.
struct LayersPage: View {
    @Binding var flow: OnboardingFlow

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s5) {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text("¿Qué quieres ver?", comment: "First run: pick the layers")
                    .textRole(.answer)
                    .foregroundStyle(Color(.ink))
                    .accessibilityAddTraits(.isHeader)
                Text("Lo puedes cambiar cuando quieras desde el mapa.", comment: "First run: layers can change later in Capas")
                    .textRole(.body)
                    .foregroundStyle(Color(.ink2))
            }
            .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 0) {
                // At accessibility sizes the rows stack, so the words start at the edge.
                RowList(elements: Layer.allCases, isInset: !typeSize.isAccessibilitySize) { layer in
                    LayerChoiceRow(
                        layer: layer,
                        isOn: flow.layers.contains(layer),
                        accessibilityValue: Text(layer.pitch),
                        action: { flow.toggle(layer) }
                    ) {
                        Text(layer.pitch)
                            .textRole(.footnote)
                            .foregroundStyle(Color(.ink3))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .insetGroup()
            Text("Luz, agua, gasolina y carreteras vienen encendidas. En una emergencia, siempre se muestran primero.", comment: "First run: which layers are on by default, and crisis shows services first")
                .textRole(.footnote)
                .foregroundStyle(Color(.ink2))
                .fixedSize(horizontal: false, vertical: true)
            watchChoice
        }
    }

    /// The diaspora's first job (§2): a place off the map you care about.
    /// The whole row flips it, not only the switch.
    private var watchChoice: some View {
        Toggle(isOn: $flow.wantsToWatch) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Vigilar un lugar", comment: "First run: also watch a place, e.g. family elsewhere")
                    .textRole(.body)
                    .foregroundStyle(Color(.ink))
                Text("¿Familia en otro pueblo? Te avisamos si allí se va la luz o el agua.", comment: "First run: why watch a place")
                    .textRole(.footnote)
                    .foregroundStyle(Color(.ink3))
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { flow.wantsToWatch.toggle() }
        }
        .frame(minHeight: Size.target)
        .insetGroup()
    }
}

/// Paso 3 (Flows-Onboarding3): why location, before the system asks.
struct LocationPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s5) {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text("¿Te mostramos lo que pasa cerca?", comment: "First run: the location question")
                    .textRole(.answer)
                    .foregroundStyle(Color(.ink))
                    .accessibilityAddTraits(.isHeader)
                Text("Con tu ubicación, el mapa abre donde estás.", comment: "First run: what location does")
                    .textRole(.body)
                    .foregroundStyle(Color(.ink2))
            }
            .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: Spacing.s4) {
                FeatureLine(
                    symbol: "clock",
                    title: LocalizedStringResource("Lo reciente, primero", comment: "First run, location: recent news first"),
                    text: LocalizedStringResource("Luz, agua, gasolina y carreteras a tu alrededor.", comment: "First run, location: what shows nearby")
                )
                FeatureLine(
                    symbol: "mappin.and.ellipse",
                    title: LocalizedStringResource("Reportes en la calle correcta", comment: "First run, location: reports land in the right place"),
                    text: LocalizedStringResource("Tu reporte cae donde estás, sin escribir la dirección.", comment: "First run, location: no typing an address")
                )
                FeatureLine(
                    symbol: "person.slash",
                    title: LocalizedStringResource("Nadie ve quién reportó", comment: "First run, location: anonymity"),
                    text: LocalizedStringResource("Los reportes se muestran por calle, nunca por persona.", comment: "First run, location: reports show by street, never by person")
                )
            }
        }
    }
}
