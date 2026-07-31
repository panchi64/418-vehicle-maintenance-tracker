import SwiftUI

/// Horizontal scroller of tap-to-select service preset chips, shown beneath the
/// service-name field as a one-tap shortcut.
///
/// `.plain`, not `.decision`: these fill the field above them, so an enclosure
/// here would make the shortcuts look like the same kind of control as the input
/// they populate — and since tapping one copies its text into that field, the
/// same words would appear twice in the same treatment.
struct QuickServiceChipsRow: View {
    let chips: [PresetData]
    var selectedName: String?
    let onSelect: (PresetData) -> Void

    var body: some View {
        ScrollingChipRow(
            items: chips,
            label: \.name,
            variant: .plain,
            isSelected: { selectedName?.caseInsensitiveCompare($0.name) == .orderedSame },
            onTap: onSelect
        )
    }
}
