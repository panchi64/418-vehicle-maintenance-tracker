import Foundation

/// "Publicar como dueño" (PRODUCT.md §6.8, Contribute-OwnerPost): today's
/// status, what's in stock and an event, as owner reports. The status shows
/// until the end of the day; owner text is filtered (§5). Pure.
nonisolated struct OwnerPostDraft: Hashable, Sendable {
    nonisolated enum Status: String, CaseIterable, Hashable, Sendable {
        case open
        case onGenerator
        case closedToday

        var kind: ReportKind {
            switch self {
            case .open: .businessOpen
            case .onGenerator: .businessOnGenerator
            case .closedToday: .businessClosed
            }
        }
    }

    var status: Status = .open
    /// "Hay (producto)": hielo, agua, pan…
    var product = ""
    var hasEvent = false
    var eventTitle = ""
    var eventStart: Date
    var eventEnd: Date

    init(now: Date, calendar: Calendar = PuertoRico.calendar) {
        let evening = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now) ?? now
        eventStart = evening
        eventEnd = evening.addingTimeInterval(.hours(3))
    }

    private var trimmedProduct: String { product.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedTitle: String { eventTitle.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// A word owners can't publish in the product. Closed for the day, the
    /// product is hidden and not published, so it can't block anything.
    var productBlockedTerm: String? {
        status == .closedToday ? nil : OwnerTextFilter.blockedTerm(in: trimmedProduct)
    }

    /// A word owners can't publish in the event title, while there is an event.
    var eventBlockedTerm: String? {
        hasEvent ? OwnerTextFilter.blockedTerm(in: trimmedTitle) : nil
    }

    /// The first word owners can't publish, in whatever would be published.
    var blockedTerm: String? { productBlockedTerm ?? eventBlockedTerm }

    var canPublish: Bool {
        blockedTerm == nil && (!hasEvent || (!trimmedTitle.isEmpty && eventEnd > eventStart))
    }

    /// When today's status stops showing: the end of today in Puerto Rico.
    static func endOfDay(for now: Date, calendar: Calendar = PuertoRico.calendar) -> Date {
        let start = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: 1, to: start)?.addingTimeInterval(-60) ?? now
    }

    /// The owner reports this draft publishes, all captured `now`.
    func reports(for placeID: Place.ID, now: Date, calendar: Calendar = PuertoRico.calendar) -> [Report] {
        let endOfDay = Self.endOfDay(for: now, calendar: calendar)
        var reports = [Report(kind: status.kind, placeID: placeID, capturedAt: now, source: .owner, statedEnd: endOfDay)]
        if !trimmedProduct.isEmpty, status != .closedToday {
            reports.append(Report(kind: .productAvailable, value: .ownerText(trimmedProduct), placeID: placeID, capturedAt: now, source: .owner, statedEnd: endOfDay))
        }
        if hasEvent, !trimmedTitle.isEmpty {
            let event = OwnerEvent(title: trimmedTitle, start: eventStart, end: eventEnd)
            reports.append(Report(kind: .event, value: .event(event), placeID: placeID, capturedAt: now, source: .owner, statedEnd: eventEnd))
        }
        return reports
    }
}
