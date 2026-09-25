import SwiftUI

public struct DataRow: View {
    let label: String
    let value: String
    let labelColor: Color
    let valueColor: Color
    let labelFont: Font
    let valueFont: Font
    let padding: CGFloat

    public init(
        label: String,
        value: String,
        labelColor: Color,
        valueColor: Color,
        labelFont: Font = .caption.monospaced(),
        valueFont: Font = .body.monospaced(),
        padding: CGFloat = 0
    ) {
        self.label = label
        self.value = value
        self.labelColor = labelColor
        self.valueColor = valueColor
        self.labelFont = labelFont
        self.valueFont = valueFont
        self.padding = padding
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public var body: some View {
        // At accessibility sizes a label and value side by side truncate each
        // other, so the row becomes a leading-aligned column.
        let stacked = dynamicTypeSize.isAccessibilitySize
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout())

        layout {
            Text(label)
                .font(labelFont)
                .foregroundStyle(labelColor)
                .textCase(.uppercase)
                .tracking(1)
            if !stacked {
                Spacer()
            }
            Text(value)
                .font(valueFont)
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(padding)
        .accessibilityElement(children: .combine)
    }
}
