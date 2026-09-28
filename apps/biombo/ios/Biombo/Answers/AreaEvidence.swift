import Foundation

/// Who says an area is out (PRODUCT.md §3, §7): the agency and neighbours,
/// side by side and never averaged. Feeds "¿Dónde no hay luz?" and the
/// agreement bar.
nonisolated struct SourceMix: Hashable, Sendable {
    /// Where one barrio's answer comes from.
    nonisolated enum Voice: Hashable, Sendable {
        /// Inside the agency's outline ("LUMA lo confirma").
        case official(Agency)
        /// Only neighbours report it ("Solo vecinos").
        case neighbours
    }

    nonisolated struct Barrio: Hashable, Sendable {
        let name: String
        let voice: Voice
    }

    let agency: Agency?
    /// Distinct phones reporting inside the outline, or across a community area.
    let agreeing: Int
    /// Distinct phones reporting past an official outline.
    let extending: Int
    /// Phones saying it came back, from the dispute share.
    let saidBack: Int
    let barrios: [Barrio]

    init(_ area: OutageArea) {
        let voice: Voice = area.officialAgency.map(Voice.official) ?? .neighbours
        agency = area.officialAgency
        agreeing = area.evidence.distinctDevices
        extending = area.communityExtension?.distinctDevices ?? 0
        saidBack = Int((Double(area.evidence.distinctDevices) * area.evidence.disputeShare).rounded())
        barrios = area.barrios.map { Barrio(name: $0, voice: voice) }
            + (area.communityExtension?.barrios ?? []).map { Barrio(name: $0, voice: .neighbours) }
    }

    /// Every phone that reported the outage, inside the outline or past it,
    /// including the ones that later said it came back.
    var neighbours: Int { agreeing + extending }

    /// The phones that still say it is out: everyone but those who said it came back.
    var stillOut: Int { max(neighbours - saidBack, 0) }

    /// Worth its own bar only when neighbours report past an agency's outline.
    var hasExtension: Bool { agency != nil && extending > 0 }
}

/// "¿Cómo ha ido?" in depth: first neighbour, the agency's notice, the latest
/// confirmation, in time order (V2-Outage).
nonisolated struct AreaTimeline: Hashable, Sendable {
    nonisolated enum Event: Hashable, Sendable {
        case firstNeighbour
        case official(Agency)
        case latestConfirmation
    }

    nonisolated struct Entry: Hashable, Sendable {
        let date: Date
        let event: Event
    }

    let entries: [Entry]
    /// How long after the first neighbour the agency said so; nil when it
    /// spoke first or not at all.
    let officialLag: TimeInterval?

    init(_ area: OutageArea) {
        var entries: [Entry] = []
        // A planned outage starts with the plan; neighbours never preceded it.
        let neighboursFirst = area.officialAgency == nil || (area.officialSince.map { $0 > area.openedAt } ?? false)
        if neighboursFirst && !area.isPlanned {
            entries.append(Entry(date: area.openedAt, event: .firstNeighbour))
        }
        if let agency = area.officialAgency {
            entries.append(Entry(date: area.officialSince ?? area.openedAt, event: .official(agency)))
        }
        if area.evidence.distinctDevices > 0, area.latestEvidenceAt > (entries.last?.date ?? .distantPast) {
            entries.append(Entry(date: area.latestEvidenceAt, event: .latestConfirmation))
        }
        self.entries = entries.sorted { $0.date < $1.date }
        if neighboursFirst, !area.isPlanned, let officialSince = area.officialSince {
            officialLag = officialSince.timeIntervalSince(area.openedAt)
        } else {
            officialLag = nil
        }
    }
}
