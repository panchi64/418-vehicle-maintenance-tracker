//
//  ServicesTabState.swift
//  checkpoint
//
//  Services tab filter, search, and view mode state
//

import Foundation

struct ServicesTabState {
    var searchText = ""
    var statusFilter: StatusFilter = .all
    var viewMode: ViewMode = .list

    /// Raw values are **storage** — they persist in analytics events and must
    /// stay stable. `displayName` is what reaches the screen (rule 10).
    enum StatusFilter: String, CaseIterable {
        case all = "All"
        case overdue = "Overdue"
        case dueSoon = "Due Soon"
        case good = "Good"

        /// Reuses `ServiceStatus.label` for the three status cases so a filter
        /// chip and the row it filters can never disagree on wording.
        var displayName: String {
            switch self {
            case .all: return L10n.filterAll
            case .overdue: return ServiceStatus.overdue.label
            case .dueSoon: return ServiceStatus.dueSoon.label
            case .good: return ServiceStatus.good.label
            }
        }

        /// The status this filter selects, or nil for `all`.
        var serviceStatus: ServiceStatus? {
            switch self {
            case .all: return nil
            case .overdue: return .overdue
            case .dueSoon: return .dueSoon
            case .good: return .good
            }
        }
    }

    /// `documents` is deliberately absent. It was a third view mode that then
    /// offered "OPEN LIBRARY" to leave for the real documents screen — a content
    /// type masquerading as a view of services. The library is now a destination
    /// reachable from the bottom of the tab, which is what it always was.
    enum ViewMode: String, CaseIterable {
        case list = "List"
        case timeline = "Timeline"

        var displayName: String {
            switch self {
            case .list: return L10n.servicesViewList
            case .timeline: return L10n.servicesViewTimeline
            }
        }
    }
}
