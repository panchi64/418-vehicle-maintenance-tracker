import SwiftUI

/// "Te estamos llamando": the 4-digit code heard on the call to the
/// business. A full code checks itself; wrong ones say how many tries are
/// left, and after the last one only a new call helps.
struct OwnerCodeStep: View {
    let phone: String?
    let attemptsLeft: Int
    let isFirstTry: Bool
    /// The code a sample verifier's pretend call reads out; debug builds show it.
    let sampleCode: String?
    let onCode: (String) -> Void
    let onCallAgain: () -> Void

    @State private var code = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            if let phone {
                Text("Te estamos llamando al \(phone). Escribe el código que te decimos.", comment: "Owner code: the call is going to the business phone; type the code")
                    .textRole(.answerSmall)
                    .foregroundStyle(Color(.ink))
                    .fixedSize(horizontal: false, vertical: true)
            }
            if attemptsLeft > 0 {
                TextField(text: $code, prompt: Text(verbatim: "••••")) {
                    Text("Código", comment: "Owner code: the code field")
                }
                .textRole(.hero)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .padding(.horizontal, Spacing.s4)
                .padding(.vertical, Spacing.s2)
                .background(Color(.paperRaised), in: .rect(cornerRadius: Radius.medium))
                .contrastEdge()
                .onAppear { isFocused = true }
                .onChange(of: code) { _, new in
                    let digits = String(new.filter(\.isNumber).prefix(ContributionRules.ownerCodeLength))
                    if digits != new { code = digits }
                    if digits.count == ContributionRules.ownerCodeLength {
                        onCode(digits)
                        code = ""
                    }
                }
            }
            if !isFirstTry {
                Label {
                    Text(attemptsLeft > 0
                         ? LocalizedStringResource("Ese código no es. Te quedan \(attemptsLeft) intentos.", comment: "Owner code: wrong code; tries left, plural by count")
                         : LocalizedStringResource("Ese código tampoco es. Pide otra llamada para un código nuevo.", comment: "Owner code: out of tries; ask for another call"))
                } icon: {
                    Image(systemName: "exclamationmark.circle").accessibilityHidden(true)
                }
                .textRole(.footnote)
                .foregroundStyle(Color(.statusCritical))
                .fixedSize(horizontal: false, vertical: true)
            }
            Button(action: onCallAgain) {
                Label { Text("Llámame otra vez", comment: "Owner code: place the call again") } icon: { Image(systemName: "phone.arrow.up.right") }
                    .textRole(.subheadline)
                    .frame(minHeight: Size.target)
            }
            .foregroundStyle(.tint)
            #if DEBUG
            if let sampleCode {
                Text("Muestra: el código es \(sampleCode).", comment: "Sample builds only: the code the pretend call reads out")
                    .textRole(.footnote)
                    .foregroundStyle(Color(.ink3))
            }
            #endif
        }
    }
}

/// Where a claim ends: in review, or verified.
enum OwnerOutcome {
    /// "Estamos verificando": the place stays as it is meanwhile.
    static func inReview(place: Place, onDone: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Label { Text("Estamos verificando", comment: "Owner claim: the document is in review") } icon: { Image(systemName: "hourglass").accessibilityHidden(true) }
                .textRole(.answer)
                .foregroundStyle(Color(.ink))
            Text("Te avisamos en 1 o 2 días laborables. Mientras tanto, el negocio sigue como está: lo que dicen los vecinos, sin sello.", comment: "Owner claim in review: when they'll hear, and that nothing changes meanwhile")
                .textRole(.body)
                .foregroundStyle(Color(.ink2))
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: LocalizedStringResource("Listo", comment: "Done: close this screen"), action: onDone)
        }
    }

    /// "Listo": the seal, how long it lasts, and the first post.
    static func verified(place: Place, until: Date, locale: Locale, onPost: @escaping () -> Void, onDone: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            VerificationBadge(label: .verifiedOwner, role: .headline)
            Text("Listo. Ya eres el dueño verificado de \(place.name).", comment: "Owner claim verified: you are now the verified owner")
                .textRole(.answer)
                .foregroundStyle(Color(.ink))
                .fixedSize(horizontal: false, vertical: true)
            Text("El sello vence el \(until.island(.dateTime.day().month(.wide).year(), locale: locale)).", comment: "Owner claim verified: when the seal expires")
                .textRole(.footnote)
                .foregroundStyle(Color(.ink2))
            PrimaryButton(title: LocalizedStringResource("Publicar ahora", comment: "Owner claim verified: post today's status now"), action: onPost)
            Button(action: onDone) {
                Text("Más tarde", comment: "Owner claim verified: post later")
                    .textRole(.subheadline)
                    .frame(maxWidth: .infinity, minHeight: Size.target)
            }
            .foregroundStyle(.tint)
        }
    }
}
