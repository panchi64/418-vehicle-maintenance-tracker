/// The three-step first run (Flows-Onboarding1–3): what Biombo is, what to
/// see, and why it asks for location. Pure transitions; the location prompt
/// and saving the choice belong to the views and the app.
struct OnboardingFlow: Hashable {
    enum Step: Int, CaseIterable, Hashable {
        case welcome
        case layers
        case location
    }

    private(set) var step: Step = .welcome
    /// The layers drawn from the first launch on (§3 Capas).
    private(set) var layers: Set<Layer>
    /// "Vigilar un lugar": the diaspora's first job (§2), opened on the map.
    var wantsToWatch = false

    init(layers: Set<Layer> = Layer.defaultVisible(inCrisis: false)) {
        self.layers = layers
    }

    /// "Paso 2 de 3".
    var number: Int { step.rawValue + 1 }
    static let stepCount = Step.allCases.count

    var canGoBack: Bool { step != .welcome }
    /// A map with nothing on it answers nothing: at least one layer.
    var canContinue: Bool { step != .layers || !layers.isEmpty }
    var isLast: Bool { step == .location }

    var result: OnboardingResult {
        OnboardingResult(layers: layers, wantsToWatch: wantsToWatch)
    }

    mutating func toggle(_ layer: Layer) {
        if layers.contains(layer) { layers.remove(layer) } else { layers.insert(layer) }
    }

    mutating func advance() {
        guard canContinue, let next = Step(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    mutating func back() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = previous
    }
}

/// What the first run decided.
struct OnboardingResult: Hashable {
    let layers: Set<Layer>
    let wantsToWatch: Bool
}
