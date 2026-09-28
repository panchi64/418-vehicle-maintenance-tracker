import SwiftUI

/// Reporting a price (PRODUCT.md §4.2, §6.1): the grade, the amount in the
/// user's unit, and an optional photo of the sign. Reading the sign fills the
/// price for the user to confirm; the photo leaves the device with no
/// location and stays private until the price is confirmed (§5, §13).
struct PriceReportView: View {
    let target: ReportTarget
    let onSend: (FuelPrice, Data?) -> Void

    @State private var grade: FuelGrade = .regular
    @State private var amount = ""
    @State private var photo: Data?
    @State private var readResult: ReadResult?
    @State private var isImplausible = false
    @FocusState private var isAmountFocused: Bool
    @Environment(\.priceUnit) private var unit
    /// nil until signs can be read: then a photo is evidence only, with no note.
    @Environment(\.priceSignReader) private var reader

    private enum ReadResult { case read, unread }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("En \(target.place.displayName)", comment: "Price report: the station the price is for")
                .textRole(.body)
                .foregroundStyle(Color(.ink2))
            Picker(selection: $grade) {
                ForEach(FuelGrade.allCases, id: \.self) { grade in
                    Text(grade.capitalizedTitle).tag(grade)
                }
            } label: {
                Text("Tipo", comment: "Price report: the fuel grade picker")
            }
            .pickerStyle(.segmented)
            amountField
            if isImplausible {
                Label {
                    Text("Ese precio no parece de bomba. Revísalo.", comment: "Price report: the typed price is not a plausible pump price")
                } icon: {
                    Image(systemName: "exclamationmark.circle").accessibilityHidden(true)
                }
                .textRole(.footnote)
                .foregroundStyle(Color(.statusCritical))
            }
            PriceSignPhotoField(photo: $photo, readNote: readNote)
            PrimaryButton(title: LocalizedStringResource("Enviar precio", comment: "Price report: send the typed price"), action: send)
                .disabled(amount.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        // Keyed by the photo, so a reading never lands on a removed or replaced one.
        .task(id: photo) {
            readResult = nil
            guard let photo, let reader else { return }
            await read(photo, with: reader)
        }
        .onChange(of: amount) { isImplausible = false }
    }

    private var amountField: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s1) {
            Text(verbatim: "$")
                .textRole(.hero)
                .foregroundStyle(Color(.ink2))
                .accessibilityHidden(true)
            TextField(text: $amount, prompt: Text(verbatim: unit == .litre ? "0.99" : "3.75")) {
                Text("Precio", comment: "Answer word: a pump price was reported")
            }
            .textRole(.hero)
            .keyboardType(.decimalPad)
            .focused($isAmountFocused)
            .fixedSize(horizontal: false, vertical: true)
            Text(unit.heroSuffix(grade))
                .textRole(.subheadline)
                .foregroundStyle(Color(.ink2))
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.vertical, Spacing.s2)
        .background(Color(.paperRaised), in: .rect(cornerRadius: Radius.medium))
        .contrastEdge()
        .onAppear { isAmountFocused = true }
    }

    private var readNote: LocalizedStringResource? {
        switch readResult {
        case .read: LocalizedStringResource("Leímos el precio del letrero. Revísalo antes de enviar.", comment: "Price report: the sign was read; check the price")
        case .unread: LocalizedStringResource("No pudimos leer el letrero. Escribe el precio.", comment: "Price report: the sign could not be read; type the price")
        case nil: nil
        }
    }

    /// The sign fills the field only when it read this grade and nothing was typed.
    private func read(_ photo: Data, with reader: any PriceSignReading) async {
        let prices = await reader.prices(in: photo)
        guard !Task.isCancelled else { return }
        guard let centsPerLitre = prices[grade] else {
            readResult = .unread
            return
        }
        readResult = .read
        if amount.isEmpty {
            amount = PriceEntry.text(for: FuelPrice(grade: grade, centsPerLitre: centsPerLitre), unit: unit)
        }
    }

    private func send() {
        guard let price = PriceEntry.parse(amount, grade: grade, unit: unit), PriceEntry.isPlausible(price) else {
            isImplausible = true
            return
        }
        onSend(price, photo)
    }
}
