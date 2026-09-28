//
//  RouteLink.swift
//  checkpoint
//
//  Opening a detail from a tab root, in whichever layout the tab is in.
//  `TabColumnsStack` tells its content which column it sits in and hands it an
//  `openRoute` action; rows use `RouteLink` (or call `openRoute` from their
//  own tap) and never need to know the size class.
//
//    compact              regular, list column
//    NavigationLink ›     Button, row highlighted while its detail shows
//    push                 replace the detail column
//

import SwiftUI

/// Opens a route from wherever the calling view sits. See
/// `AppState.path(_:opening:from:on:)` for push vs. replace.
struct OpenRouteAction {
    let handler: @MainActor (AppRoute) -> Void

    @MainActor
    func callAsFunction(_ route: AppRoute) {
        handler(route)
    }
}

extension EnvironmentValues {
    /// The column this view sits in. Set by `TabColumnsStack`.
    @Entry var navigationColumn: NavigationColumn = .stack
    /// The route the detail column is showing, for the list's row highlight.
    @Entry var columnSelection: AppRoute?
    /// Set by `TabColumnsStack`; outside a tab it does nothing.
    @Entry var openRoute = OpenRouteAction { _ in }
}

/// A row that opens `route`: a `NavigationLink` in a stack, a `Button` in a
/// list column (so it replaces the detail rather than pushing into the
/// column). Not `List(selection:)`: Services' edit mode already owns the
/// list's selection.
struct RouteLink<Label: View>: View {
    let route: AppRoute
    @ViewBuilder let label: () -> Label

    @Environment(\.navigationColumn) private var column
    @Environment(\.openRoute) private var openRoute
    @Environment(\.editMode) private var editMode

    init(_ route: AppRoute, @ViewBuilder label: @escaping () -> Label) {
        self.route = route
        self.label = label
    }

    var body: some View {
        if column == .list {
            Button {
                // In edit mode a tap selects the row; it must not open it.
                guard editMode?.wrappedValue.isEditing != true else { return }
                openRoute(route)
            } label: {
                label()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: route, label: label)
        }
    }
}

// MARK: - Row highlight

/// The row background: clear, or — in a list column — the subtle surface
/// while this row's detail is the one showing beside the list.
private struct ColumnRowBackground: ViewModifier {
    let route: AppRoute?

    @Environment(\.navigationColumn) private var column
    @Environment(\.columnSelection) private var selection

    func body(content: Content) -> some View {
        let isShowing = column == .list && route != nil && route == selection
        content
            .listRowBackground(isShowing ? Theme.backgroundSubtle : Color.clear)
            .accessibilityAddTraits(isShowing ? .isSelected : [])
    }
}

extension View {
    /// A list row's background, highlighted while `route` is the detail shown
    /// beside the list. Rows that open nothing pass `nil`.
    func columnRowBackground(for route: AppRoute?) -> some View {
        modifier(ColumnRowBackground(route: route))
    }
}
