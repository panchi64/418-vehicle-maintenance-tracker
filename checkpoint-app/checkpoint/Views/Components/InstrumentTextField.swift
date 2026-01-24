//
//  InstrumentTextField.swift
//  checkpoint
//
//  Custom dark instrument-panel styled text input
//

import SwiftUI

struct InstrumentTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .sentences

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label
            Text(label.uppercased())
                .font(.instrumentLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)

            // Input field
            TextField(placeholder, text: $text)
                .font(.instrumentBody)
                .foregroundStyle(Theme.textPrimary)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .focused($isFocused)
                .padding(16)
                .background(Theme.surfaceInstrument)
                .clipShape(Rectangle())
                .overlay(
                    Rectangle()
                        .strokeBorder(
                            isFocused ? Theme.accent : Theme.gridLine,
                            lineWidth: Theme.borderWidth
                        )
                )
                .animation(.easeOut(duration: Theme.animationFast), value: isFocused)
        }
    }
}

// MARK: - Instrument Number Field

struct InstrumentNumberField: View {
    let label: String
    @Binding var value: Int?
    var placeholder: String = ""
    var suffix: String = ""

    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label
            Text(label.uppercased())
                .font(.instrumentLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)

            // Input field
            HStack(spacing: 8) {
                TextField(placeholder, text: $textValue)
                    .font(.instrumentBody)
                    .foregroundStyle(Theme.textPrimary)
                    .keyboardType(.numberPad)
                    .focused($isFocused)
                    .onChange(of: textValue) { _, newValue in
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            textValue = filtered
                        }
                        value = Int(filtered)
                    }
                    .onAppear {
                        if let value = value {
                            textValue = String(value)
                        }
                    }

                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.instrumentLabel)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(16)
            .background(Theme.surfaceInstrument)
            .clipShape(Rectangle())
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isFocused ? Theme.accent : Theme.gridLine,
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            .animation(.easeOut(duration: Theme.animationFast), value: isFocused)
        }
    }
}

// MARK: - Instrument Date Picker

struct InstrumentDatePicker: View {
    let label: String
    @Binding var date: Date
    var displayedComponents: DatePicker<Label>.Components = .date

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label
            Text(label.uppercased())
                .font(.instrumentLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)

            // Date picker container
            DatePicker("", selection: $date, displayedComponents: displayedComponents)
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(Theme.accent)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surfaceInstrument)
                .clipShape(Rectangle())
                .overlay(
                    Rectangle()
                        .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                )
        }
    }
}

// MARK: - Instrument Toggle

struct InstrumentToggle: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.instrumentBody)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Theme.accent)
        }
        .padding(16)
        .background(Theme.surfaceInstrument)
        .clipShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.gridLine, lineWidth: 1)
        )
    }
}

// MARK: - Instrument Text Editor

struct InstrumentTextEditor: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var minHeight: CGFloat = 100

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label
            Text(label.uppercased())
                .font(.instrumentLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)

            // Text editor
            ZStack(alignment: .topLeading) {
                if text.isEmpty && !isFocused {
                    Text(placeholder)
                        .font(.instrumentBody)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                }

                TextEditor(text: $text)
                    .font(.instrumentBody)
                    .foregroundStyle(Theme.textPrimary)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .padding(12)
            }
            .frame(minHeight: minHeight)
            .background(Theme.surfaceInstrument)
            .clipShape(Rectangle())
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isFocused ? Theme.accent : Theme.gridLine,
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            .animation(.easeOut(duration: Theme.animationFast), value: isFocused)
        }
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        ScrollView {
            VStack(spacing: Spacing.lg) {
                InstrumentTextField(
                    label: "Vehicle Name",
                    text: .constant("Daily Driver"),
                    placeholder: "Enter name..."
                )

                InstrumentNumberField(
                    label: "Mileage",
                    value: .constant(32500),
                    placeholder: "0",
                    suffix: "mi"
                )

                InstrumentDatePicker(
                    label: "Due Date",
                    date: .constant(Date())
                )

                InstrumentToggle(
                    label: "Enable Notifications",
                    isOn: .constant(true)
                )

                InstrumentTextEditor(
                    label: "Notes",
                    text: .constant(""),
                    placeholder: "Add notes..."
                )
            }
            .padding(Spacing.screenHorizontal)
        }
    }
    .preferredColorScheme(.dark)
}
