import Foundation

/// The sheet detents are the disclosure tiers (PRODUCT.md §3).
nonisolated enum DisclosureTier: Hashable, Sendable {
    /// The answer, Reportar and Capas.
    case peek
    /// The answer and at most 3 rows per section.
    case summary
    /// At most 5 rows per section.
    case full

    /// Rows a section shows before "Ver todas (N)". Crisis caps every tier at 3 (§8).
    func rowCap(isCrisis: Bool) -> Int {
        switch self {
        case .peek: 0
        case .summary: 3
        case .full: isCrisis ? 3 : 5
        }
    }

    /// Sections shown, so the summary reads as a few chunks (§3, N9).
    var sectionCap: Int {
        switch self {
        case .peek: 0
        case .summary: 3
        case .full: .max
        }
    }
}

/// A row's subject: a place's answer or an outage area.
nonisolated enum NearbyItem: Identifiable, Hashable, Sendable {
    case place(PlaceAnswer)
    case area(AreaStatus)

    var id: String {
        switch self {
        case .place(let answer): answer.id
        case .area(let status): status.id
        }
    }

    var layer: Layer {
        switch self {
        case .place(let answer): answer.layer
        case .area(let status): status.layer
        }
    }

    var anchor: GeoPoint {
        switch self {
        case .place(let answer): answer.anchor
        case .area(let status): status.anchor
        }
    }

    /// Stations, chargers and businesses read as places; roads and utility
    /// events read as sentences (§3 "Two row grammars").
    var grammar: NearbySection.Grammar {
        switch self {
        case .area: .event
        case .place(let answer): answer.layer.readsAsPlace ? .place : .event
        }
    }

    /// Flood items always carry "No cruces carreteras inundadas." (§6.6).
    var isFlood: Bool {
        if case .place(let answer) = self { answer.kind == .flooded } else { false }
    }
}

nonisolated struct NearbyRow: Identifiable, Hashable, Sendable {
    let item: NearbyItem
    /// Metres from where "cerca" is measured.
    let distance: Double

    var id: String { item.id }
    var layer: Layer { item.layer }
    var anchor: GeoPoint { item.anchor }
}

/// One section of "Cerca de ti", named for the user's question (§3).
nonisolated struct NearbySection: Identifiable, Hashable, Sendable {
    nonisolated enum Kind: String, CaseIterable, Hashable, Sendable {
        /// "Más baratas cerca": place rows sorted by price.
        case cheapestGas
        /// "Luz, agua y señal": outage areas and utility events.
        case services
        /// "En la carretera": road events.
        case roads
        /// "Cargadores cerca": place rows, working first.
        case chargers
        /// "Abiertos ahora": place rows.
        case openNow
    }

    /// The two row grammars, never mixed in one section (§3).
    nonisolated enum Grammar: Hashable, Sendable {
        case place
        case event
    }

    let kind: Kind
    /// Current rows, sorted by the section's question.
    let rows: [NearbyRow]
    /// Behind "Ver reportes anteriores (N)", newest first.
    let staleRows: [NearbyRow]

    var id: Kind { kind }

    var grammar: Grammar {
        switch kind {
        case .cheapestGas, .chargers, .openNow: .place
        case .services, .roads: .event
        }
    }

    func shownRows(cap: Int) -> ArraySlice<NearbyRow> { rows.prefix(cap) }

    /// The N in "Ver todas (N)", or 0 when every row shows.
    func overflowCount(cap: Int) -> Int { rows.count > cap ? rows.count : 0 }
}

/// A fact the area's answer sentence states, in priority order.
nonisolated enum AnswerFact: Hashable, Sendable {
    /// Crisis: the official warning, in the agency's own sentence (§8).
    case warning(OfficialNotice)
    /// Crisis: "La gasolina más cerca está en Puma, a 0.8 km."
    case nearestFuel(PlaceAnswer, distance: Double)
    /// "Bairoa sigue sin luz desde las 3:10 p. m."
    case outage(AreaStatus)
    /// "Inundada la PR-52, km 14."
    case road(PlaceAnswer)
    /// "Gasolina desde $0.97/L cerca."
    case cheapestGas(PlaceAnswer)
    /// "No hay reportes recientes cerca." The answer is empty, not old (§3.2).
    case quiet
}

/// Official items grouped as one card per agency (§3).
nonisolated struct AgencyNotices: Identifiable, Hashable, Sendable {
    let agency: Agency
    /// Actionable notices first, then newest.
    let notices: [OfficialNotice]

    var id: Agency { agency }
    var latestUpdate: Date { notices.map(\.updatedAt).max() ?? .distantPast }
}

/// Today's DACO references for one grade, lowest to highest (§6.1).
nonisolated struct DacoRange: Hashable, Sendable {
    let grade: FuelGrade
    /// ¢/L.
    let cents: ClosedRange<Double>

    var low: FuelPrice { FuelPrice(grade: grade, centsPerLitre: cents.lowerBound) }
    var high: FuelPrice { FuelPrice(grade: grade, centsPerLitre: cents.upperBound) }

    init(grade: FuelGrade, cents: ClosedRange<Double>) {
        self.grade = grade
        self.cents = cents
    }

    /// The island range across brands from the current references; nil when none is current.
    init?(_ references: [DacoReference], grade: FuelGrade, now: Date) {
        let current = references
            .filter { $0.price.grade == grade && $0.isCurrent(at: now) }
            .map(\.price.centsPerLitre)
        guard let low = current.min(), let high = current.max() else { return nil }
        self.init(grade: grade, cents: low...high)
    }
}

/// Everything "Cerca de ti" says, derived once per snapshot and visible-layer set.
nonisolated struct NearbyDigest: Hashable, Sendable {
    /// The municipio people call the area ("Guaynabo").
    let areaName: String
    /// Picks the area's postcard landscape.
    let areaRegion: Region?
    /// At most two facts, highest stakes first; `[.quiet]` when nothing is current.
    let facts: [AnswerFact]
    let officials: [AgencyNotices]
    let sections: [NearbySection]
    /// Today's DACO reference range for the default grade.
    let dacoRange: DacoRange?
    let isCrisis: Bool

    /// The station the crisis answer names, which "Cómo llegar" goes to.
    var nearestFuelStation: Place? {
        facts.lazy.compactMap { fact -> Place? in
            if case .nearestFuel(let answer, _) = fact { answer.place } else { nil }
        }.first
    }

    func sections(for tier: DisclosureTier) -> ArraySlice<NearbySection> {
        sections.prefix(tier.sectionCap)
    }

    func section(_ kind: NearbySection.Kind) -> NearbySection? {
        sections.first { $0.kind == kind }
    }
}
