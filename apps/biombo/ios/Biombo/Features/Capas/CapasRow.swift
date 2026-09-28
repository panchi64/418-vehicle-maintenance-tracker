import SwiftUI

/// One Capas row: a layer choice whose line is its live mini-answer. News
/// is said in words and marked, never colour alone.
struct CapasRow: View {
    let digest: LayerDigest
    let isVisible: Bool
    let action: () -> Void

    @Environment(\.locale) private var locale
    @Environment(\.priceUnit) private var unit

    var body: some View {
        LayerChoiceRow(
            layer: digest.layer,
            isOn: isVisible,
            accessibilityValue: Text(digest.live.text(unit: unit, locale: locale)),
            action: action
        ) {
            live
        }
    }

    private var live: some View {
        let isNews = digest.hasNews && isVisible
        return HStack(spacing: Spacing.s1) {
            if isNews {
                Image(systemName: "exclamationmark.circle.fill")
                    .accessibilityHidden(true)
            }
            Text(digest.live.text(unit: unit, locale: locale))
        }
        .textRole(.footnote)
        .fontWeight(isNews ? .medium : .regular)
        .foregroundStyle(Color(isNews ? .ink2 : .ink3))
        .lineLimit(2)
    }
}
