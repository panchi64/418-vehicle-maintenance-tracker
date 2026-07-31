//
//  CostsTab.swift
//  checkpoint
//
//  Costs tab — analytics-style answers to "how is this car doing financially?"
//  The view itself is a thin orchestrator. Sections live in
//  `CostsTab+Sections.swift`; analytics in `CostsTab+Analytics.swift`;
//  derived insights in `CostsTab+Insights.swift`.
//

import SwiftUI
import SwiftData
import Charts

struct CostsTab: View {
    @Environment(AppState.self) var appState
    let onboardingState: OnboardingState
    @Query var serviceLogs: [ServiceLog]

    @State var periodFilter: PeriodFilter = .year
    @State var categoryFilter: CategoryFilter = .all
    @State var highlightedEventID: UUID? = nil

    /// Scopes the log fetch to `vehicle` at the database level. `appState`
    /// arrives through the environment.
    init(vehicle: Vehicle?, onboardingState: OnboardingState) {
        self.onboardingState = onboardingState
        if let vehicleID = vehicle?.id {
            _serviceLogs = Query(filter: #Predicate<ServiceLog> { $0.vehicle?.id == vehicleID })
        } else {
            _serviceLogs = Query(filter: #Predicate<ServiceLog> { _ in false })
        }
    }

    /// Raw values are **storage** — they persist in analytics events and must
    /// stay stable. `displayName` is what reaches the screen (rule 10).
    ///
    /// Note for Phase 3: these labels mix rolling windows (`month` = last 30
    /// days, `year` = last 12 months) with a calendar-anchored one (`ytd` =
    /// since Jan 1), which is genuinely ambiguous to a reader. Relabeling is a
    /// Costs-tab layout decision, so it is deferred rather than changed here.
    enum PeriodFilter: String, CaseIterable {
        case month = "Month"
        case ytd = "YTD"
        case year = "Year"
        case all = "All"

        var displayName: String {
            switch self {
            case .month: return L10n.costsPeriodMonth
            case .ytd: return L10n.costsPeriodYTD
            case .year: return L10n.costsPeriodYear
            case .all: return L10n.costsPeriodAll
            }
        }

        var startDate: Date? {
            let calendar = Calendar.current
            switch self {
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: .now)
            case .ytd:
                return calendar.date(from: calendar.dateComponents([.year], from: .now))
            case .year:
                return calendar.date(byAdding: .year, value: -1, to: .now)
            case .all:
                return nil
            }
        }
    }

    enum CategoryFilter: String, CaseIterable {
        case all = "All"
        case maintenance = "Maint."
        case repair = "Repair"
        case upgrade = "Upgrade"

        /// Defers to `CostCategory.shortDisplayName` rather than carrying its
        /// own copy of the category names — the filter and the category badge
        /// on an expense row must always read the same.
        var displayName: String {
            guard let costCategory else { return L10n.filterAll }
            return costCategory.shortDisplayName
        }

        var costCategory: CostCategory? {
            switch self {
            case .all: return nil
            case .maintenance: return .maintenance
            case .repair: return .repair
            case .upgrade: return .upgrade
            }
        }
    }

    var body: some View {
        // The control row is pinned above the scroll area, so the cards scroll
        // under it rather than pushing the only means of changing them
        // off-screen.
        VStack(spacing: 0) {
            filtersSection

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        summaryCardsSection
                        breakdownSections
                        expenseListSection(scrollProxy: proxy)
                        emptyStates
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.xxl + Spacing.tabBarOffset)
                }
                .onChange(of: highlightedEventID) { _, newID in
                    guard let newID else { return }
                    withAnimation(.easeInOut(duration: Theme.animationMedium)) {
                        proxy.scrollTo(newID, anchor: .center)
                    }
                }
            }
        }
        .trackScreen(.costs)
        .onChange(of: periodFilter) { _, newValue in
            AnalyticsService.shared.capture(.costsPeriodChanged(period: newValue.rawValue))
        }
        .onChange(of: categoryFilter) { _, newValue in
            AnalyticsService.shared.capture(.costsCategoryChanged(category: newValue.rawValue))
        }
    }
}

#Preview {
    let appState = AppState()
    appState.selectedVehicle = Vehicle.sampleVehicle

    return ZStack {
        AtmosphericBackground()
        CostsTab(vehicle: appState.selectedVehicle, onboardingState: OnboardingState())
    }
    .environment(appState)
    .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self], inMemory: true)
    .preferredColorScheme(.dark)
}
