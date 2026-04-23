import SwiftUI

public struct SectionHeader<Trailing: View>: View {
    let title: String
    let labelColor: Color
    let dividerColor: Color
    let dividerHeight: CGFloat
    let labelFont: Font
    let trailing: Trailing

    public init(
        title: String,
        labelColor: Color,
        dividerColor: Color,
        dividerHeight: CGFloat = 2,
        labelFont: Font = .caption.monospaced(),
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.labelColor = labelColor
        self.dividerColor = dividerColor
        self.dividerHeight = dividerHeight
        self.labelFont = labelFont
        self.trailing = trailing()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(labelFont)
                    .foregroundStyle(labelColor)
                    .textCase(.uppercase)
                    .tracking(2)
                Spacer()
                trailing
            }
            Rectangle()
                .fill(dividerColor)
                .frame(height: dividerHeight)
        }
    }
}
