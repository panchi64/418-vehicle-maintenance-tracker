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

    enum StatusFilter: String, CaseIterable {
        case all = "All"
        case overdue = "Overdue"
        case dueSoon = "Due Soon"
        case good = "Good"
    }

    enum ViewMode: String, CaseIterable {
        case list = "List"
        case timeline = "Timeline"
    }
}
