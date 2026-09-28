import SwiftUI

/// A row with a leading part and a trailing label ("Bairoa · LUMA lo
/// confirma", "Diésel · $1.08"): side by side when they fit, the label
/// under the leading part when they don't, so neither is squeezed or
/// breaks mid-word. At least one 44pt target tall; VoiceOver reads it as one.
struct SplitRow<Leading: View, Trailing: View>: View {
    var stackedSpacing: CGFloat = 2
    @ViewBuilder let leading: Leading
    @ViewBuilder let trailing: Trailing

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                leading
                Spacer(minLength: Spacing.s2)
                trailing
            }
            VStack(alignment: .leading, spacing: stackedSpacing) {
                leading
                trailing
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: Size.target, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
