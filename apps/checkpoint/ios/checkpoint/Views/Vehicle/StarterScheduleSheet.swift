//
//  StarterScheduleSheet.swift
//  checkpoint
//
//  "Set up a starter schedule?" — offered by the router right after a vehicle
//  is saved. Lists the common services for a car with the catalog's default
//  intervals, all selected, each asking only when it was last done.
//
//  Decision surface. Default path: accept the defaults — Save Vehicle (1),
//  Add (2). Skipping is Cancel. Nothing here is load-bearing but the
//  selection; "Don't know" is a real answer, not a blank (the first reminder
//  counts from today — `StarterSchedule`).
//

import SwiftUI
import SwiftData

struct StarterScheduleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let vehicle: Vehicle

    @State private var items: [StarterScheduleItem] = []
    @State private var initialItems: [StarterScheduleItem] = []
    @State private var showNoneSelected = false

    private var selectedCount: Int {
        items.filter(\.isIncluded).count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text(L10n.vehicleStarterIntro)
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if showNoneSelected, selectedCount == 0 {
                            FormAdvisory.blocking(L10n.vehicleStarterNoneSelected)
                        }

                        VStack(spacing: 0) {
                            ForEach($items) { $item in
                                StarterScheduleRow(item: $item)
                                if item.id != items.last?.id {
                                    ListDivider()
                                }
                            }
                        }
                        .background(Theme.surfaceInstrument)
                        .brutalistBorder()
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .keyboardDismissToolbar()
            .formToolbar(
                title: L10n.vehicleStarterTitle,
                subtitle: vehicle.displayName,
                saveTitle: L10n.vehicleStarterAdd(selectedCount),
                canSave: selectedCount > 0,
                isDirty: items != initialItems,
                onSave: createServices,
                onBlocked: { showNoneSelected = true }
            )
            .onAppear(perform: prepare)
        }
    }

    private func prepare() {
        guard items.isEmpty else { return }
        let existing = (vehicle.services ?? []).map(\.name)
        items = StarterSchedule.items(from: PresetDataService.shared.loadPresets(), excluding: existing)
        initialItems = items
    }

    private func createServices() {
        let plans = StarterSchedule.plans(for: items, currentMileage: vehicle.currentMileage)
        let categories = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.category) })

        for plan in plans {
            let service = Service(
                name: plan.name,
                dueDate: plan.dueDate,
                dueMileage: plan.dueMileage,
                lastPerformed: plan.lastPerformed,
                lastMileage: plan.lastMileage,
                intervalMonths: plan.intervalMonths,
                intervalMiles: plan.intervalMiles,
                isRecurring: true
            )
            service.vehicle = vehicle
            modelContext.insert(service)
            AnalyticsService.shared.capture(.serviceScheduled(
                isPreset: true,
                category: categories[plan.name],
                hasInterval: true
            ))
        }

        ServiceDeleteAction.refreshDerivedSurfaces(for: vehicle)
        HapticService.shared.success()
        ToastService.shared.show(L10n.vehicleStarterToastAdded(plans.count), icon: "clock", style: .success)
        dismiss()
    }
}

// MARK: - Row

/// One service: whether to track it, and when it was last done. The name is
/// the row's primary; the interval and the last-done answer step down.
private struct StarterScheduleRow: View {
    @Binding var item: StarterScheduleItem

    @State private var kind: StarterLastDone.Kind = .unknown
    @State private var date: Date = .now
    @State private var mileage: Int?

    private var kinds: [StarterLastDone.Kind] {
        item.offersMileage ? StarterLastDone.Kind.allCases : [.unknown, .date]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Button {
                item.isIncluded.toggle()
                HapticService.shared.selectionChanged()
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                    Image(systemName: item.isIncluded ? "checkmark.square.fill" : "square")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(item.isIncluded ? Theme.accent : Theme.textTertiary)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.brutalistBodyEmphasis)
                            .foregroundStyle(Theme.textPrimary)

                        if let interval = Formatters.serviceInterval(months: item.intervalMonths, miles: item.intervalMiles) {
                            Text(L10n.formEveryInterval(interval))
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: TouchTarget.minimum)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(item.isIncluded ? [.isSelected, .isButton] : .isButton)

            if item.isIncluded {
                lastDoneControls
            }
        }
        .padding(Spacing.md)
        .onChange(of: kind) { commit() }
        .onChange(of: date) { commit() }
        .onChange(of: mileage) { commit() }
    }

    @ViewBuilder
    private var lastDoneControls: some View {
        Text(L10n.vehicleStarterLastDone.uppercased())
            .font(.brutalistLabel)
            .foregroundStyle(Theme.textTertiary)
            .tracking(1.5)

        InstrumentSegmentedControl(options: kinds, selection: $kind) { kind in
            switch kind {
            case .unknown: return L10n.vehicleStarterLastDoneUnknown
            case .date: return L10n.vehicleStarterLastDoneDate
            case .mileage: return L10n.vehicleStarterLastDoneMileage
            }
        }

        switch kind {
        case .unknown:
            EmptyView()
        case .date:
            InstrumentDatePicker(label: nil, date: $date)
        case .mileage:
            InstrumentNumberField(
                value: $mileage,
                placeholder: L10n.vehicleMileagePlaceholder,
                suffix: DistanceSettings.shared.unit.abbreviation
            )
        }
    }

    /// An empty mileage answer is still "don't know" — it schedules from now.
    private func commit() {
        switch kind {
        case .unknown: item.lastDone = .unknown
        case .date: item.lastDone = .date(date)
        case .mileage: item.lastDone = mileage.map(StarterLastDone.mileage) ?? .unknown
        }
    }
}

#Preview {
    StarterScheduleSheet(vehicle: Vehicle(name: "", make: "Toyota", model: "Camry", year: 2019, currentMileage: 64000))
        .modelContainer(for: [Vehicle.self, Service.self], inMemory: true)
        .preferredColorScheme(.dark)
}
