import SwiftUI
import UIKit

/// Presents "Abrir en…" for a destination: straight to the only maps app
/// installed, or a dialog offering only the installed ones (Flows-EVAddStop).
/// Probing installed apps is a side effect, so it lives here in the view layer.
struct OpenInMaps: ViewModifier {
    @Binding var isPresented: Bool
    let destination: GeoPoint
    let name: String

    @Environment(\.openURL) private var openURL
    @State private var choices: [MapsApp] = []
    @State private var isChoosing = false

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _, requested in
                guard requested else { return }
                isPresented = false
                switch MapsHandOff(installed: installedApps()) {
                case .open(let app):
                    openURL(app.directionsURL(to: destination))
                case .choose(let apps):
                    choices = apps
                    isChoosing = true
                }
            }
            .confirmationDialog(Text("Abrir en", comment: "Title of the maps-app chooser"), isPresented: $isChoosing, titleVisibility: .visible) {
                ForEach(choices, id: \.self) { app in
                    Button { openURL(app.directionsURL(to: destination)) } label: { app.displayName }
                }
            } message: {
                Text(verbatim: name)
            }
    }

    private func installedApps() -> Set<MapsApp> {
        Set(MapsApp.allCases.filter { app in
            guard let probe = app.probeURL else { return true }
            return UIApplication.shared.canOpenURL(probe)
        })
    }
}

extension View {
    func openInMaps(isPresented: Binding<Bool>, destination: GeoPoint, name: String) -> some View {
        modifier(OpenInMaps(isPresented: isPresented, destination: destination, name: name))
    }
}

extension MapsApp {
    /// App names are proper nouns except Apple's, which iOS calls "Mapas" in Spanish.
    var displayName: Text {
        switch self {
        case .appleMaps: Text("Mapas", comment: "Apple Maps, as iOS names it")
        case .googleMaps: Text(verbatim: "Google Maps")
        case .waze: Text(verbatim: "Waze")
        }
    }
}
