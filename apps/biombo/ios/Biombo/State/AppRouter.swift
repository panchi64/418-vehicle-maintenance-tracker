import Observation

/// Where something outside home asked the app to go: a Control, a widget,
/// an App Intent or onboarding's "Vigilar un lugar". Home is its one
/// consumer. Pure state: the app moves a Control's pending screen in here,
/// and home takes it.
@Observable
final class AppRouter {
    private(set) var pending: AppRoute?

    func open(_ route: AppRoute) {
        pending = route
    }

    /// Removes and returns what is waiting, so a route opens once.
    func take() -> AppRoute? {
        defer { pending = nil }
        return pending
    }

    /// Drops what is waiting unopened.
    func discard() {
        pending = nil
    }
}

enum AppRoute: Hashable {
    /// Quick Report, about where you stand.
    case report
    /// One tap about where you stand, with Deshacer (a Control).
    case quickReport(ReportKind)
    case watchList
    /// "Vigilar un lugar": a search whose result opens watch setup.
    case watchAnother

    init(_ screen: BiomboScreen) {
        switch screen {
        case .report: self = .report
        case .noPower: self = .quickReport(.noPower)
        case .powerBack: self = .quickReport(.powerBack)
        case .watchList: self = .watchList
        }
    }
}
