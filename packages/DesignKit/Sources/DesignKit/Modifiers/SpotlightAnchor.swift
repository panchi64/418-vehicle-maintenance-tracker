import SwiftUI

/// Shared anchor-publishing pattern for app-defined "spotlight" overlays
/// (e.g. onboarding tours, focus modes, feature hints). Components mark
/// themselves with `.spotlightAnchor(MyID.something)` using any `Hashable`
/// identifier. A coordinating overlay collects all published anchors via
/// `.overlayPreferenceValue(SpotlightAnchorPreferenceKey.self)` and resolves
/// the bounds it cares about with `anchors.anchor(myID)`.
///
/// This is intentionally agnostic to which step / scheme an app is running —
/// each app keeps its own ID enum and overlay UI; only the wiring is shared.
public struct SpotlightAnchorPreferenceKey: PreferenceKey {
    public static let defaultValue: [AnyHashable: Anchor<CGRect>] = [:]

    public static func reduce(
        value: inout [AnyHashable: Anchor<CGRect>],
        nextValue: () -> [AnyHashable: Anchor<CGRect>]
    ) {
        value.merge(nextValue()) { _, new in new }
    }
}

public extension View {
    /// Publishes the view's bounds under the given identifier so a
    /// coordinating overlay can spotlight this exact element.
    ///
    /// Pass `active: false` to suppress publication without changing the
    /// view's identity — useful for gating anchor reporting on whether the
    /// owning feature (e.g. a tour) is actually running. When inactive, an
    /// empty dictionary is published, which the preference reducer treats
    /// as a no-op.
    func spotlightAnchor<ID: Hashable>(_ id: ID, active: Bool = true) -> some View {
        anchorPreference(key: SpotlightAnchorPreferenceKey.self, value: .bounds) { anchor in
            active ? [AnyHashable(id): anchor] : [:]
        }
    }
}

public extension Dictionary where Key == AnyHashable, Value == Anchor<CGRect> {
    /// Typed lookup convenience — equivalent to `self[AnyHashable(id)]`.
    func anchor<ID: Hashable>(_ id: ID) -> Anchor<CGRect>? {
        self[AnyHashable(id)]
    }
}
