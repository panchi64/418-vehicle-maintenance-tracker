//
//  ServiceTypePicker.swift
//  checkpoint
//
//  Component for selecting service presets when adding/editing services
//

import SwiftUI

struct ServiceTypePicker: View {
    @Binding var selectedPreset: PresetData?
    @Binding var customServiceName: String
    @State private var showingPicker = false
    @State private var selectedCategory: ServiceCategory = .engine

    private let presetService = PresetDataService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Show selected preset or custom input
            if let preset = selectedPreset {
                // Selected preset display
                Button {
                    showingPicker = true
                } label: {
                    HStack {
                        Image(systemName: ServiceCategory(rawValue: preset.category)?.icon ?? "wrench.and.screwdriver")
                            .foregroundStyle(Theme.accent)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(preset.name)
                                .foregroundStyle(Theme.textPrimary)
                            if let interval = formatInterval(preset) {
                                Text(interval)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(Spacing.md)
                    .background(Theme.backgroundElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Theme.borderSubtle, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            } else {
                // No selection - show button to pick or custom field
                VStack(spacing: Spacing.sm) {
                    TextField("Service name", text: $customServiceName)
                        .padding(Spacing.md)
                        .background(Theme.backgroundElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Theme.borderSubtle, lineWidth: 1)
                        )

                    Button {
                        showingPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("Browse Presets")
                        }
                        .font(.subheadline)
                        .foregroundStyle(Theme.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showingPicker) {
            ServicePresetPickerSheet(
                selectedPreset: $selectedPreset,
                selectedCategory: $selectedCategory
            )
        }
    }

    private func formatInterval(_ preset: PresetData) -> String? {
        var parts: [String] = []
        if let months = preset.defaultIntervalMonths {
            parts.append("\(months) mo")
        }
        if let miles = preset.defaultIntervalMiles {
            let formatted = NumberFormatter.localizedString(from: NSNumber(value: miles), number: .decimal)
            parts.append("\(formatted) mi")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " / ")
    }
}

// MARK: - Preset Picker Sheet

struct ServicePresetPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPreset: PresetData?
    @Binding var selectedCategory: ServiceCategory

    private let presetService = PresetDataService.shared

    var body: some View {
        NavigationStack {
            List {
                // Category filter tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(presetService.availableCategories(), id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                // Presets for selected category
                Section {
                    ForEach(presetService.presets(for: selectedCategory), id: \.name) { preset in
                        Button {
                            selectedPreset = preset
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: selectedCategory.icon)
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text(preset.name)
                                        .foregroundStyle(Theme.textPrimary)

                                    if let interval = formatInterval(preset) {
                                        Text(interval)
                                            .font(.caption)
                                            .foregroundStyle(Theme.textSecondary)
                                    }
                                }

                                Spacer()

                                if selectedPreset?.name == preset.name {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.accent)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Service Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func formatInterval(_ preset: PresetData) -> String? {
        var parts: [String] = []
        if let months = preset.defaultIntervalMonths {
            parts.append("\(months) mo")
        }
        if let miles = preset.defaultIntervalMiles {
            let formatted = NumberFormatter.localizedString(from: NSNumber(value: miles), number: .decimal)
            parts.append("\(formatted) mi")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " / ")
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: ServiceCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: category.icon)
                    .font(.system(size: 12))
                Text(category.rawValue)
            }
            .font(.subheadline)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? Theme.accent : Theme.backgroundSubtle)
            .foregroundStyle(isSelected ? Color(red: 0.071, green: 0.071, blue: 0.071) : Theme.textSecondary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedPreset: PresetData? = nil
    @Previewable @State var customServiceName = ""

    ZStack {
        Theme.backgroundPrimary
            .ignoresSafeArea()

        VStack(spacing: Spacing.lg) {
            // No selection state
            ServiceTypePicker(
                selectedPreset: $selectedPreset,
                customServiceName: $customServiceName
            )

            // With selection state
            ServiceTypePicker(
                selectedPreset: .constant(PresetData(
                    name: "Oil Change",
                    category: "Engine",
                    defaultIntervalMonths: 6,
                    defaultIntervalMiles: 5000
                )),
                customServiceName: .constant("")
            )
        }
        .screenPadding()
    }
}
