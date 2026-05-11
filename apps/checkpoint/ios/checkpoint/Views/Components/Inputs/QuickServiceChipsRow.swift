import SwiftUI

/// Horizontal scroller of tap-to-select service preset chips, shown above
/// the full service-type picker as a one-tap shortcut.
struct QuickServiceChipsRow: View {
    let chips: [PresetData]
    let onSelect: (PresetData) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(chips, id: \.name) { preset in
                    Button { onSelect(preset) } label: {
                        Text(preset.name.uppercased())
                            .font(.brutalistLabel)
                            .tracking(1)
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(Theme.surfaceInstrument)
                            .overlay(
                                Rectangle()
                                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Quick select \(preset.name)")
                }
            }
        }
    }
}
