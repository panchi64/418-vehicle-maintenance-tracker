import CoreGraphics

/// The 4pt spacing ladder. Components scale these with `@ScaledMetric` where
/// the spacing sits between text.
nonisolated enum Spacing {
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 20
    static let s6: CGFloat = 24
    static let s7: CGFloat = 28
    static let s8: CGFloat = 32
    static let s10: CGFloat = 40
    static let s12: CGFloat = 48

    /// Screen side gutter on iPhone.
    static let gutter: CGFloat = s4
}

/// Continuous corner radii. Capsules are for glass chrome only; content uses 10–16.
nonisolated enum Radius {
    static let xs: CGFloat = 6
    static let small: CGFloat = 10
    static let medium: CGFloat = 12
    static let plate: CGFloat = 16
    static let menu: CGFloat = 22
    static let sheet: CGFloat = 34
}

/// Fixed geometry the information-design rules depend on.
nonisolated enum Size {
    /// Minimum tap target.
    static let target: CGFloat = 44
    /// Quick Report's one-tap verbs, usable at a red light.
    static let reportTarget: CGFloat = 56
    static let listPin: CGFloat = 28
    static let mapPin: CGFloat = 34
    static let control: CGFloat = 48
    static let plateStrip: CGFloat = 64
    static let plateStripWidth: CGFloat = 96
    static let plate: CGFloat = 168
    static let vignette: CGFloat = 120
    /// The pen line around every pin and polygon label.
    static let contour: CGFloat = 1.25
}
