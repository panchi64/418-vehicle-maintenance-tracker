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
    var isRequired: Bool = false

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label with optional required indicator
            HStack(spacing: 2) {
                Text(label.uppercased())
                    .font(.instrumentLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)

                if isRequired {
                    Text("*")
                        .font(.instrumentLabel)
                        .foregroundStyle(Theme.statusOverdue)
                }
            }

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
                .focusGlow(isActive: isFocused)
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
    var isRequired: Bool = false

    /// Show camera button accessory
    var showCameraButton: Bool = false

    /// Callback when camera button is tapped
    var onCameraTap: (() -> Void)?

    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label with optional required indicator
            HStack(spacing: 2) {
                Text(label.uppercased())
                    .font(.instrumentLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)

                if isRequired {
                    Text("*")
                        .font(.instrumentLabel)
                        .foregroundStyle(Theme.statusOverdue)
                }
            }

            // Input field with optional camera accessory
            HStack(spacing: 0) {
                // Main input area
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
                        .onChange(of: value) { _, newValue in
                            let newText = newValue.map { String($0) } ?? ""
                            if newText != textValue {
                                textValue = newText
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

                // Camera button accessory
                if showCameraButton, let onCameraTap = onCameraTap {
                    Button {
                        onCameraTap()
                    } label: {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 52, height: 52)
                            .background(Theme.surfaceInstrument)
                    }
                    .overlay(
                        Rectangle()
                            .strokeBorder(isFocused ? Theme.accent : Theme.gridLine, lineWidth: Theme.borderWidth)
                    )
                }
            }
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .strokeBorder(
                        isFocused ? Theme.accent : Theme.gridLine,
                        lineWidth: Theme.borderWidth
                    )
            )
            .focusGlow(isActive: isFocused)
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
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
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
                Rectangle()
                    .strokeBorder(
                        isFocused ? Theme.accent : Theme.gridLine,
                        lineWidth: Theme.borderWidth
                    )
            )
            .focusGlow(isActive: isFocused)
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
