import SwiftUI

/// An ink vignette for a small moment (direction §1.1 "C · Papel y tinta"):
/// empty states and progression. Never on a screen with a postcard plate,
/// never in crisis. Increase Contrast gets the line-only rendition from the
/// asset catalog. Decorative, so VoiceOver skips it.
struct InkVignette: View {
    let image: ImageResource
    /// Its size at the default text size; it grows with Dynamic Type up to half again.
    var points: CGFloat = Size.vignette

    @Environment(\.theme) private var theme
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    var body: some View {
        if !theme.isCrisis {
            let side = points * min(scale, 1.5)
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: side, height: side)
                .accessibilityHidden(true)
        }
    }
}
