import SwiftUI

/// Caps content at `DKSpacing.readableWidth` and centers it in whatever width
/// is offered. Narrower than the cap (every iPhone, compact width) it is a
/// no-op: the content already fills the offered width.
///
/// Apply it to the content *inside* a `ScrollView`, after its screen padding —
/// never to the scroll view or the screen background, which should still span
/// the full width (and keep the scroll indicator at the screen edge).
public struct ReadableContentWidthModifier: ViewModifier {
    let maxWidth: CGFloat

    public init(maxWidth: CGFloat = DKSpacing.readableWidth) {
        self.maxWidth = maxWidth
    }

    public func body(content: Content) -> some View {
        content
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}

public extension EnvironmentValues {
    /// Extra horizontal inset, per side, that centers a
    /// `DKSpacing.readableWidth` column inside the enclosing `List`. Set by
    /// `readableListMargins()`; 0 everywhere else. Rows and section headers
    /// add it to their `listRowInsets`.
    @Entry var readableListInset: CGFloat = 0
}

/// The same cap for a `List`, whose rows can't be wrapped in a frame. The
/// list keeps its full width (background, scroll indicator, swipe area); it
/// publishes `readableListInset` for its rows to add to their insets. (Not
/// `contentMargins`: that moves rows but leaves section headers behind.)
/// A plain `List` does not follow a readable content guide on its own. The
/// inset is 0 whenever the list is narrower than the cap, so compact width is
/// unchanged.
public struct ReadableListMarginsModifier: ViewModifier {
    let maxWidth: CGFloat
    @State private var inset: CGFloat = 0

    public init(maxWidth: CGFloat = DKSpacing.readableWidth) {
        self.maxWidth = maxWidth
    }

    public func body(content: Content) -> some View {
        content
            .environment(\.readableListInset, inset)
            .onGeometryChange(for: CGFloat.self) { proxy in
                max(0, (proxy.size.width - maxWidth) / 2).rounded()
            } action: { newInset in
                inset = newInset
            }
    }
}

public extension View {
    func readableContentWidth(_ maxWidth: CGFloat = DKSpacing.readableWidth) -> some View {
        modifier(ReadableContentWidthModifier(maxWidth: maxWidth))
    }

    func readableListMargins(_ maxWidth: CGFloat = DKSpacing.readableWidth) -> some View {
        modifier(ReadableListMarginsModifier(maxWidth: maxWidth))
    }
}
