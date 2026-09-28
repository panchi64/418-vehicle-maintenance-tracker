import SwiftUI

/// "Ver cómo llega el aviso": the notification as it will look, scoped to
/// this place, and a button that sends it for real as a local notification.
struct WatchPreview: View {
    let place: WatchedPlace
    @Binding var isShown: Bool
    let outcome: WatchNotifier.Outcome?
    let onSend: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            DisclosureRow(
                title: LocalizedStringResource("Ver cómo llega el aviso", comment: "Watch setup: reveal the notification preview"),
                symbol: "bell",
                accessory: isShown ? .collapse : .expand
            ) { isShown.toggle() }
            if isShown {
                banner
                Button(action: onSend) {
                    Label {
                        Text("Enviarme un aviso de prueba", comment: "Watch setup: send the preview as a real notification")
                    } icon: {
                        Image(systemName: "paperplane")
                    }
                    .frame(maxWidth: .infinity, minHeight: Size.target)
                }
                .buttonStyle(.bordered)
                if let outcome {
                    Text(outcomeText(outcome))
                        .textRole(.footnote)
                        .foregroundStyle(Color(.ink2))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// A notification banner drawn in the app: app name and time, title, body.
    private var banner: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Label {
                    Text(verbatim: "Biombo")
                } icon: {
                    Image(systemName: "map").accessibilityHidden(true)
                }
                .textRole(.caption)
                .foregroundStyle(Color(.ink2))
                Spacer()
                Text("ahora", comment: "Age: less than a minute ago")
                    .textRole(.caption)
                    .foregroundStyle(Color(.ink3))
            }
            Text(place.previewTitle).textRole(.headline).foregroundStyle(Color(.ink))
            Text(place.previewBody).textRole(.subheadline).foregroundStyle(Color(.ink2))
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.paperRaised), in: .rect(cornerRadius: Radius.medium))
        .contrastEdge(always: true)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Ejemplo de aviso: \(Text(place.previewTitle)). \(Text(place.previewBody))", comment: "VoiceOver: the example notification's title and body"))
    }

    private func outcomeText(_ outcome: WatchNotifier.Outcome) -> LocalizedStringResource {
        switch outcome {
        case .scheduled:
            LocalizedStringResource("Te llegará en unos segundos.", comment: "Watch preview: the test notification is on its way")
        case .notAllowed:
            LocalizedStringResource("Las notificaciones están apagadas. Actívalas en Ajustes para recibir avisos.", comment: "Watch preview: notifications are not allowed")
        }
    }
}
