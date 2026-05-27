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
    @Bindable var appState: AppState
    let onboardingState: OnboardingState
    @Query var serviceLogs: [ServiceLog]

    @State var periodFilter: PeriodFilter = .year
    @State var categoryFilter: CategoryFilter = .all
    @State var highlightedEventID: UUID?

    enum PeriodFilter: String, CaseIterable {
        case month = "Month"
        case ytd = "YTD"
        case year = "Year"
        case all = "All"

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
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    filtersSection
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
        CostsTab(appState: appState, onboardingState: OnboardingState())
    }
    .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self], inMemory: true)
    .preferredColorScheme(.dark)
}
