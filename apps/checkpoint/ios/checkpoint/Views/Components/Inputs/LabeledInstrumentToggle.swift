import SwiftUI

/// A bordered toggle row: uppercase tertiary label on the leading side, an
/// accent-tinted iOS toggle on the trailing side. Used across the Add/Edit
/// Service forms to keep toggle-row styling consistent.
struct LabeledInstrumentToggle: View {
    let label: String
    let accessibilityLabel: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Theme.accent)
                .accessibilityLabel(accessibilityLabel)
        }
        .padding(Spacing.md)
        .accessibilityElement(children: .combine)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
    }
}
