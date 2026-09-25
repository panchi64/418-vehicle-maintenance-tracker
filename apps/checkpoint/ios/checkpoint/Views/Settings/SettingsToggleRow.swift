//
//  SettingsToggleRow.swift
//  checkpoint
//
//  A Settings row whose control is a switch. The title and description are
//  the Toggle's own label, so VoiceOver reads "Title, description, switch,
//  on" as one element and a double-tap flips it — no hidden label to keep in
//  sync with the visible one.
//

import SwiftUI

struct SettingsToggleRow: View {
    let title: String
    var subtitle: String?
    var subtitleColor: Color = Theme.textTertiary
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.brutalistSecondary)
                        .foregroundStyle(subtitleColor)
                }
            }
        }
        .tint(Theme.accent)
        .padding(Spacing.md)
        .frame(minHeight: TouchTarget.minimum)
    }
}

/// A toggle row bound to a stored setting: seeds from `read`, writes through
/// `write` with a selection haptic on every change.
struct SettingToggle: View {
    let title: String
    var subtitle: String?
    let write: @MainActor (Bool) -> Void

    @State private var isOn: Bool

    init(
        title: String,
        subtitle: String? = nil,
        read: () -> Bool,
        write: @escaping @MainActor (Bool) -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.write = write
        _isOn = State(initialValue: read())
    }

    var body: some View {
        SettingsToggleRow(title: title, subtitle: subtitle, isOn: $isOn)
            .onChange(of: isOn) { _, newValue in
                HapticService.shared.selectionChanged()
                write(newValue)
            }
    }
}
