//
//  OptionList.swift
//  checkpoint
//
//  The option panel shared by `FilterControl` and `InlinePicker`.
//
//  Extracted on the second use rather than the third. The two triggers differ —
//  a filter names its dimension, a form field shows its value — but the list
//  they open is the same object, and two copies would drift.
//
//  Presented as an inline band that pushes content down, NOT as a popover. A
//  SwiftUI popover draws its own rounded, translucent system chrome, which
//  cannot be squared off — and every corner radius in this app is 0. It also
//  floats a narrow panel over content, where a full-width band can't truncate an
//  option label.
//
//  This is the same disclosure idiom the vehicle specs panel already uses:
//  expand in place, collapse by re-tapping the trigger or by choosing.
//

import SwiftUI

struct PickerOption<Value: Hashable>: Identifiable {
    let value: Value
    let label: String
    /// Shown beside the option, so choosing is informed rather than a guess
    /// followed by an empty list.
    var count: Int?

    var id: Value { value }

    init(value: Value, label: String, count: Int? = nil) {
        self.value = value
        self.label = label
        self.count = count
    }
}

struct OptionList<Value: Hashable>: View {
    let options: [PickerOption<Value>]
    let selection: Value
    let onSelect: (Value) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                let isSelected = option.value == selection

                Button {
                    onSelect(option.value)
                } label: {
                    HStack(spacing: Spacing.md) {
                        Text(option.label)
                            .font(isSelected ? .brutalistBodyEmphasis : .brutalistBody)
                            .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if let count = option.count {
                            Text(String(count))
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.textTertiary)
                                .monospacedDigit()
                        }
                    }
                    // Text lands on the same left edge as the screen content
                    // below the band, with the selection rule occupying the
                    // 2pt outboard of it.
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .frame(minHeight: TouchTarget.minimum)
                    .background(isSelected ? Theme.backgroundSubtle : Color.clear)
                    // Selection is a rule plus weight, not color alone — color
                    // is spoken for by status semantics, and in the default
                    // theme `accent` equals `textPrimary`, so an accent-tinted
                    // label is no signal at all there.
                    //
                    // An overlay rather than an HStack member: a bare Rectangle
                    // in the flow has no ideal height, so it drove each row to
                    // fill whatever space the band offered.
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(isSelected ? Theme.accent : Color.clear)
                            .frame(width: Theme.borderWidth)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)

                if index < options.count - 1 {
                    Rectangle()
                        .fill(Theme.gridLine)
                        .frame(height: 1)
                }
            }
        }
        .background(Theme.backgroundElevated)
        // Fade only, per AESTHETIC.md (Motion) — never slide.
        .transition(.opacity)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        OptionList(
            options: [
                PickerOption(value: "all", label: "All", count: 24),
                PickerOption(value: "overdue", label: "Overdue", count: 2),
                PickerOption(value: "dueSoon", label: "Due soon", count: 5),
                PickerOption(value: "onTrack", label: "On track", count: 17)
            ],
            selection: "overdue"
        ) { _ in }
    }
    .preferredColorScheme(.dark)
}
