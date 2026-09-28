import SwiftUI

/// "Otra cosa…": the seven layers, Servicios then Del día a día, marked
/// with their pins (the Capas pattern without answers, direction §3.6).
/// A layer with nothing in reach says what to get close to.
struct ReportLayerList: View {
    let context: ReportContext
    let onPick: (Layer) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s5) {
            group(.services, title: LocalizedStringResource("Servicios", comment: "Capas group: power, water, signal and roads"))
            group(.everyday, title: LocalizedStringResource("Del día a día", comment: "Capas group: gas, chargers and businesses"))
        }
    }

    private func group(_ group: Layer.Group, title: LocalizedStringResource) -> some View {
        let layers = Layer.allCases.filter { $0.group == group }
        return SectionGroup(title: title) {
            RowList(elements: layers, isInset: true) { layer in
                let inReach = context.target(for: layer)?.isInReach == true
                PinChoiceRow(
                    layer: layer,
                    title: Text(layer.title),
                    subtitle: inReach ? nil : layer.reachHint.map { Text($0) },
                    accessory: .forward,
                    isMuted: !inReach
                ) { onPick(layer) }
            }
        }
    }
}

/// One layer's page: where it lands (with Cambiar), at most four verbs,
/// and the rest in one Más menu so every report stays reachable (N13).
struct ReportLayerPage: View {
    let layer: Layer
    let context: ReportContext
    let canChange: Bool
    let onPick: (ReportKind) -> Void
    let onChange: () -> Void

    @Environment(\.locale) private var locale

    var body: some View {
        let target = context.target(for: layer)
        let inReach = target?.isInReach == true
        VStack(alignment: .leading, spacing: Spacing.s4) {
            HStack(spacing: Spacing.s2) {
                Text(whereText(target))
                    .textRole(.body)
                    .foregroundStyle(Color(.ink2))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Spacing.s2)
                if canChange {
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
            VStack(alignment: .leading, spacing: 0) {
                RowList(elements: ReportVocabulary.primary(for: layer, isCrisis: context.isCrisis), isInset: true) { kind in
                    PinChoiceRow(layer: layer, glyph: kind.glyph, title: Text(kind.verb)) { onPick(kind) }
                }
            }
            .insetGroup()
            .disabled(!inReach)
            let more = ReportVocabulary.more(for: layer, isCrisis: context.isCrisis)
            if !more.isEmpty {
                Menu {
                    ForEach(more, id: \.self) { kind in
                        Button { onPick(kind) } label: { Text(kind.verb) }
                    }
                } label: {
                    DisclosureLabel(title: LocalizedStringResource("Más", comment: "Quick Report: more report types for this layer"), symbol: "ellipsis.circle", accessory: .expand)
                }
                .disabled(!inReach)
                .opacity(inReach ? 1 : 0.5)
            }
        }
    }

    private func whereText(_ target: ReportTarget?) -> LocalizedStringResource {
        guard let target else {
            return layer.reachHint ?? LocalizedStringResource("No sabemos en qué barrio estás.", comment: "Quick Report context: nothing in reach to report on")
        }
        let away = GlanceNumbers.distance(meters: target.distance, locale: locale)
        guard target.isInReach else {
            return LocalizedStringResource("Estás a \(away) de \(target.place.displayName).", comment: "Quick Report context: the place is too far to report on")
        }
        if target.place.kind == .area {
            return LocalizedStringResource("En \(target.place.displayName), \(target.place.municipio)", comment: "Quick Report layer page: the barrio the report lands in")
        }
        return LocalizedStringResource("En \(target.place.displayName) · a \(away)", comment: "Quick Report layer page: the place the report lands on and how far")
    }
}

/// Cambiar: every place of the layer's kind in reach, nearest first.
struct ReportPlacePicker: View {
    let targets: [ReportTarget]
    let chosen: Place.ID?
    let onChoose: (Place.ID) -> Void

    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RowList(elements: targets, isInset: true) { target in
                PinChoiceRow(
                    layer: target.place.kind.layer,
                    title: Text(verbatim: target.place.displayName),
                    subtitle: Text(target.distanceLine(locale: locale)),
                    accessory: target.place.id == chosen ? .selected : .none
                ) { onChoose(target.place.id) }
            }
        }
        .insetGroup()
    }
}
