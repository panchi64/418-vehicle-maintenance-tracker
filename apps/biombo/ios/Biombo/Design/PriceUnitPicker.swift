import SwiftUI

/// Por litro or por galón (PRODUCT.md §2): a setting of its own, apart from
/// language. Until the user picks, it shows the region's default. Inline in
/// Ajustes, segmented on the visitor's card.
struct PriceUnitPicker: View {
    var isSegmented = false

    @AppStorage(PriceUnit.storageKey) private var storedUnit: PriceUnit?
    @Environment(\.priceUnit) private var unit

    var body: some View {
        let picker = Picker(selection: Binding(get: { unit }, set: { storedUnit = $0 })) {
            ForEach(PriceUnit.allCases, id: \.self) { Text($0.title).tag($0) }
        } label: {
            Text("Precios de gasolina", comment: "Settings: the unit gas prices are shown in")
        }
        if isSegmented {
            picker.pickerStyle(.segmented)
        } else {
            picker.pickerStyle(.inline).labelsHidden()
        }
    }
}
