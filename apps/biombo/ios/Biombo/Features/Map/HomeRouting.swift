/// What a Control, a widget, an App Intent or onboarding opens on home
/// (`AppRoute`): Quick Report, a one-tap report with Deshacer, the watch
/// list, or the search for a place to watch.
struct HomeRouting {
    let store: HomeStore
    let reporting: HomeReporting

    func open(_ route: AppRoute) {
        switch route {
        case .report: reporting.reportHere()
        case .quickReport(let kind): reporting.quickReport(kind)
        case .watchList: store.openWatchList()
        case .watchAnother: store.watchAnother()
        }
    }
}
