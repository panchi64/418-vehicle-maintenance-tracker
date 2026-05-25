import SwiftUI

struct ServiceTypePicker: View {
    @Binding var selectedPreset: PresetData?
    @Binding var customServiceName: String
    @State private var showingPicker = false
    @State private var selectedCategory: ServiceCategory = .engine
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let preset = selectedPreset {
                selectedPresetRow(preset)
            } else {
                browseRow

                Text("OR TYPE A CUSTOM SERVICE")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, Spacing.xs)

                TextField("Service name", text: $customServiceName)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                    .focused($isFocused)
                    .padding(Spacing.md)
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
        .sheet(isPresented: $showingPicker) {
            ServicePresetPickerSheet(
                selectedPreset: $selectedPreset,
                selectedCategory: $selectedCategory
            )
        }
    }

    private func selectedPresetRow(_ preset: PresetData) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: 0) {
                Button { showingPicker = true } label: {
                    HStack {
                        Image(systemName: ServiceCategory(rawValue: preset.category)?.icon ?? "wrench.and.screwdriver")
                            .foregroundStyle(Theme.accent)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(preset.name)
                                .foregroundStyle(Theme.textPrimary)
                            if let interval = Formatters.serviceInterval(months: preset.defaultIntervalMonths, miles: preset.defaultIntervalMiles) {
                                Text(interval.uppercased())
                                    .font(.brutalistLabel)
                                    .foregroundStyle(Theme.textSecondary)
                                    .tracking(1)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(Spacing.md)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Change service type. Currently \(preset.name)")

                Divider()
                    .frame(width: Theme.borderWidth)
                    .overlay(Theme.gridLine)

                Button {
                    selectedPreset = nil
                    HapticService.shared.selectionChanged()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 48, height: 48)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear service type")
            }
            .background(Theme.surfaceInstrument)
            .clipShape(Rectangle())
            .brutalistBorder()

            Button {
                selectedPreset = nil
            } label: {
                Text("USE A CUSTOM SERVICE INSTEAD")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Clears the selected preset and lets you type any service name")
        }
    }

    private var browseRow: some View {
        Button { showingPicker = true } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.accent)

                Text("BROWSE ALL PRESETS")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.accent)
                    .tracking(1.5)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Spacing.md)
            .background(Theme.surfaceInstrument)
            .clipShape(Rectangle())
            .brutalistBorder(color: Theme.accent.opacity(0.4))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Browse all service presets")
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
            ZStack {
                AtmosphericBackground()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
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
                            .padding(.horizontal, Spacing.screenHorizontal)
                        }

                        LazyVStack(spacing: Spacing.sm) {
                            ForEach(presetService.presets(for: selectedCategory), id: \.name) { preset in
                                PresetRow(
                                    preset: preset,
                                    icon: selectedCategory.icon,
                                    isSelected: selectedPreset?.name == preset.name
                                ) {
                                    HapticService.shared.selectionChanged()
                                    selectedPreset = preset
                                    dismiss()
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                    }
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("Select Service Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.surfaceInstrument, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .toolbarButtonStyle()
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Preset Row

private struct PresetRow: View {
    let preset: PresetData
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(preset.name)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)

                    if let interval = Formatters.serviceInterval(months: preset.defaultIntervalMonths, miles: preset.defaultIntervalMiles) {
                        Text(interval.uppercased())
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textSecondary)
                            .tracking(1)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Theme.accent)
                }
            }
            .padding(Spacing.md)
            .background(Theme.surfaceInstrument)
            .clipShape(Rectangle())
            .brutalistBorder(color: isSelected ? Theme.accent : Theme.gridLine)
        }
        .buttonStyle(.plain)
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
            .font(.brutalistBody)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? Theme.accent : Theme.backgroundSubtle)
            .foregroundStyle(isSelected ? Theme.backgroundPrimary : Theme.textSecondary)
            .clipShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var selectedPreset: PresetData? = nil
    @Previewable @State var customServiceName = ""

    ZStack {
        Theme.backgroundPrimary
            .ignoresSafeArea()

        VStack(spacing: Spacing.lg) {
            ServiceTypePicker(
                selectedPreset: $selectedPreset,
                customServiceName: $customServiceName
            )

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
