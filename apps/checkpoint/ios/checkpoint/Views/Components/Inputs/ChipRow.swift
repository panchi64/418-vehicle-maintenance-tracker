import SwiftUI

/// Horizontal scroller of tap-to-select chips for any `Hashable` item type.
/// Mirrors the visual treatment of `QuickServiceChipsRow` so chip strips for
/// fuzzy date entry, interval shortcuts, etc. read as the same primitive.
struct ChipRow<Item: Hashable>: View {
    let items: [Item]
    let label: (Item) -> String
    let onTap: (Item) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(items, id: \.self) { item in
                    Button { onTap(item) } label: {
                        Text(label(item).uppercased())
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
                    .accessibilityLabel("Use \(label(item))")
                }
            }
        }
    }
}
