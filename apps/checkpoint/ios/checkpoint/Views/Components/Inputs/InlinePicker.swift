//
//  InlinePicker.swift
//  checkpoint
//
//  A one-of-N form value that does not deserve a visible option set.
//
//  Replaces the six outlined category chips on the service form. Category has a
//  sensible default and is rarely changed, so six permanent enclosures were six
//  rectangles spent on a decision most users never make — while the timing
//  chips, which every user must answer, looked exactly the same.
//
//  Shaped like a field (label, value, rule) so a form reads as one column of
//  lines rather than a mix of lines and boxes.
//
//  Unlike `FilterControl`, the trigger shows the VALUE: this sets a value rather
//  than narrowing a list, and it is not sharing a row with another control, so a
//  value-dependent width is safe here.
//

import SwiftUI

struct InlinePicker<Value: Hashable>: View {
    var label: String?
    let options: [PickerOption<Value>]
    @Binding var selection: Value

    @State private var isExpanded = false

    private var activeLabel: String {
        options.first { $0.value == selection }?.label ?? "—"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let label {
                Text(label.uppercased())
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)
            }

            Button {
                isExpanded = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    Text(activeLabel)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .frame(minHeight: 40)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(isExpanded ? Theme.accent : Theme.borderSubtle)
                        .frame(height: Theme.borderWidth)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .animation(.easeOut(duration: Theme.animationMedium), value: isExpanded)
            .accessibilityLabel(label ?? "")
            .accessibilityValue(activeLabel)
            .optionListPopover(
                isPresented: $isExpanded,
                options: options,
                selection: selection
            ) { selection = $0 }
        }
    }
}

#Preview {
    @Previewable @State var category = "maintenance"

    return ZStack {
        AtmosphericBackground()

        VStack(alignment: .leading, spacing: Spacing.md) {
            InlinePicker(
                label: "Category",
                options: [
                    PickerOption(value: "maintenance", label: "Maintenance"),
                    PickerOption(value: "repair", label: "Repair"),
                    PickerOption(value: "inspection", label: "Inspection"),
                    PickerOption(value: "other", label: "Other")
                ],
                selection: $category
            )
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
