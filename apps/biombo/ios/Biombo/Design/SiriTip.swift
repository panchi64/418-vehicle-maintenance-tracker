import AppIntents
import SwiftUI

/// Apple's Siri tip for one App Shortcut, dismissed for good (PRODUCT.md
/// §11: tips on Quick Report and the watch list). Hidden in crisis, when
/// the screen keeps to what's needed. `SiriTipView` shows nothing for an
/// intent that isn't in `BiomboShortcuts`.
struct SiriTip<Intent: AppIntent>: View {
    let intent: Intent

    @AppStorage private var isVisible: Bool
    @Environment(\.theme) private var theme

    init(intent: Intent, storageKey: String) {
        self.intent = intent
        _isVisible = AppStorage(wrappedValue: true, storageKey)
    }

    var body: some View {
        if !theme.isCrisis {
            SiriTipView(intent: intent, isVisible: $isVisible)
                .siriTipViewStyle(.automatic)
        }
    }
}
