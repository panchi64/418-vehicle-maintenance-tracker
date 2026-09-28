import Foundation

/// The one compact question under a detail's answer (PRODUCT.md §4.3):
/// "¿Sigue a $0.99?" / "¿Sigue sin luz?", answered Sigue igual / Ya no.
nonisolated enum ConfirmQuestion: Hashable, Sendable {
    /// "¿Sigue a $0.99?"; "Ya no" then asks what changed.
    case price(FuelPrice)
    /// "¿Sigue sin gasolina?", "¿Sigue funcionando?", "¿Sigue inundada?"…
    case status(ReportKind)
    /// "¿Sigue sin luz?" about an outage area.
    case outage(Layer)

    /// Only a changed price has a follow-up: another price, or no gas at all.
    var asksWhatChanged: Bool {
        if case .price = self { true } else { false }
    }

    /// The question for an answer; nil for official items, which are never voted on.
    init?(_ answer: PlaceAnswer) {
        guard answer.label.canBeVotedOn else { return nil }
        switch answer.value {
        case .price(let price): self = .price(price)
        case .status(let kind): self = .status(kind)
        }
    }

    init?(_ status: AreaStatus) {
        guard status.label.canBeVotedOn else { return nil }
        self = .outage(status.layer)
    }
}

extension VerificationLabel {
    /// Official items are never voted on; a contradiction shows both instead (§4.3).
    nonisolated var canBeVotedOn: Bool {
        if case .official = self { false } else { true }
    }
}

/// Who may answer: people nearby at vote time (§4.3, *proposed* radii).
nonisolated enum ConfirmRules {
    nonisolated static let placeRadius = 300.0
    nonisolated static let areaRadius = 1_000.0

    /// Far-away users see the question dimmed with "Solo quien está cerca puede confirmar".
    static func isNearby(distance: Double, isArea: Bool) -> Bool {
        distance <= (isArea ? areaRadius : placeRadius)
    }
}

/// Where the question stands on this visit. Pure: the 5-second window for
/// Deshacer is kept by the view that shows it.
nonisolated enum ConfirmStep: Hashable, Sendable {
    case asking
    /// After "Ya no" on a price: "¿Qué cambió?".
    case askingWhatChanged
    case answered(ConfirmReply)
    /// A vote from an earlier visit: said, and changeable once (§4.3).
    case standing(agrees: Bool, canChange: Bool)

    /// The step after an answer.
    func replying(_ reply: ConfirmReply, to question: ConfirmQuestion) -> ConfirmStep {
        switch (self, reply) {
        case (.asking, .changed) where question.asksWhatChanged: .askingWhatChanged
        case (.asking, _), (.askingWhatChanged, _): .answered(reply)
        case (.answered, _), (.standing, _): self
        }
    }

    /// What this visit shows: a vote already on the book stands, unless the
    /// user reopened it with Cambiar or answered on this visit.
    static func shown(_ step: ConfirmStep, standing vote: MyVote?, isRevising: Bool) -> ConfirmStep {
        guard step == .asking, !isRevising, let vote else { return step }
        return .standing(agrees: vote.agrees, canChange: !vote.hasChanged)
    }
}

extension ConfirmReply {
    /// Sigue igual, and a price's "Otro precio" or "No hay", count as what they say (§4.3).
    nonisolated var agrees: Bool { self == .same }
}

nonisolated enum ConfirmReply: Hashable, Sendable {
    /// "Sigue igual": adds confirming weight and resets freshness.
    case same
    /// "Ya no".
    case changed
    /// A price's follow-up: "Otro precio", which leads to reporting it.
    case otherPrice
    /// A price's follow-up: "No hay gasolina".
    case noGas
}
