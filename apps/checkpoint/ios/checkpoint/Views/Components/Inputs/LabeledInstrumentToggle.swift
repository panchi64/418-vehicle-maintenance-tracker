import SwiftUI

/// A toggle row: label on the leading side, an accent-tinted iOS toggle on the
/// trailing side.
///
/// UNBOXED, like every other control in a form. It used to carry a filled
/// background and a full border, which was fine when the fields around it were
/// boxed too — once they became single rules, this was the only enclosure left
/// in its section, so the heaviest treatment on screen landed on the least
/// important control. Enclosure is a budget; a toggle does not need to spend it,
/// because the switch itself is already an unambiguous affordance.
///
/// The label is 15 Regular rather than 11pt tracked caps: it is a statement the
/// switch turns on or off ("Repeat after completion"), not a field label naming
/// the value beside it.
struct LabeledInstrumentToggle: View {
    let label: String
    let accessibilityLabel: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text(label)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Theme.accent)
                .accessibilityLabel(accessibilityLabel)
        }
        .frame(minHeight: TouchTarget.minimum)
        .accessibilityElement(children: .combine)
    }
}
