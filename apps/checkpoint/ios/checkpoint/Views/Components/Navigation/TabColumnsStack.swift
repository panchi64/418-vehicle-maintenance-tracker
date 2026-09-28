//
//  TabColumnsStack.swift
//  checkpoint
//
//  One tab's navigation: a stack at compact width, list | detail columns at
//  regular width (iPad, the Duo's inner display) for the tabs that are lists.
//
//    compact / Home            regular, Services + Costs
//    ┌──────────────┐          ┌──────────┬───────────────────┐
//    │ root › a › b │          │ root     │ a › b             │
//    └──────────────┘          │ (334pt)  │ (first: no back)  │
//                              └──────────┴───────────────────┘
//
//  Both read and write the same `AppState.paths[tab]`, so folding or unfolding
//  (the size class flips at runtime) keeps what was open, and switching
//  vehicles, notification routes and `showDetail` behave identically in each.
//  At regular width the detail column is a stack over the WHOLE path with an
//  empty-state root, the first route's back button hidden. Rooting it at the
//  first route instead would leave that screen unable to `dismiss()` itself
//  (its Delete and Mark Done pop the screen), because a stack's root has
//  nothing to pop to.
//
//  Beside a list, Settings and the vehicle menu stay on the list column and
//  Select + [+] (`TabRootActions`) end the detail column's bar: the iPad's
//  floating tab bar covers the list column's trailing edge.
//

import SwiftUI
import SwiftData

struct TabColumnsStack<Root: View>: View {
    let tab: Tab
    let vehicles: [Vehicle]
    @ViewBuilder let root: () -> Root

    @Environment(AppState.self) private var appState
    @Environment(\.horizontalSizeClass) private var sizeClass

    /// The list column's width. Half the Duo's inner display (669pt), so the
    /// divider lands on the fold (sketchpad `LIST_COLUMN_WIDTH`).
    static var listColumnWidth: CGFloat { 334 }

    /// Whether `tab` shows as list | detail columns at `sizeClass`. Home is a
    /// dashboard, not a list, so it stays one stack.
    static func usesColumns(for tab: Tab, in sizeClass: UserInterfaceSizeClass?) -> Bool {
        sizeClass == .regular && tab != .home
    }

    private var path: Binding<[AppRoute]> {
        Binding(
            get: { appState.paths[tab] ?? [] },
            set: { appState.paths[tab] = $0 }
        )
    }

    var body: some View {
        if Self.usesColumns(for: tab, in: sizeClass) {
            columns
        } else {
            stack
        }
    }

    // MARK: - Compact

    private var stack: some View {
        NavigationStack(path: path) {
            root()
                .tabRootChrome(tab, vehicles: vehicles)
                .navigationDestination(for: AppRoute.self) { route in
                    AppRouteDestination(route: route)
                }
        }
        .environment(\.navigationColumn, .stack)
        .environment(\.openRoute, openRoute(from: .stack))
    }

    // MARK: - Regular

    private var columns: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            root()
                .tabRootChrome(tab, vehicles: vehicles, includesActions: false)
                .navigationSplitViewColumnWidth(Self.listColumnWidth)
                // The list is the tab; collapsing it would leave a detail
                // with no way back to its siblings.
                .toolbar(removing: .sidebarToggle)
                .environment(\.navigationColumn, .list)
                .environment(\.columnSelection, appState.paths[tab]?.first)
                .environment(\.openRoute, openRoute(from: .list))
        } detail: {
            NavigationStack(path: path) {
                placeholder
                    .toolbar { TabRootActions(tab: tab, appState: appState) }
                    .navigationDestination(for: AppRoute.self) { route in
                        AppRouteDestination(route: route)
                            // The column's first screen replaces, never
                            // stacks: there is nothing behind it to go back to.
                            .navigationBarBackButtonHidden(route == appState.paths[tab]?.first)
                            .toolbar {
                                // A library has its own Select and add; two
                                // of each in one bar reads as a bug.
                                if !route.isLibrary {
                                    TabRootActions(tab: tab, appState: appState)
                                }
                            }
                    }
            }
            .environment(\.navigationColumn, .detail)
            .environment(\.openRoute, openRoute(from: .detail))
        }
        .navigationSplitViewStyle(.balanced)
        // A row deleted from the list (swipe, Select) takes its detail with it.
        .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave)) { _ in
            let path = appState.paths[tab] ?? []
            let kept = path.prefixBeforeGone()
            if kept.count != path.count {
                appState.paths[tab] = kept
            }
        }
    }

    private var placeholder: some View {
        ContentUnavailableView(
            L10n.columnsPlaceholderTitle(tab),
            systemImage: tab.icon,
            description: Text(L10n.columnsPlaceholderMessage(tab))
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { AtmosphericBackground() }
    }

    // MARK: - Opening routes

    private func openRoute(from column: NavigationColumn) -> OpenRouteAction {
        OpenRouteAction { [appState, tab] route in
            // Swapping the detail beside the list is a selection change, not
            // a push: it doesn't slide.
            var transaction = Transaction()
            transaction.disablesAnimations = column == .list
            withTransaction(transaction) {
                appState.open(route, from: column, on: tab)
            }
        }
    }
}
