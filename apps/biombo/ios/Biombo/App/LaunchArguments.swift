import Foundation

/// Launch arguments the sample build reads.
nonisolated enum LaunchArguments {
    /// `-vantage 18.3755,-66.1190`: where "cerca" is measured from.
    static func vantage(in arguments: [String]) -> GeoPoint? {
        guard let flag = arguments.firstIndex(of: "-vantage"), arguments.indices.contains(flag + 1) else { return nil }
        let parts = arguments[flag + 1].split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 2, (-90...90).contains(parts[0]), (-180...180).contains(parts[1]) else { return nil }
        return GeoPoint(parts[0], parts[1])
    }

    /// `-skipOnboarding` marks the first run done; `-onboarding` replays it.
    static func applyOnboarding(_ arguments: [String], to defaults: UserDefaults) {
        if arguments.contains("-skipOnboarding") { defaults.set(true, forKey: Preferences.hasOnboarded) }
        if arguments.contains("-onboarding") { defaults.set(false, forKey: Preferences.hasOnboarded) }
    }

    /// `-offline` or `-weakSignal`: start with that connection.
    static func connection(in arguments: [String]) -> ConnectionStatus {
        if arguments.contains("-offline") { return .offline }
        if arguments.contains("-weakSignal") { return .weak }
        return .online
    }
}
