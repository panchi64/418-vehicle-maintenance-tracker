import SwiftUI

/// The business being claimed or posted for: its name and where it is.
struct OwnerPlaceHeader: View {
    let place: Place

    var body: some View {
        HStack(spacing: Spacing.s3) {
            LayerPin(layer: .businesses, size: Size.listPin)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: place.name)
                    .textRole(.headline)
                    .foregroundStyle(Color(.ink))
                Group {
                    if let barrio = place.barrio {
                        Text("\(barrio), \(place.municipio)", comment: "Owner header: the place's barrio, then its municipio")
                    } else {
                        Text(verbatim: place.municipio)
                    }
                }
                .textRole(.footnote)
                .foregroundStyle(Color(.ink2))
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

/// What verifying gives, what it takes, and whether you're at the place.
struct OwnerClaimIntro: View {
    let isPresent: Bool
    let distance: Double
    let onStart: () -> Void

    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("Verifícalo y publica si abriste, si tienes planta, lo que tienes y tus eventos.", comment: "Owner claim: what verifying lets an owner post")
                .textRole(.answerSmall)
                .foregroundStyle(Color(.ink))
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text("Lo tuyo sale con este sello:", comment: "Owner claim: an owner's posts carry this seal")
                    .textRole(.footnote)
                    .foregroundStyle(Color(.ink2))
                VerificationBadge(label: .verifiedOwner, role: .subheadline)
            }
            SectionGroup(title: LocalizedStringResource("Lo que necesitas", comment: "Owner claim: what verifying takes")) {
                requirement(
                    isPresent
                        ? LocalizedStringResource("Estás en el negocio.", comment: "Owner claim requirement met: you are at the business")
                        : LocalizedStringResource("Estar en el negocio. Ahora estás a \(GlanceNumbers.distance(meters: distance, locale: locale)).", comment: "Owner claim requirement unmet: be at the business; how far you are"),
                    isMet: isPresent
                )
                RowDivider(isInset: false)
                requirement(LocalizedStringResource("Entrar con tu cuenta de Apple.", comment: "Owner claim requirement: sign in with Apple"), isMet: nil)
                RowDivider(isInset: false)
                requirement(LocalizedStringResource("Una llamada al negocio o tu Registro de Comerciante.", comment: "Owner claim requirement: a call to the business or its merchant registration"), isMet: nil)
            }
            Text("No publicamos tu nombre, solo “Dueño verificado”. El sello dura un año.", comment: "Owner claim: the owner's name is never shown; the seal lasts a year")
                .textRole(.footnote)
                .foregroundStyle(Color(.ink2))
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: LocalizedStringResource("Empezar", comment: "Owner claim: start verifying"), action: onStart)
                .disabled(!isPresent)
        }
    }

    /// A requirement with a symbol and a word state, never colour alone.
    private func requirement(_ text: LocalizedStringResource, isMet: Bool?) -> some View {
        Label {
            Text(text).fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: isMet == false ? "location.slash" : isMet == true ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(Color(isMet == false ? .statusCaution : isMet == true ? .statusOk : .ink3))
                .accessibilityHidden(true)
        }
        .textRole(.body)
        .foregroundStyle(Color(.ink))
        .frame(maxWidth: .infinity, minHeight: Size.target, alignment: .leading)
    }
}

/// Owners need an account (§13); the name and email are never shown.
struct OwnerAccountStep: View {
    let onSignIn: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("Entra con tu cuenta para que el sello quede a tu nombre, aunque cambies de teléfono.", comment: "Owner claim: why an account is needed")
                .textRole(.answerSmall)
                .foregroundStyle(Color(.ink))
                .fixedSize(horizontal: false, vertical: true)
            Text("Biombo no publica tu nombre ni tu correo.", comment: "Owner claim: the name and email are never published")
                .textRole(.footnote)
                .foregroundStyle(Color(.ink2))
            PrimaryButton(title: LocalizedStringResource("Continuar con Apple", comment: "Owner claim: sign in with Apple"), symbol: "apple.logo", action: onSignIn)
        }
    }
}

/// "Elige cómo": the call to the public phone, or a document for staff.
struct OwnerMethodStep: View {
    let phone: String?
    let onCall: () -> Void
    let onDocument: (Data) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("Elige cómo lo verificamos.", comment: "Owner claim: pick how to prove it")
                .textRole(.answerSmall)
                .foregroundStyle(Color(.ink))
            VStack(alignment: .leading, spacing: 0) {
                PinChoiceRow(
                    layer: .businesses, glyph: "phone.fill",
                    title: Text("Te llamamos al negocio", comment: "Owner claim method: a call to the business's phone"),
                    subtitle: phone.map { Text("Al \($0) que aparece en el mapa. Te decimos un código de 4 números.", comment: "Owner claim method detail: the public phone, then a 4-digit code") }
                        ?? Text("Este negocio no tiene teléfono en el mapa.", comment: "Owner claim method unavailable: no public phone"),
                    accessory: .forward,
                    action: onCall
                )
                .disabled(phone == nil)
            }
            .insetGroup()
            SectionGroup(title: LocalizedStringResource("O sube tu Registro de Comerciante", comment: "Owner claim method: upload the merchant registration")) {
                VStack(alignment: .leading, spacing: Spacing.s3) {
                    Text("El certificado de SURI con el nombre y la dirección del negocio. Una persona de Biombo lo revisa.", comment: "Owner claim document: which certificate, and that staff review it")
                        .textRole(.footnote)
                        .foregroundStyle(Color(.ink2))
                        .fixedSize(horizontal: false, vertical: true)
                    PhotoSourceButtons(
                        cameraTitle: LocalizedStringResource("Retratarlo", comment: "Owner claim: photograph the certificate"),
                        libraryTitle: LocalizedStringResource("Elegir foto", comment: "Pick a photo from the library"),
                        onPhoto: onDocument
                    )
                }
                .padding(.vertical, Spacing.s3)
            }
        }
    }
}
