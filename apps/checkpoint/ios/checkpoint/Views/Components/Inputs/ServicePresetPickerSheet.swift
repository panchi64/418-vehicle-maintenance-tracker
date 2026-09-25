//
//  ServicePresetPickerSheet.swift
//  checkpoint
//
//  "Browse all services" — every preset, grouped by category, searchable.
//
//  Was a category chip strip over one category's presets at a time: finding
//  "Cabin air filter" meant guessing which of eight chips held it, and the
//  chips printed the category's storage `rawValue`. Now it is one list with
//  the system search field, and category names come from `displayName`.
//
//  Choosing is the only action: the sheet has no "clear" of its own. The
//  form's collapsed row owns the single way to undo a choice (Change).
//

import SwiftUI

struct ServicePresetPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// The service currently chosen in the form, checked in the list.
    var selectedName: String?
    let onSelect: (PresetData) -> Void

    @State private var query = ""

    private var groups: [(category: ServiceCategory, presets: [PresetData])] {
        let presetService = PresetDataService.shared
        let needle = query.trimmingCharacters(in: .whitespaces)
        return presetService.availableCategories().compactMap { category in
            let presets = presetService.presets(for: category).filter {
                needle.isEmpty || $0.name.localizedCaseInsensitiveContains(needle)
            }
            return presets.isEmpty ? nil : (category, presets)
        }
    }

    var body: some View {
        NavigationStack {
            let groups = groups
            List {
                ForEach(groups, id: \.category) { group in
                    Section {
                        ForEach(group.presets, id: \.name) { preset in
                            row(preset)
                        }
                    } header: {
                        Label(group.category.displayName, systemImage: group.category.icon)
                            .font(.brutalistSectionTitle)
                            .foregroundStyle(Theme.textPrimary)
                            .textCase(nil)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundPrimary)
            .overlay {
                if groups.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle(L10n.formBrowseAll)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func row(_ preset: PresetData) -> some View {
        let isSelected = selectedName?.caseInsensitiveCompare(preset.name) == .orderedSame
        return Button {
            HapticService.shared.selectionChanged()
            onSelect(preset)
            dismiss()
        } label: {
            HStack(spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name)
                        .font(.brutalistBodyEmphasis)
                        .foregroundStyle(Theme.textPrimary)

                    if let interval = Formatters.serviceInterval(
                        months: preset.defaultIntervalMonths,
                        miles: preset.defaultIntervalMiles
                    ) {
                        Text(L10n.formEveryInterval(interval))
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: TouchTarget.minimum)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension ServiceCategory {
    /// Localized name. `rawValue` is storage and never reaches the screen.
    var displayName: String {
        switch self {
        case .engine: return L10n.formCategoryEngine
        case .tires: return L10n.formCategoryTires
        case .brakes: return L10n.formCategoryBrakes
        case .transmission: return L10n.formCategoryTransmission
        case .fluids: return L10n.formCategoryFluids
        case .electrical: return L10n.formCategoryElectrical
        case .body: return L10n.formCategoryBody
        case .other: return L10n.formCategoryOther
        }
    }
}

#Preview {
    ServicePresetPickerSheet(selectedName: "Oil Change") { _ in }
}
