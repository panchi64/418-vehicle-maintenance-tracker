import SwiftUI

/// Horizontal scroller of tap-to-select service preset chips, shown above
/// the full service-type picker as a one-tap shortcut. Thin wrapper around
/// `ChipRow` so all chip strips in the form share one visual primitive.
struct QuickServiceChipsRow: View {
    let chips: [PresetData]
    let onSelect: (PresetData) -> Void

    var body: some View {
        ChipRow(items: chips, label: \.name, onTap: onSelect)
    }
}
