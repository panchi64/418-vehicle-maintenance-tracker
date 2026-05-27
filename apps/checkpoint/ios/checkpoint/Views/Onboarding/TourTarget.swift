//
//  TourTarget.swift
//  checkpoint
//
//  Checkpoint-specific onboarding tour identifiers. The anchor-publishing
//  mechanism itself (`SpotlightAnchorPreferenceKey`, `.spotlightAnchor(_:)`)
//  lives in DesignKit so other 418 apps can build their own guided overlays
//  on the same plumbing — this file just enumerates the four targets the
//  Checkpoint tour walks through and exposes a typed convenience.
//

import SwiftUI

enum TourTargetID: Hashable {
    case dashboardSpecs    // Step 0 — Home: QuickSpecsCard
    case vehicleHeader     // Step 1 — Home: VehicleHeader
    case servicesSearch    // Step 2 — Services: ServiceSearchField
    case costsHeadline     // Step 3 — Costs: CostHeadlineCard
}

extension View {
    /// Sugar for `.spotlightAnchor(_:active:)` typed to Checkpoint's tour
    /// targets. Pass `active: false` to skip publication when the tour is
    /// inactive — keeps the host view's identity stable across phase changes.
    func tourTarget(_ id: TourTargetID, active: Bool = true) -> some View {
        spotlightAnchor(id, active: active)
    }
}
