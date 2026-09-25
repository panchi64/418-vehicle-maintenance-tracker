//
//  CostsTab.swift
//  checkpoint
//
//  Costs — a Readout. "How much is this car costing me, and is that changing?"
//
//  Fixed order (tools/sketchpad/src/screens/CostsTab.tsx):
//
//    [ 30D | YTD | 12M | All ]   the one control; scopes every number below
//    Year to Date                hero: the period total
//      $330 a month on average   the secondary figure
//    Per Month, USD  Trend·Category   ONE chart section, with a written summary
//    2026 vs 2025                one comparison row, same calendar span
//    July 2026        $730.40    expenses by month; rows push their detail
//
//  Sparse data never renders a card of absence: the hero always renders, and
//  the chart and comparison each collapse to one `InsufficientDataNote`.
//
//  The view is a thin orchestrator. Period/chart state lives in
//  `CostsTab+Period.swift`, sections in `CostsTab+Sections.swift`, numbers in
//  `CostsTab+Analytics.swift`, and their wording in `CostsTab+Insights.swift`.
//

import SwiftUI
import SwiftData

struct CostsTab: View {
    @Environment(AppState.self) var appState
    let onboardingState: OnboardingState
    @Query var serviceLogs: [ServiceLog]

    @State var periodFilter: PeriodFilter = .yearToDate
    @State var chartMode: ChartMode = .trend

    /// Scopes the log fetch to `vehicle` at the database level and lets the store
    /// return them newest-first. `appState` arrives through the environment.
    ///
    /// Nothing downstream re-filters by vehicle: the predicate already did it,
    /// and re-checking `$0.vehicle?.id` faults the relationship once per log.
    init(vehicle: Vehicle?, onboardingState: OnboardingState) {
        self.onboardingState = onboardingState
        if let vehicleID = vehicle?.id {
            _serviceLogs = Query(
                filter: #Predicate<ServiceLog> { $0.vehicle?.id == vehicleID },
                sort: \.performedDate,
                order: .reverse
            )
        } else {
            _serviceLogs = Query(filter: #Predicate<ServiceLog> { _ in false })
        }
    }

    var vehicle: Vehicle? {
        appState.selectedVehicle
    }

    var body: some View {
        // Derived once per body evaluation and handed to every section.
        let metrics = CostsMetrics(logs: serviceLogs, period: periodFilter)

        Group {
            if vehicle == nil {
                ContentUnavailableView(
                    L10n.emptyNoVehicleTitle,
                    systemImage: "car.side",
                    description: Text(L10n.emptyNoVehicleMessage)
                )
            } else if !metrics.hasAnyExpense {
                ContentUnavailableView(
                    metrics.hasAnyLog ? L10n.costsEmptyStartTitle : L10n.costsEmptyNoneTitle,
                    systemImage: "dollarsign.circle",
                    description: Text(metrics.hasAnyLog ? L10n.costsEmptyStartMessage : L10n.costsEmptyNoneMessage)
                )
            } else {
                // A system List so expense rows get swipe actions and a context
                // menu. Nothing in it drags sideways except those rows — the
                // chart row carries no swipe action, so its scrub never fights
                // one.
                List {
                    Group {
                        periodPicker
                        heroSection(metrics)
                        chartSection(metrics)
                        comparisonSection(metrics)
                    }
                    .costsListRow()

                    expenseSections(metrics)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .trackScreen(.costs)
        .onChange(of: periodFilter) { _, newValue in
            AnalyticsService.shared.capture(.costsPeriodChanged(period: newValue.rawValue))
        }
    }
}

#Preview {
    let appState = AppState()
    appState.selectedVehicle = Vehicle.sampleVehicle

    return NavigationStack {
        CostsTab(vehicle: appState.selectedVehicle, onboardingState: OnboardingState())
            .background { AtmosphericBackground() }
    }
    .environment(appState)
    .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self], inMemory: true)
}
