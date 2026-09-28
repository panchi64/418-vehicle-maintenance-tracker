import SwiftUI

/// The one filled, full-width button a flow step ends with ("Enviar precio",
/// "Empezar", "Publicar"). 56pt tall; the crisis tint swaps in with the theme.
/// Disabled, it keeps its word in readable ink on a neutral fill.
struct PrimaryButton: View {
    let title: LocalizedStringResource
    var symbol: String?
    let action: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Label {
                Text(title)
            } icon: {
                if let symbol { Image(systemName: symbol).accessibilityHidden(true) }
            }
            .labelStyle(.titleAndIcon)
            .textRole(.headline)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.s3)
            .frame(maxWidth: .infinity, minHeight: Size.reportTarget)
            .foregroundStyle(isEnabled ? theme.onAccentFill : Color(.ink2))
            .background(isEnabled ? theme.accentFill : Color(.fillStrong), in: .rect(cornerRadius: Radius.medium))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
