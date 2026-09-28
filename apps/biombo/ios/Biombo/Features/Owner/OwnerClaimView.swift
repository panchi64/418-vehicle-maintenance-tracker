import SwiftUI

/// "¿Es tu negocio?" (PRODUCT.md §5 owner verification, Contribute-OwnerClaim):
/// what verifying gives, then an account, then one proof — a call to the
/// place's public phone with a 4-digit code, or a Registro de Comerciante
/// for staff. Only from the place itself. The owner's name is never shown;
/// only the "Dueño verificado" seal is.
struct OwnerClaimView: View {
    let place: Place
    /// Metres from where you stand, for the presence check.
    let distance: Double
    let now: Date
    /// "Publicar ahora" once verified.
    let onPost: () -> Void

    @State private var flow: OwnerClaimFlow
    @Environment(ContributionStore.self) private var contributions
    @Environment(\.ownerVerifier) private var verifier
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    init(place: Place, distance: Double, now: Date, onPost: @escaping () -> Void) {
        self.place = place
        self.distance = distance
        self.now = now
        self.onPost = onPost
        _flow = State(initialValue: OwnerClaimFlow(placeID: place.id, isPresent: distance <= ContributionRules.snapRadius(for: .business)))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    OwnerPlaceHeader(place: place)
                    step
                }
                .padding(.horizontal, Spacing.gutter)
                .padding(.vertical, Spacing.s4)
            }
            .background(Color(.paperSheet))
            .navigationTitle(Text("¿Es tu negocio?", comment: "More menu: claim this business as its owner"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if flow.step == .method || flow.step.isCode || flow.step == .locked || flow.step == .account {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { flow.back() } label: { Text("Atrás", comment: "Go back one step") }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: { Text("Cerrar", comment: "Close a card or panel") }
                }
            }
        }
        .onAppear {
            if contributions.isSignedIn { flow.signedIn() }
        }
    }

    @ViewBuilder
    private var step: some View {
        switch flow.step {
        case .intro:
            OwnerClaimIntro(isPresent: flow.isPresent, distance: distance) { flow.start() }
        case .account:
            OwnerAccountStep {
                Task {
                    guard let verifier, await verifier.signIn() else { return }
                    contributions.signedIn()
                    flow.signedIn()
                }
            }
        case .method:
            OwnerMethodStep(phone: place.publicPhone) {
                Task {
                    guard let verifier else { return }
                    await verifier.call(place.id)
                    flow.requestCall()
                }
            } onDocument: { document in
                Task {
                    guard let verifier else { return }
                    await verifier.submit(document: document, for: place.id)
                    contributions.submittedClaim(place.id)
                    flow.submittedDocument()
                }
            }
        case .code(let attemptsLeft):
            OwnerCodeStep(
                phone: place.publicPhone, attemptsLeft: attemptsLeft, isFirstTry: attemptsLeft == ContributionRules.ownerCodeAttempts,
                sampleCode: verifier?.sampleCode, onCode: check, onCallAgain: callAgain
            )
        case .locked:
            OwnerCodeStep(phone: place.publicPhone, attemptsLeft: 0, isFirstTry: false, sampleCode: nil, onCode: { _ in }, onCallAgain: callAgain)
        case .inReview:
            OwnerOutcome.inReview(place: place) { dismiss() }
        case .verified(let until):
            OwnerOutcome.verified(place: place, until: until, locale: locale, onPost: onPost) { dismiss() }
        }
    }

    private func check(_ code: String) {
        Task {
            guard let verifier else { return }
            let isCorrect = await verifier.check(code: code, for: place.id)
            flow.entered(codeIsCorrect: isCorrect, now: now)
            if case .verified(let until) = flow.step {
                contributions.verified(place.id, until: until)
            }
        }
    }

    private func callAgain() {
        Task {
            guard let verifier else { return }
            await verifier.call(place.id)
            flow.callAgain()
        }
    }
}
