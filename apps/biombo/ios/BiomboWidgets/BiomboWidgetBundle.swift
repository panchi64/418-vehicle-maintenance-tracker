import SwiftUI
import WidgetKit

/// Biombo's system surfaces (PRODUCT.md §11 "Other system surfaces",
/// Flows-SystemSurfaces): "Gasolina cerca", a watched place, and the
/// Controls for reporting. The gallery lists them in this order.
@main
struct BiomboWidgetBundle: WidgetBundle {
    var body: some Widget {
        GasWidget()
        WatchedPlaceWidget()
        ReportControl()
        NoPowerControl()
        PowerBackControl()
    }
}
