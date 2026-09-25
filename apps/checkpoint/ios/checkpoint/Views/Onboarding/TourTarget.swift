//
//  TourTarget.swift
//  checkpoint
//
//  Checkpoint-specific onboarding tour targets, and how their frames reach
//  the tour overlay.
//
//  The targets used to publish anchors through DesignKit's
//  `SpotlightAnchorPreferenceKey`, collected by an `overlayPreferenceValue` at
//  the root. Preferences do not cross the system `TabView` / `NavigationStack`
//  (each tab is hosted separately), so under the native shell they never
//  arrived. Environment values do cross, so each target now writes its
//  window-space frame into a `TourSpotlightRegistry` the root injects, and the
//  root overlay converts those frames into its own space.
//
//  Every target is content, never system chrome: the navigation bar's title
//  menu, toolbar items, the search field and the tab bar expose no frames to
//  SwiftUI, so the steps that used to spotlight the custom header and search
//  field now spotlight the content that does the same job.
//

import SwiftUI

enum TourTargetID: Hashable {
    case homeNextUp          // Step 0 — Home: Next Up card
    case servicesStatusGroup // Step 1 — Services: first status group header
    case costsHeadline       // Step 2 — Costs: period total readout
}

/// Window-space frames of the tour targets currently on screen.
@Observable
@MainActor
final class TourSpotlightRegistry {
    private(set) var frames: [TourTargetID: CGRect] = [:]

    func setFrame(_ frame: CGRect?, for id: TourTargetID) {
        guard frames[id] != frame else { return }
        frames[id] = frame
    }
}

extension View {
    /// Marks this view as a tour spotlight target. Pass `active: false` to stop
    /// reporting when the tour is inactive; the modifier stays applied either
    /// way, so the host view's identity is stable across phase changes.
    func tourTarget(_ id: TourTargetID, active: Bool = true) -> some View {
        modifier(TourTargetModifier(id: id, active: active))
    }
}

private struct TourTargetModifier: ViewModifier {
    let id: TourTargetID
    let active: Bool

    @Environment(TourSpotlightRegistry.self) private var registry: TourSpotlightRegistry?

    /// Last measured frame. A tab switched away and back keeps its views, so
    /// no geometry change fires on return; this is re-reported on appear.
    @State private var frame: CGRect?

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect?.self) { proxy in
                active ? proxy.frame(in: .global) : nil
            } action: { newFrame in
                frame = newFrame
                registry?.setFrame(newFrame, for: id)
            }
            .onAppear {
                registry?.setFrame(frame, for: id)
            }
            // A tab that is not selected is not on screen; its stale frame
            // must not be spotlighted.
            .onDisappear {
                registry?.setFrame(nil, for: id)
            }
    }
}
