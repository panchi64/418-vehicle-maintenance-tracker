import Foundation

/// How old something is, in the words §3 allows: relative under 24 h
/// ("ahora", "hace 12 min", "hace 2 h"), then "ayer", then a date.
nonisolated enum AgePhrase: Hashable, Sendable {
    case now
    case minutes(Int)
    case hours(Int)
    case yesterday
    case date(Date)

    init(since date: Date, now: Date, calendar: Calendar = PuertoRico.calendar) {
        let seconds = max(0, now.timeIntervalSince(date))
        switch seconds {
        case ..<60: self = .now
        case ..<3600: self = .minutes(Int(seconds / 60))
        case ..<86_400: self = .hours(Int(seconds / 3600))
        default:
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now).map { calendar.isDate(date, inSameDayAs: $0) } ?? false
            self = yesterday ? .yesterday : .date(date)
        }
    }
}

/// The one trust atom of a row (§3 "Row budget"): freshness and verification
/// merged into one phrase with one symbol, promoted when it is the news.
nonisolated struct TrustSuffix: Hashable, Sendable {
    enum Phrase: Hashable, Sendable {
        /// "Confirmado hace 12 min"
        case confirmed(AgePhrase)
        /// "Sin verificar · hace 25 min"
        case unverified(AgePhrase)
        /// "Dueño verificado · hace 1 h"
        case owner(AgePhrase)
        /// "Oficial · LUMA, 4:00 p. m." — official items state their clock time
        /// today, and "ayer" or a date before today.
        case official(Agency, OfficialStamp)
        /// "Vecinos no coinciden · hace 20 min"
        case disputed(AgePhrase)
        /// "Reportado hace 3 días": behind "Ver reportes anteriores", age first.
        case stale(AgePhrase)
    }

    enum OfficialStamp: Hashable, Sendable {
        case today(Date)
        case earlier(AgePhrase)
    }

    enum Tone: Hashable, Sendable {
        /// ink-3, after the context atom.
        case quiet
        /// Promoted to the front of the line in its label's ink.
        case news
        /// Getting old: promoted in caution ink with a clock, never in the
        /// label's own ink, so age never reads as more trust.
        case aging
        /// Stale ink with the clock symbol.
        case stale
    }

    let phrase: Phrase
    let tone: Tone
    /// The label behind the phrase; the symbol follows it unless disputed or stale.
    let label: VerificationLabel

    init(label: VerificationLabel, freshness: Freshness, dispute: DisputeState, stamp: Date, now: Date) {
        self.label = label
        let age = AgePhrase(since: stamp, now: now)
        if !freshness.isCurrent {
            phrase = .stale(age)
            tone = .stale
            return
        }
        if dispute == .disputed {
            phrase = .disputed(age)
            tone = .news
            return
        }
        switch label {
        case .official(let agency):
            let today = PuertoRico.calendar.isDate(stamp, inSameDayAs: now)
            phrase = .official(agency, today ? .today(stamp) : .earlier(age))
        case .verifiedOwner: phrase = .owner(age)
        case .communityConfirmed: phrase = .confirmed(age)
        case .unverified: phrase = .unverified(age)
        }
        tone = freshness == .aging ? .aging : label == .unverified ? .news : .quiet
    }

    init(_ answer: PlaceAnswer, now: Date) {
        self.init(label: answer.label, freshness: answer.freshness, dispute: answer.dispute, stamp: answer.asOf, now: now)
    }

    init(_ status: AreaStatus, now: Date) {
        self.init(label: status.label, freshness: status.freshness, dispute: .none, stamp: status.area.latestEvidenceAt, now: now)
    }

    init(_ notice: OfficialNotice, now: Date) {
        self.init(label: .official(notice.agency), freshness: .fresh, dispute: .none, stamp: notice.updatedAt, now: now)
    }

    /// The source of one clause of the area's answer; nil when the answer is empty.
    init?(_ fact: AnswerFact, now: Date) {
        switch fact {
        case .warning(let notice): self.init(notice, now: now)
        case .outage(let status): self.init(status, now: now)
        case .road(let answer), .cheapestGas(let answer), .nearestFuel(let answer, _): self.init(answer, now: now)
        case .quiet: return nil
        }
    }

    /// Promoted suffixes carry more weight on the secondary line (§3).
    var isPromoted: Bool { tone != .quiet }
}
