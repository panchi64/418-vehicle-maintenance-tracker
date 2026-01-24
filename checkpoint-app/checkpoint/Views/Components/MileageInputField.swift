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
                .font(.bodyText)
                .foregroundStyle(Theme.textPrimary)
                .onChange(of: textValue) { _, newValue in
                    // Strip non-numeric characters and update binding
                    let numericOnly = newValue.filter { $0.isNumber }
                    if let intValue = Int(numericOnly), intValue > 0 {
                        value = intValue
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
                    .font(.bodyText)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .onAppear {
            if let val = value {
                textValue = formatMileage(val)
            }
        }
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
                .font(.bodySecondary)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 80, alignment: .leading)

            MileageInputField(value: .constant(nil))
                .padding(Spacing.md)
                .background(Theme.backgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }

        // With value
        HStack {
            Text("With value:")
                .font(.bodySecondary)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 80, alignment: .leading)

            MileageInputField(value: .constant(32500))
                .padding(Spacing.md)
                .background(Theme.backgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }

        // Large number
        HStack {
            Text("Large:")
                .font(.bodySecondary)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 80, alignment: .leading)

            MileageInputField(value: .constant(1234567))
                .padding(Spacing.md)
                .background(Theme.backgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }

        // Custom suffix
        HStack {
            Text("Custom:")
                .font(.bodySecondary)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 80, alignment: .leading)

            MileageInputField(value: .constant(150000), suffix: "km")
                .padding(Spacing.md)
                .background(Theme.backgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }

        // No suffix
        HStack {
            Text("No suffix:")
                .font(.bodySecondary)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 80, alignment: .leading)

            MileageInputField(value: .constant(75000), suffix: "")
                .padding(Spacing.md)
                .background(Theme.backgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    .padding(Spacing.xl)
    .background(Theme.backgroundPrimary)
}

#Preview("Interactive") {
    @Previewable @State var mileage: Int? = 32500

    VStack(spacing: Spacing.lg) {
        Text("Current value: \(mileage.map(String.init) ?? "nil")")
            .font(.headline)
            .foregroundStyle(Theme.textPrimary)

        MileageInputField(value: $mileage)
            .padding(Spacing.md)
            .background(Theme.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

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
