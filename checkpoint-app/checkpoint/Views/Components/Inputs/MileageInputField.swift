//
//  MileageInputField.swift
//  checkpoint
//
//  Formatted mileage input with comma separators and numeric-only validation
//

import SwiftUI

struct MileageInputField: View {
    @Binding var value: Int?
    var placeholder: String = "0"
    var suffix: String = "mi"

    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool

    private var displayValue: String {
        guard let value = value else { return "" }
        return formatMileage(value)
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            TextField(placeholder, text: $textValue)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)
                .onChange(of: textValue) { _, newValue in
                    // Strip non-numeric characters and limit to 7 digits
                    let numericOnly = String(newValue.filter { $0.isNumber }.prefix(7))
                    if let intValue = Int(numericOnly), intValue > 0 {
                        value = intValue
                        // Update textValue if it was truncated
                        if numericOnly != newValue.filter({ $0.isNumber }) {
                            textValue = numericOnly
                        }
                    } else if numericOnly.isEmpty {
                        value = nil
                    }

                    // Update display with formatting
                    if !isFocused, let val = value {
                        textValue = formatMileage(val)
                    }
                }
                .onChange(of: isFocused) { _, focused in
                    if focused {
                        // When focused, show raw number for easier editing
                        if let val = value {
                            textValue = String(val)
                        }
                    } else {
                        // When unfocused, show formatted
                        if let val = value {
                            textValue = formatMileage(val)
                        } else {
                            textValue = ""
                        }
                    }
                }

            if !suffix.isEmpty {
                Text(suffix)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .onAppear {
            if let val = value {
                textValue = formatMileage(val)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Mileage input")
        .accessibilityValue(value.map { "\(formatMileage($0)) \(suffix)" } ?? "Empty")
    }

    private func formatMileage(_ miles: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: miles)) ?? String(miles)
    }
}

// MARK: - Convenience Initializer

extension MileageInputField {
    /// Convenience initializer for String binding (backwards compatibility)
    init(stringValue: Binding<String>, placeholder: String = "0", suffix: String = "mi") {
        self._value = Binding(
            get: { Int(stringValue.wrappedValue) },
            set: { newValue in
                stringValue.wrappedValue = newValue.map(String.init) ?? ""
            }
        )
        self.placeholder = placeholder
        self.suffix = suffix
    }
}

// MARK: - Preview

#Preview("Default State") {
    VStack(spacing: Spacing.lg) {
        // Empty state
        HStack {
            Text("Empty:")
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 80, alignment: .leading)

            MileageInputField(value: .constant(nil))
                .padding(Spacing.md)
                .background(Theme.backgroundElevated)
                .clipShape(Rectangle())
        }

        // With value
        HStack {
            Text("With value:")
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 80, alignment: .leading)

            MileageInputField(value: .constant(32500))
                .padding(Spacing.md)
                .background(Theme.backgroundElevated)
                .clipShape(Rectangle())
        }

        // Large number
        HStack {
            Text("Large:")
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 80, alignment: .leading)

            MileageInputField(value: .constant(1234567))
                .padding(Spacing.md)
                .background(Theme.backgroundElevated)
                .clipShape(Rectangle())
        }

        // Custom suffix
        HStack {
            Text("Custom:")
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 80, alignment: .leading)

            MileageInputField(value: .constant(150000), suffix: "km")
                .padding(Spacing.md)
                .background(Theme.backgroundElevated)
                .clipShape(Rectangle())
        }

        // No suffix
        HStack {
            Text("No suffix:")
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 80, alignment: .leading)

            MileageInputField(value: .constant(75000), suffix: "")
                .padding(Spacing.md)
                .background(Theme.backgroundElevated)
                .clipShape(Rectangle())
        }
    }
    .padding(Spacing.xl)
    .background(Theme.backgroundPrimary)
}

#Preview("Interactive") {
    @Previewable @State var mileage: Int? = 32500

    VStack(spacing: Spacing.lg) {
        Text("Current value: \(mileage.map(String.init) ?? "nil")")
            .font(.brutalistHeading)
            .foregroundStyle(Theme.textPrimary)

        MileageInputField(value: $mileage)
            .padding(Spacing.md)
            .background(Theme.backgroundElevated)
            .clipShape(Rectangle())

        HStack(spacing: Spacing.sm) {
            Button("Set 1,000") { mileage = 1000 }
            Button("Set 100,000") { mileage = 100000 }
            Button("Clear") { mileage = nil }
        }
        .buttonStyle(.secondary)
    }
    .padding(Spacing.xl)
    .background(Theme.backgroundPrimary)
}
