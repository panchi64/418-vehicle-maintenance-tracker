import SwiftUI

/// The detail's ••• menu: the verbs that aren't primary (PRODUCT.md §3).
struct PlaceMoreMenu: View {
    /// The owner's entry on a business: claim it, post as its owner, or
    /// wait for the claim's review (§5, §6.8).
    enum OwnerItem {
        case none
        case claim(() -> Void)
        case post(() -> Void)
        case inReview
    }

    let detail: PlaceDetail
    var owner: OwnerItem = .none
    let onReport: () -> Void

    @Environment(\.locale) private var locale

    var body: some View {
        Menu {
            ShareLink(
                item: MapsApp.appleMaps.directionsURL(to: detail.anchor),
                subject: Text(verbatim: detail.name),
                message: Text(detail.accessibilityName)
            ) {
                Label { Text("Compartir", comment: "More menu: share this place") } icon: { Image(systemName: "square.and.arrow.up") }
            }
            Button {
                UIPasteboard.general.string = String(localized: detail.accessibilityName)
            } label: {
                Label { Text("Copiar nombre", comment: "More menu: copy the place's name and municipio") } icon: { Image(systemName: "doc.on.doc") }
            }
            Button(action: onReport) {
                Label { Text("Algo está mal aquí", comment: "More menu: report something wrong about this place") } icon: { Image(systemName: "exclamationmark.bubble") }
            }
            ownerItem
        } label: {
            RoundGlyph(symbol: "ellipsis")
        }
        .accessibilityLabel(Text("Más acciones", comment: "VoiceOver: the more-actions menu"))
    }

    /// Its own group, after the everyday verbs. A claim in review is shown dimmed (N13).
    @ViewBuilder
    private var ownerItem: some View {
        switch owner {
        case .none:
            EmptyView()
        case .claim(let action):
            Divider()
            Button(action: action) {
                Label { Text("¿Es tu negocio?", comment: "More menu: claim this business as its owner") } icon: { Image(systemName: "checkmark.seal") }
            }
        case .post(let action):
            Divider()
            Button(action: action) {
                Label { Text("Publicar como dueño", comment: "More menu: post as this business's verified owner") } icon: { Image(systemName: "checkmark.seal") }
            }
        case .inReview:
            Divider()
            Button {} label: {
                Label { Text("Verificando que es tu negocio", comment: "More menu: the owner claim is in review") } icon: { Image(systemName: "hourglass") }
            }
            .disabled(true)
        }
    }
}
