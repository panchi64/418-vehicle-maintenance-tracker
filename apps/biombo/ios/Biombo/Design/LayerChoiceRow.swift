import SwiftUI

/// A layer the user can draw or hide: its pin silhouette, its name, one
/// line under it and a checkmark while on (Capas, the first run). The
/// state reads in the checkmark, the pin's strength and VoiceOver's
/// "selected", never in colour alone. At accessibility sizes the pin and
/// checkmark sit above the words, so the name gets the whole width and
/// never breaks mid-word.
struct LayerChoiceRow<Detail: View>: View {
    let layer: Layer
    let isOn: Bool
    /// What VoiceOver reads after the name.
    let accessibilityValue: Text
    let action: () -> Void
    @ViewBuilder let detail: Detail

    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .body) private var pinSize = Size.listPin

    var body: some View {
        Button(action: action) {
            Group {
                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: Spacing.s2) {
                        HStack {
                            pin
                            Spacer(minLength: Spacing.s2)
                            if isOn { checkmark }
                        }
                        words
                    }
                    .padding(.vertical, Spacing.s2)
                } else {
                    HStack(spacing: Spacing.s3) {
                        pin
                        words
                        Spacer(minLength: Spacing.s2)
                        // Kept in the layout while off, so the words don't shift on a tap.
                        checkmark.opacity(isOn ? 1 : 0)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: Size.target, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(layer.title))
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityHint(Text(isOn
            ? LocalizedStringResource("Toca para ocultarla del mapa", comment: "VoiceOver hint on a visible Capas row")
            : LocalizedStringResource("Toca para mostrarla en el mapa", comment: "VoiceOver hint on a hidden Capas row")))
    }

    private var pin: some View {
        LayerPin(layer: layer, size: pinSize)
            .opacity(isOn ? 1 : 0.55)
    }

    private var words: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(layer.title)
                .textRole(.body)
                .foregroundStyle(Color(.ink))
            detail
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var checkmark: some View {
        Image(systemName: "checkmark")
            .font(.body.weight(.semibold))
            .foregroundStyle(.tint)
            .accessibilityHidden(true)
    }
}
