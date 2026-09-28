import SwiftUI

/// Ajustes › Tus datos (PRODUCT.md §13): what lives on this iPhone, and
/// "Borrar mis datos", which asks once and says what goes. Erasing brings
/// the first run back in place of home, so the presenter closes Ajustes
/// first and erases once it is gone.
struct DataSettingsSection: View {
    let onErase: () -> Void

    @State private var isConfirming = false

    var body: some View {
        Section {
            Button(role: .destructive) {
                isConfirming = true
            } label: {
                Label {
                    Text("Borrar mis datos", comment: "Settings: erase everything this device keeps")
                } icon: {
                    Image(systemName: "trash").accessibilityHidden(true)
                }
                .foregroundStyle(Color(.statusCritical))
                .frame(minHeight: Size.target)
            }
            .confirmationDialog(
                Text("¿Borrar tus datos de este iPhone?", comment: "Erase confirmation title"),
                isPresented: $isConfirming,
                titleVisibility: .visible
            ) {
                Button(role: .destructive, action: onErase) {
                    Text("Borrar mis datos", comment: "Settings: erase everything this device keeps")
                }
            } message: {
                Text("Se borran los lugares que vigilas, los reportes sin enviar, tu aporte y tus ajustes. Lo que ya enviaste queda en el mapa sin nada que lo una a ti.", comment: "Erase confirmation: what goes, and that sent reports stay unlinked")
            }
        } header: {
            Text("Tus datos", comment: "Settings section: this device's data")
        } footer: {
            Text("Biombo no pide cuenta. Lo que vigilas y lo que reportas vive en este iPhone.", comment: "Settings footer: no account; data lives on the device")
        }
    }
}
