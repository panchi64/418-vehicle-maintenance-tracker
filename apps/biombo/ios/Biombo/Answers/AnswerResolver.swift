import Foundation

/// Turns reports into one answer per place and layer, and outage areas into
/// drawable statuses. This is the freshness gate for everything the map and
/// the sheet show: only `.fresh` and `.aging` items come out as current.
nonisolated struct AnswerResolver: Sendable {
    var freshness = FreshnessPolicy()
    var verification = VerificationRules()
    /// The grade the answer quotes by default (§6.1).
    var defaultGrade: FuelGrade = .regular
    /// The median applies once this many fresh prices agree on a grade (*proposed*, §6.1).
    nonisolated static let medianMinimum = 3

    // MARK: - Places

    /// One current answer per layer for `place`, newest evidence first within each rule.
    func answers(for place: Place, reports: [Report], now: Date) -> [PlaceAnswer] {
        let usable = reports.filter { report in
            report.placeID == place.id
                && !isRepresentedByAreas(report.kind, on: place)
                && !report.kind.isOwnerOnly
                && freshness.evaluate(report, now: now).isCurrent
                && verification.disputeState(for: report) != .resolved
        }
        return Layer.allCases.compactMap { layer in
            let candidates = usable.filter { $0.layer == layer }
            guard !candidates.isEmpty else { return nil }
            let statuses = candidates.filter { $0.kind != .price }
            if layer == .gas, let priced = priceAnswer(for: place, candidates: candidates, now: now) {
                // A closed or dry station has no price worth quoting, unless the
                // price outranks the negative (§6.1): same rule as any lead.
                let negatives = statuses.filter(\.kind.meansNoFuel)
                guard let lead = pickLead(negatives + [priced.lead], place: place), lead.kind != .price else {
                    return priced
                }
                return answer(place: place, lead: lead, value: .status(lead.kind), now: now)
            }
            guard let lead = pickLead(statuses, place: place) else {
                return priceAnswer(for: place, candidates: candidates, now: now, anyGrade: true)
            }
            return answer(place: place, lead: lead, value: .status(lead.kind), now: now)
        }
    }

    /// Stale reports on `place`, each its own answer, for "Ver reportes anteriores".
    func staleAnswers(for place: Place, reports: [Report], now: Date) -> [PlaceAnswer] {
        reports
            .filter { $0.placeID == place.id && !isRepresentedByAreas($0.kind, on: place) && !$0.kind.isOwnerOnly }
            .filter { freshness.evaluate($0, now: now).isRevealableOnly }
            .map { report in
                let value: AnswerValue = report.price.map(AnswerValue.price) ?? .status(report.kind)
                return answer(place: place, lead: report, value: value, now: now)
            }
    }

    /// Every current report on `place` and `layer`, each as its own answer,
    /// newest first: the reports behind the answer, for depth.
    func currentReports(for place: Place, layer: Layer, reports: [Report], now: Date) -> [PlaceAnswer] {
        reportAnswers(for: place, layer: layer, reports: reports, now: now) {
            freshness.evaluate($0, now: now).isCurrent && verification.disputeState(for: $0) != .resolved
        }
    }

    /// Stale reports on `place` and `layer`, newest first, outage kinds
    /// included: what "Ver reportes anteriores" reveals on a detail.
    func olderReports(for place: Place, layer: Layer, reports: [Report], now: Date) -> [PlaceAnswer] {
        reportAnswers(for: place, layer: layer, reports: reports, now: now) { freshness.evaluate($0, now: now).isRevealableOnly }
    }

    private func reportAnswers(for place: Place, layer: Layer, reports: [Report], now: Date, where include: (Report) -> Bool) -> [PlaceAnswer] {
        reports
            .filter { $0.placeID == place.id && $0.layer == layer && !$0.kind.isOwnerOnly && include($0) }
            .sorted { $0.freshnessAnchor > $1.freshnessAnchor }
            .map { report in
                let value: AnswerValue = report.price.map(AnswerValue.price) ?? .status(report.kind)
                return answer(place: place, lead: report, value: value, now: now)
            }
    }

    /// Current owner-only posts on `place` (events, stock, special hours), newest first.
    func ownerPosts(for place: Place, reports: [Report], now: Date) -> [Report] {
        reports
            .filter { $0.placeID == place.id && $0.kind.isOwnerOnly }
            .filter { freshness.evaluate($0, now: now).isCurrent && verification.disputeState(for: $0) != .resolved }
            .sorted { $0.freshnessAnchor > $1.freshnessAnchor }
    }

    // MARK: - Areas

    /// Current, drawable outage areas: at least 3 devices or an official part (§7).
    func areaStatuses(_ areas: [OutageArea], isCrisis: Bool, now: Date) -> [AreaStatus] {
        areas.compactMap { area in
            guard let label = verification.label(for: area) else { return nil }
            let state = freshness.evaluate(area, label: label, isCrisis: isCrisis, now: now)
            guard state.isCurrent else { return nil }
            return AreaStatus(
                area: area, label: label, confidence: verification.confidence(for: area), freshness: state,
                extensionConfidence: area.communityExtension.flatMap(verification.confidence(for:))
            )
        }
    }

    // MARK: - Rules

    /// On an area place, outages and their reversals live in the area polygon,
    /// never as per-report pins (§6.2 "Map").
    func isRepresentedByAreas(_ kind: ReportKind, on place: Place) -> Bool {
        guard place.kind == .area else { return false }
        return kind.isOutageState || (kind.reverses?.isOutageState ?? false)
    }

    /// Owner first on an owned place, then official, then confirmed, then unverified;
    /// newest within each. One unverified negative never flips a stated answer.
    private func pickLead(_ reports: [Report], place: Place) -> Report? {
        reports.max { lhs, rhs in
            let left = rank(lhs, place: place)
            let right = rank(rhs, place: place)
            return left != right ? left < right : lhs.freshnessAnchor < rhs.freshnessAnchor
        }
    }

    private func rank(_ report: Report, place: Place) -> Int {
        verification.label(for: report, placeHasVerifiedOwner: place.hasVerifiedOwner).leadRank
    }

    /// §6.1: the median of fresh prices once there are enough, else the latest
    /// confirmed, else the latest unverified.
    private func priceAnswer(for place: Place, candidates: [Report], now: Date, anyGrade: Bool = false) -> PlaceAnswer? {
        let priced = candidates.compactMap { report -> (Report, FuelPrice)? in
            guard case .price(let price) = report.value else { return nil }
            return (report, price)
        }
        let grade = anyGrade ? priced.map(\.1.grade).first : defaultGrade
        let sameGrade = priced.filter { $0.1.grade == grade }
        guard !sameGrade.isEmpty else { return nil }

        let fresh = sameGrade.filter { freshness.evaluate($0.0, now: now) == .fresh }
        if fresh.count >= Self.medianMinimum, let median = fresh.map(\.1.centsPerLitre).median {
            let newest = fresh.max { $0.0.freshnessAnchor < $1.0.freshnessAnchor }!.0
            return answer(place: place, lead: newest, value: .price(FuelPrice(grade: fresh[0].1.grade, centsPerLitre: median)), now: now)
        }
        guard let lead = pickLead(sameGrade.map(\.0), place: place),
              case .price(let price) = lead.value else { return nil }
        return answer(place: place, lead: lead, value: .price(price), now: now)
    }

    private func answer(place: Place, lead: Report, value: AnswerValue, now: Date) -> PlaceAnswer {
        PlaceAnswer(
            place: place,
            layer: lead.layer,
            lead: lead,
            value: value,
            label: verification.label(for: lead, placeHasVerifiedOwner: place.hasVerifiedOwner),
            freshness: freshness.evaluate(lead, now: now),
            dispute: verification.disputeState(for: lead)
        )
    }
}
