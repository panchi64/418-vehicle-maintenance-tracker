//
//  NavigationColumn.swift
//  checkpoint
//
//  Which navigation surface a view sits in, and what opening a route from it
//  does to the tab's path. `AppState.paths[tab]` stays the only navigation
//  state in both layouts; at regular width the list column shows the tab's
//  root and the detail column shows the path, so a size-class flip (folding
//  the Duo) re-renders the same array rather than translating between two.
//
//    compact (stack)     root › a › b            open(x) → [a, b, x]
//    regular (list)      root │ a › b            open(x) → [x]
//    regular (detail)    root │ a › b            open(x) → [a, b, x]
//

import Foundation

enum NavigationColumn: Hashable {
    /// A single NavigationStack: compact width, or a tab with no split view.
    case stack
    /// A split view's list column: the tab root beside the detail.
    case list
    /// A split view's detail column.
    case detail
}

extension AppState {
    /// The path after opening `route` from `column` of `tab`. From the list
    /// column, a route the list links to replaces the detail — tapping another
    /// row swaps the screen beside the list instead of stacking behind it.
    /// Everywhere else it pushes, as it always has.
    static func path(
        _ path: [AppRoute],
        opening route: AppRoute,
        from column: NavigationColumn,
        on tab: Tab
    ) -> [AppRoute] {
        if column == .list && route.isColumnRoot(for: tab) {
            return [route]
        }
        return path + [route]
    }

    /// Open `route` on `tab` from `column`. See `path(_:opening:from:on:)`.
    func open(_ route: AppRoute, from column: NavigationColumn, on tab: Tab) {
        paths[tab] = Self.path(paths[tab] ?? [], opening: route, from: column, on: tab)
    }
}
