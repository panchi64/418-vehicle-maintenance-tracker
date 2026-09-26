//
//  ScreenSiriTip.swift
//  checkpoint
//
//  A screen's one Siri tip: the App Shortcut phrase for doing what the
//  screen does by voice ("What's due on my car in Checkpoint"). Apple's
//  `SiriTipView`, which shows the phrase from `CheckpointShortcuts` in the
//  user's language and has its own dismiss button; dismissing it hides it on
//  that screen for good.
//
//  Placement is resolved in tools/sketchpad (`SiriTip`): last in the
//  scroll, outside every section, so it never competes for a section's
//  primary — it is the least important thing on the screen. Callers show it
//  only once the screen has something the phrase acts on. It is system
//  chrome (F15), so it keeps the system's look rather than the theme's.
//
//  `SiriTipView` shows nothing for an intent that isn't an App Shortcut, so
//  every intent passed here must stay in `CheckpointShortcuts`.
//

import AppIntents
import SwiftUI

/// The screens that carry a tip, one each. Raw values key the dismissal —
/// never rename one.
enum SiriTipScreen: String {
    case home
    case mileageUpdate
    case costs
    case documents

    var dismissedKey: String { "siriTip.dismissed.\(rawValue)" }
}

struct ScreenSiriTip<Intent: AppIntent>: View {
    let intent: Intent
    @AppStorage private var isDismissed: Bool

    init(_ screen: SiriTipScreen, intent: Intent) {
        self.intent = intent
        _isDismissed = AppStorage(wrappedValue: false, screen.dismissedKey)
    }

    var body: some View {
        if !isDismissed {
            SiriTipView(intent: intent, isVisible: Binding(
                get: { !isDismissed },
                set: { isDismissed = !$0 }
            ))
            .siriTipViewStyle(.automatic)
        }
    }
}
