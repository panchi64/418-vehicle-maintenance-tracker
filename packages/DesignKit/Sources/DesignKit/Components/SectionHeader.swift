import SwiftUI

public struct SectionHeader<Trailing: View>: View {
    let title: String
    let labelColor: Color
    let dividerColor: Color
    let dividerHeight: CGFloat
    let labelFont: Font
    let uppercased: Bool
    let trailing: Trailing

    /// - Parameter uppercased: `true` renders the terminal-style tracked caps
    ///   label; `false` renders the title as given (iOS 26 title-case headers).
    public init(
        title: String,
        labelColor: Color,
        dividerColor: Color,
        dividerHeight: CGFloat = 2,
        labelFont: Font = .caption.monospaced(),
        uppercased: Bool = true,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.labelColor = labelColor
        self.dividerColor = dividerColor
        self.dividerHeight = dividerHeight
        self.labelFont = labelFont
        self.uppercased = uppercased
        self.trailing = trailing()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(labelFont)
                    .foregroundStyle(labelColor)
                    .textCase(uppercased ? .uppercase : nil)
                    .tracking(uppercased ? 2 : 0)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                trailing
            }
            Rectangle()
                .fill(dividerColor)
                .frame(height: dividerHeight)
        }
    }
}
