import SwiftUI

/// The round close control on in-sheet cards, at the full tap target.
struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        RoundButton(symbol: "xmark", label: Text("Cerrar", comment: "Close a card or panel"), action: action)
    }
}

/// Atrás, one step back in a flow (Quick Report, the first run).
struct BackButton: View {
    let action: () -> Void

    var body: some View {
        RoundButton(symbol: "chevron.backward", label: Text("Atrás", comment: "Go back one step"), action: action)
    }
}

/// A round glyph button at the full tap target; the large content viewer
/// shows it bigger at the accessibility sizes.
struct RoundButton: View {
    let symbol: String
    let label: Text
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RoundGlyph(symbol: symbol)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityShowsLargeContentViewer {
            Label { label } icon: { Image(systemName: symbol) }
        }
    }
}

/// A glyph in a filled circle at the full tap target (Cerrar, Atrás, •••).
/// The glyph stops growing at the largest standard size so it stays inside
/// its circle.
struct RoundGlyph: View {
    let symbol: String

    var body: some View {
        Image(systemName: symbol)
            .font(.body.weight(.semibold))
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .foregroundStyle(Color(.ink2))
            .frame(width: Size.target, height: Size.target)
            .background(Color(.fill), in: .circle)
    }
}
