import SwiftUI
import SwiftData
import DesignKit

@main
struct BiomboApp: App {
    @State private var appState = BiomboAppState()
    @Environment(\.scenePhase) private var scenePhase
    private let theme = AestheticBrutalistTheme.shared
    private let locationService = LocationService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .designKitTheme(theme)
                .preferredColorScheme(theme.colorScheme)
                .tint(theme.accent)
        }
        .modelContainer(for: [CachedFuelPrice.self, PriceHistoryPoint.self, CachedBrand.self])
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                locationService.startUpdatingLocation()
            case .background, .inactive:
                locationService.stopUpdatingLocation()
            @unknown default:
                break
            }
        }
    }
}
