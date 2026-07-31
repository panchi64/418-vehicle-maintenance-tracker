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
//  Presented in a popover rather than as an overlay: on a touch screen the list
//  needs a way out that isn't "find the trigger again", and a popover gets
//  tap-away dismissal, anchoring, and safe-area avoidance for free.
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
                        // Selection is a rule plus weight, not color alone —
                        // color is spoken for by status semantics, and in the
                        // default theme `accent` equals `textPrimary`, so an
                        // accent-tinted label is no signal at all there.
                        Rectangle()
                            .fill(isSelected ? Theme.accent : Color.clear)
                            .frame(width: Theme.borderWidth)

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
                    .padding(.trailing, Spacing.md)
                    .frame(minHeight: TouchTarget.minimum)
                    .background(isSelected ? Theme.backgroundSubtle : Color.clear)
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
        .frame(minWidth: 190)
        .background(Theme.backgroundElevated)
    }
}

// MARK: - Presentation

extension View {
    /// Presents an `OptionList` anchored to this view, as a popover on every
    /// size class rather than a sheet on compact ones — the list belongs to the
    /// control that opened it, and a full sheet for four statuses is a
    /// disproportionate amount of ceremony.
    func optionListPopover<Value: Hashable>(
        isPresented: Binding<Bool>,
        options: [PickerOption<Value>],
        selection: Value,
        onSelect: @escaping (Value) -> Void
    ) -> some View {
        popover(isPresented: isPresented, arrowEdge: .top) {
            OptionList(options: options, selection: selection) { value in
                onSelect(value)
                isPresented.wrappedValue = false
            }
            .presentationCompactAdaptation(.popover)
            .presentationBackground(Theme.backgroundElevated)
            .fixedSize()
        }
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
        .brutalistBorder(color: Theme.accent)
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
