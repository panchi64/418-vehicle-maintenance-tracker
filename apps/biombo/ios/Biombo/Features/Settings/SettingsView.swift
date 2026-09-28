import AppIntents
import SwiftUI
import UIKit

/// Ajustes. Units are a setting separate from language (PRODUCT.md §2):
/// litres by default in Puerto Rico, gallons for a US mainland region,
/// until the user picks. Language follows the system, per app. Then the
/// map's ground, notifications, Siri and "Borrar mis datos" (§13).
struct SettingsView: View {
    /// "Borrar mis datos", confirmed.
    let onErase: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Group { sections }
                    // Paper like every other screen, not the system's grey and white.
                    .listRowBackground(Color(.paperRaised))
            }
            .scrollContentBackground(.hidden)
            .background(Color(.paperSheet))
            .navigationTitle(Text("Ajustes", comment: "Settings screen title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: { Text("Listo", comment: "Done: close this screen") }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private var sections: some View {
        Section {
            PriceUnitPicker()
        } header: {
            Text("Precios de gasolina", comment: "Settings: the unit gas prices are shown in")
        } footer: {
            Text("DACO publica por litro. Biombo convierte antes de redondear.", comment: "Settings footer: prices are stored per litre and converted before rounding")
        }
        language
        Section {
            MapGroundPicker(isCrisis: theme.isCrisis, showsLabel: false)
        } header: {
            Text("Mapa", comment: "Capas footer: the map ground style")
        }
        NotificationSettingsSection()
        Section {
            ShortcutsLink()
        } header: {
            Text("Siri", comment: "Settings section: Siri and Shortcuts")
        } footer: {
            Text("Di «Reporta en Biombo que no hay luz» o «Pregúntale a Biombo si hay luz». Funciona sin Apple Intelligence.", comment: "Settings footer: example Siri phrases, and that they work on every iPhone")
        }
        DataSettingsSection(onErase: onErase)
        #if DEBUG
        SampleSection()
        #endif
    }

    /// Biombo follows the iPhone's language; Ajustes › Biombo › Idioma sets
    /// it for Biombo alone. Units stay a separate choice.
    private var language: some View {
        Section {
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            } label: {
                LabeledContent {
                    Image(systemName: "arrow.up.forward.app")
                        .accessibilityHidden(true)
                } label: {
                    Text(languageName)
                        .foregroundStyle(Color(.ink))
                }
                .frame(minHeight: Size.target)
            }
            .accessibilityHint(Text("Abre Ajustes para cambiar el idioma de Biombo", comment: "VoiceOver hint: the language row opens the system Settings"))
        } header: {
            Text("Idioma", comment: "Settings section: the app's language")
        } footer: {
            Text("Biombo sigue el idioma de tu iPhone. Para cambiarlo solo aquí, ve a Ajustes › Biombo › Idioma.", comment: "Settings footer: how to change the language for Biombo alone")
        }
    }

    private var languageName: String {
        let code = locale.language.languageCode?.identifier ?? "es"
        return (locale.localizedString(forLanguageCode: code) ?? code).capitalized(with: locale)
    }
}
