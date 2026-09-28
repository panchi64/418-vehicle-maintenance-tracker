import AppIntents
import SwiftUI
import WidgetKit

// Controls (Control Center, Lock Screen, Action button; PRODUCT.md §10, §11):
// Reportar, "No hay luz aquí" and "Volvió la luz". Each opens Biombo through
// `OpenBiomboScreenIntent`, since a location fix without the app is
// unverified (open decision 16). "No hay luz aquí" and "Volvió la luz" then
// send at once where you stand, with Deshacer; Reportar opens Quick Report.
// Buttons, not toggles: there is no state to show.

struct ReportControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        ScreenControl.configuration(
            kind: "com.418-studio.biombo.control.report",
            screen: .report,
            title: LocalizedStringResource("Reportar", comment: "Control: open Quick Report"),
            systemImage: "plus.bubble",
            description: LocalizedStringResource("Abre Biombo en Reportar, donde estás.", comment: "Control description: open Quick Report")
        )
    }
}

struct NoPowerControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        ScreenControl.configuration(
            kind: "com.418-studio.biombo.control.noPower",
            screen: .noPower,
            title: LocalizedStringResource("No hay luz aquí", comment: "Control: report no power where you are"),
            systemImage: "bolt.slash.fill",
            description: LocalizedStringResource("Avisa que no hay luz donde estás, con Deshacer.", comment: "Control description: report no power, with undo")
        )
    }
}

struct PowerBackControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        ScreenControl.configuration(
            kind: "com.418-studio.biombo.control.powerBack",
            screen: .powerBack,
            title: LocalizedStringResource("Volvió la luz", comment: "Control: report power is back where you are"),
            systemImage: "bolt.fill",
            description: LocalizedStringResource("Avisa que volvió la luz donde estás, con Deshacer.", comment: "Control description: report power back, with undo")
        )
    }
}

/// The one shape the three Controls share; each differs only in its screen,
/// words and symbol. Main actor, like the `ControlWidget.body` that calls it.
@MainActor
private enum ScreenControl {
    static func configuration(
        kind: String,
        screen: BiomboScreen,
        title: LocalizedStringResource,
        systemImage: String,
        description: LocalizedStringResource
    ) -> some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: kind) {
            ControlWidgetButton(action: OpenBiomboScreenIntent(target: screen)) {
                Label {
                    Text(title)
                } icon: {
                    Image(systemName: systemImage)
                }
            }
        }
        .displayName(title)
        .description(description)
    }
}
