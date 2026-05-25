//
//  DevEntitlements.swift
//  checkpoint
//
//  Single source of truth for dev-build entitlement overrides.
//  StoreManager and ThemeManager both consult this so the "unlock everything
//  in dev" intent has one switch, not three.
//

import Foundation

enum DevEntitlements {
    /// When true, the app behaves as if the user owns every entitlement:
    /// Pro is active, every theme is owned, every gated flow is unlocked.
    ///
    /// Flip to `false` (in DEBUG) to exercise the real free-tier paths —
    /// useful for capturing paywall screenshots or testing gating flows.
    /// In Release builds this is always `false`.
    #if DEBUG
    static let unlockAll = true
    #else
    static let unlockAll = false
    #endif
}
