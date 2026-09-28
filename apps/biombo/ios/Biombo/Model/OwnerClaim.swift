import Foundation

/// Claiming a business (PRODUCT.md §5 "Owner verification", open decision
/// 22): Sign in with Apple, being at the place, then one proof of control —
/// a code on a call to the place's public phone, or a Registro de
/// Comerciante that Biombo staff review. Pure: whether a code is right is
/// decided elsewhere and handed in.
nonisolated struct OwnerClaimFlow: Hashable, Sendable {
    nonisolated enum Step: Hashable, Sendable {
        /// What verifying gives you, and whether you're at the place.
        case intro
        /// Owners need an account (§13).
        case account
        case method
        /// "Te llamamos al negocio": the code heard on the call.
        case code(attemptsLeft: Int)
        /// Too many wrong codes: the owner asks for another call.
        case locked
        /// A document waiting for staff; the place stays as it is meanwhile.
        case inReview
        case verified(until: Date)
    }

    let placeID: Place.ID
    /// Presence at the place when claiming (§5), from a one-shot fix.
    let isPresent: Bool
    private(set) var isSignedIn: Bool
    private(set) var step: Step = .intro

    init(placeID: Place.ID, isPresent: Bool, isSignedIn: Bool = false) {
        self.placeID = placeID
        self.isPresent = isPresent
        self.isSignedIn = isSignedIn
    }

    /// "Empezar": only from the place itself.
    mutating func start() {
        guard step == .intro, isPresent else { return }
        step = isSignedIn ? .method : .account
    }

    mutating func signedIn() {
        isSignedIn = true
        if step == .account { step = .method }
    }

    /// "Te llamamos al negocio": the call goes out and the code field opens.
    mutating func requestCall() {
        guard step == .method else { return }
        step = .code(attemptsLeft: ContributionRules.ownerCodeAttempts)
    }

    /// "Sube tu Registro de Comerciante": once a document is picked, it waits for staff.
    mutating func submittedDocument() {
        guard step == .method else { return }
        step = .inReview
    }

    /// A full code was entered; `isCorrect` comes from the verifier.
    mutating func entered(codeIsCorrect isCorrect: Bool, now: Date) {
        guard case .code(let attemptsLeft) = step else { return }
        if isCorrect {
            step = .verified(until: now.addingTimeInterval(ContributionRules.ownerVerificationLength))
        } else {
            step = attemptsLeft > 1 ? .code(attemptsLeft: attemptsLeft - 1) : .locked
        }
    }

    /// "Llámame otra vez": a new call, a new code, a fresh set of attempts.
    mutating func callAgain() {
        guard step == .locked || step.isCode else { return }
        step = .code(attemptsLeft: ContributionRules.ownerCodeAttempts)
    }

    /// Back one step from choosing how to prove it.
    mutating func back() {
        switch step {
        case .code, .locked: step = .method
        case .method, .account: step = .intro
        default: break
        }
    }
}

extension OwnerClaimFlow.Step {
    nonisolated var isCode: Bool {
        if case .code = self { true } else { false }
    }
}

/// Owner free text (a product, an event title) never names an agency or
/// uses alert vocabulary, so it can never read as an alert (§5 "Owner
/// content"). Case- and accent-insensitive, on whole words.
nonisolated enum OwnerTextFilter {
    /// Words and phrases an owner can't publish. *Proposed*; staff extend it.
    nonisolated static let blocked: [String] = Agency.allCases.map(\.displayName) + [
        // The agency's full name: "salud" alone is ordinary product text.
        "FEMA", "Negociado", "Manejo de Emergencias", "Departamento de Salud",
        "hierve el agua", "hervir", "refugio", "evacuar", "evacuación", "desalojo",
        "huracán", "tormenta", "inundación", "alerta", "aviso oficial", "emergencia",
        "boil water", "shelter", "evacuate", "hurricane", "warning",
    ]

    /// The first blocked word or phrase in `text`, as the list spells it.
    static func blockedTerm(in text: String) -> String? {
        let words = normalizedWords(text)
        guard !words.isEmpty else { return nil }
        let haystack = " " + words.joined(separator: " ") + " "
        return blocked.first { term in
            haystack.contains(" " + normalizedWords(term).joined(separator: " ") + " ")
        }
    }

    private static func normalizedWords(_ text: String) -> [String] {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }
}
