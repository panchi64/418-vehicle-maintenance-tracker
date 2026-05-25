import SwiftUI

/// Isolated view so `NetworkMonitor.isOnline` changes invalidate only this
/// subtree instead of the whole `ContentView`.
struct OfflineBannerSlot: View {
    private let network = NetworkMonitor.shared

    var body: some View {
        if !network.isOnline {
            StatusBanner(status: .offline)
                .accessibilityIdentifier("status.offline")
        }
    }
}
