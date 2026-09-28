import SwiftUI

/// A big one-tap row led by a map pin silhouette (direction N10, §3.6):
/// Quick Report's verbs, its layer list, Cambiar's places and an owner's
/// status. 56pt tall so it works at a red light; the trailing mark says
/// what the tap does. Wraps at accessibility sizes.
struct PinChoiceRow: View {
    enum Accessory {
        case none
        /// Leads somewhere else (another step).
        case forward
        /// The chosen option.
        case selected
    }

    /// The pin's layer; nil for a row about no layer in particular, which
    /// gets a plain round mark.
    let layer: Layer?
    var glyph: String?
    let title: Text
    var subtitle: Text?
    var accessory: Accessory = .none
    /// Greyed like a disabled row, but still tappable (it leads to why).
    var isMuted = false
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @ScaledMetric(relativeTo: .body) private var pinSize = Size.listPin

    private var isGreyed: Bool { !isEnabled || isMuted }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.s3) {
                pin
                    .opacity(isGreyed ? 0.5 : 1)
                VStack(alignment: .leading, spacing: 2) {
                    title
                        .textRole(.headline)
                        .foregroundStyle(Color(isGreyed ? .ink2 : .ink))
                    if let subtitle {
                        subtitle
                            .textRole(.footnote)
                            .foregroundStyle(Color(.ink2))
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Spacing.s2)
                accessoryMark
            }
            .padding(.vertical, Spacing.s2)
            .frame(maxWidth: .infinity, minHeight: Size.reportTarget, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(accessory == .selected ? .isSelected : [])
    }

    @ViewBuilder
    private var pin: some View {
        if let layer {
            LayerPin(layer: layer, glyph: glyph, size: pinSize)
        } else {
            ZStack {
                Circle().fill(Color(.fill))
                Circle().strokeBorder(Color(.ink3), lineWidth: Size.contour)
                Image(systemName: glyph ?? "ellipsis")
                    .font(.system(size: pinSize * 0.38, weight: .bold))
                    .foregroundStyle(Color(.ink2))
            }
            .frame(width: pinSize * 0.8, height: pinSize * 0.8)
            .frame(width: pinSize, height: pinSize)
            .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var accessoryMark: some View {
        switch accessory {
        case .none:
            EmptyView()
        case .forward:
            Image(systemName: "chevron.forward")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(.ink3))
                .accessibilityHidden(true)
        case .selected:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
        }
    }
}
