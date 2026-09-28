import SwiftUI
import WidgetKit

extension View {
    /// Writes the widgets' snapshot to the App Group whenever what they show
    /// changes, and asks WidgetKit to redraw. The widgets never load places
    /// themselves.
    func widgetPublishing(digest: HomeDigest, watchOverview: WatchOverview) -> some View {
        modifier(WidgetPublishing(digest: digest, watchOverview: watchOverview))
    }
}

private struct WidgetPublishing: ViewModifier {
    let digest: HomeDigest
    let watchOverview: WatchOverview

    @Environment(\.priceUnit) private var unit
    @Environment(\.locale) private var locale

    /// Everything the widgets show; a change here is a new snapshot.
    private struct Shown: Hashable {
        let overview: WatchOverview
        let gas: GasPick?
        let isCrisis: Bool
        let unit: PriceUnit
        let locale: Locale
    }

    func body(content: Content) -> some View {
        let shown = Shown(overview: watchOverview, gas: GasPick.make(from: digest), isCrisis: digest.isCrisis, unit: unit, locale: locale)
        content.onChange(of: shown, initial: true) { _, shown in
            publish(shown)
        }
    }

    private func publish(_ shown: Shown) {
        let snapshot = WidgetSnapshotMaker(unit: shown.unit, locale: shown.locale)
            .make(digest: digest, overview: shown.overview, gas: shown.gas, writtenAt: Date())
        snapshot.save(to: SharedContainer.defaults)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
