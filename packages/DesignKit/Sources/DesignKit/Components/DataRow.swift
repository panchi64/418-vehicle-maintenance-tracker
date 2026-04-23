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

    public var body: some View {
        HStack {
            Text(label)
                .font(labelFont)
                .foregroundStyle(labelColor)
                .textCase(.uppercase)
                .tracking(1)
            Spacer()
            Text(value)
                .font(valueFont)
                .foregroundStyle(valueColor)
        }
        .padding(padding)
    }
}
