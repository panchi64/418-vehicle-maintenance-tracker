import Foundation

/// One source's reading for the crisis check (PRODUCT.md §8).
nonisolated enum SourceReading<Value: Hashable & Sendable>: Hashable, Sendable {
    /// Biombo doesn't have this source (LUMA before permission): it is left
    /// out of every check.
    case unavailable
    /// The source was live and went quiet. It never counts as "all clear".
    case lost
    case live(Value)
}

/// What the backend reads from every source at one moment.
nonisolated struct CrisisReadings: Hashable, Sendable {
    /// An NWS Hurricane or Tropical Storm Warning for any PR zone.
    var nwsWarning: SourceReading<Bool> = .unavailable
    /// LUMA's island share of customers out, 0...1.
    var lumaOutShare: SourceReading<Double> = .unavailable
    var dirsActive: SourceReading<Bool> = .unavailable
    /// Share of municipios with a community power area opened in the last 2 h, 0...1.
    var communityPowerShare: SourceReading<Double> = .unavailable
    /// An authority (NMEAD) or staff declaration, with the municipios it names
    /// (empty for island-wide); nil when nothing is declared.
    var declaration: [String]?
}

/// When crisis mode turns on and off (§8). Every number is *proposed* and
/// lives only here. Pure: the caller passes the previous state and `now`.
nonisolated struct CrisisRules: Sendable {
    /// LUMA customers out that turns the mode on…
    var lumaOnShare = 0.10
    /// …once it has held this long.
    var lumaHold: TimeInterval = .minutes(30)
    /// Community power areas across this share of municipios turn it on.
    var communityOnShare = 0.15
    /// Below this share (LUMA and community alike) counts as clear.
    var clearShare = 0.05
    /// Every automatic trigger must stay clear this long before the mode ends.
    var clearHold: TimeInterval = .hours(6)

    /// The next state from the previous one and the current readings.
    func step(_ state: CrisisState, readings: CrisisReadings, now: Date) -> CrisisState {
        var next = state
        if case .live(let share) = readings.lumaOutShare, share >= lumaOnShare {
            next.lumaAboveSince = state.lumaAboveSince ?? now
        } else {
            next.lumaAboveSince = nil
        }

        let firing = firingTriggers(readings, lumaAboveSince: next.lumaAboveSince, now: now)
        if !firing.isEmpty {
            next.triggers = firing
            next.since = state.isActive ? state.since : now
            next.municipios = readings.declaration ?? []
            next.clearSince = nil
            return next
        }
        guard state.isActive else { return next }

        // A withdrawn declaration ends only itself; automatic triggers still wait out the hold.
        next.triggers = state.triggers.filter { $0 != .declaration }
        next.municipios = []
        guard !next.triggers.isEmpty else { return ended(next) }
        guard isAllClear(readings) else {
            next.clearSince = nil
            return next
        }
        let clearSince = state.clearSince ?? now
        if now.timeIntervalSince(clearSince) >= clearHold {
            return ended(next)
        }
        next.clearSince = clearSince
        return next
    }

    /// The end is announced once, in one sentence (§8): true only on the step that ends it.
    static func didEnd(from previous: CrisisState, to next: CrisisState) -> Bool {
        previous.isActive && !next.isActive
    }

    // MARK: - Rules

    private func firingTriggers(_ readings: CrisisReadings, lumaAboveSince: Date?, now: Date) -> [CrisisState.Trigger] {
        var triggers: [CrisisState.Trigger] = []
        if readings.nwsWarning == .live(true) { triggers.append(.nwsWarning) }
        if let since = lumaAboveSince, now.timeIntervalSince(since) >= lumaHold { triggers.append(.lumaCustomersOut) }
        if readings.dirsActive == .live(true) { triggers.append(.dirsActivated) }
        if case .live(let share) = readings.communityPowerShare, share >= communityOnShare { triggers.append(.communityPowerAreas) }
        if readings.declaration != nil { triggers.append(.declaration) }
        return triggers
    }

    /// Clear means every source Biombo has is live and calm. A source that
    /// was live and then lost never counts as clear.
    private func isAllClear(_ readings: CrisisReadings) -> Bool {
        isClear(readings.nwsWarning) && isClear(readings.dirsActive)
            && isClear(readings.lumaOutShare) && isClear(readings.communityPowerShare)
    }

    private func isClear(_ reading: SourceReading<Bool>) -> Bool {
        switch reading {
        case .unavailable: true
        case .lost: false
        case .live(let on): !on
        }
    }

    private func isClear(_ reading: SourceReading<Double>) -> Bool {
        switch reading {
        case .unavailable: true
        case .lost: false
        case .live(let share): share < clearShare
        }
    }

    private func ended(_ state: CrisisState) -> CrisisState {
        var ordinary = CrisisState.ordinary
        ordinary.lumaAboveSince = state.lumaAboveSince
        return ordinary
    }
}
