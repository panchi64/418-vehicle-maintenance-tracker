//
//  ServicesTabState.swift
//  checkpoint
//
//  Services tab search and selection state.
//
//  There is no view mode and no status filter any more. The tab is one list —
//  status groups, then history by month — so grouping by status gives for free
//  what the filter re-derived, and the timeline mode only re-drew the history
//  the list now carries.
//

import Foundation

struct ServicesTabState {
    var searchText = ""

    /// Edit mode, entered from the toolbar's Select. Lives here rather than in
    /// the tab so the shared toolbar (`TabRootStack`) can toggle it.
    var isSelecting = false
    var selection: Set<ServicesSelectionID> = []

    /// Whether the list has anything to select. Select is hidden otherwise.
    var hasSelectableContent = false

    mutating func setSelecting(_ selecting: Bool) {
        isSelecting = selecting
        selection = []
    }
}

/// A row the user can select in edit mode. The list mixes schedules and
/// history, so a selection has to say which it is.
enum ServicesSelectionID: Hashable {
    case service(UUID)
    case log(UUID)
}
