import SwiftUI

/// Pintado or Sencillo (direction §1.1), in Capas and in Ajustes. When
/// crisis, Increase Contrast or Reduce Transparency forces Sencillo, the
/// switch is disabled and one line says why.
struct MapGroundPicker: View {
    let isCrisis: Bool
    /// Capas labels the switch "Mapa" beside it; Ajustes has a section title instead.
    var showsLabel = true

    @AppStorage(MapGround.storageKey) private var ground: MapGround = .painted
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            HStack {
                if showsLabel {
                    Text("Mapa", comment: "Capas footer: the map ground style")
                        .textRole(.subheadline)
                        .foregroundStyle(Color(.ink2))
                }
                Picker(selection: selection) {
                    Text("Pintado", comment: "Map ground: the painted island").tag(MapGround.painted)
                    Text("Sencillo", comment: "Map ground: the plain map").tag(MapGround.plain)
                } label: {
                    Text("Estilo del mapa", comment: "VoiceOver: the map style picker")
                }
                .pickerStyle(.segmented)
                .disabled(isForced)
            }
            if let reason {
                Text(reason)
                    .textRole(.footnote)
                    .foregroundStyle(Color(.ink3))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var isForced: Bool {
        MapGround.isForced(isCrisis: isCrisis, increasedContrast: contrast == .increased, reduceTransparency: reduceTransparency)
    }

    private var reason: LocalizedStringResource? {
        guard isForced else { return nil }
        if isCrisis {
            return LocalizedStringResource("En emergencia el mapa es sencillo.", comment: "Capas: why the map is plain in crisis mode")
        }
        return contrast == .increased
            ? LocalizedStringResource("Con más contraste el mapa es sencillo.", comment: "Capas: why the map is plain with Increase Contrast")
            : LocalizedStringResource("Con menos transparencia el mapa es sencillo.", comment: "Capas: why the map is plain with Reduce Transparency")
    }

    private var selection: Binding<MapGround> {
        Binding(
            get: { isForced ? .plain : ground },
            set: { ground = $0 }
        )
    }
}
