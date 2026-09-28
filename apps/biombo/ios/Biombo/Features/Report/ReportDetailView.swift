import SwiftUI

/// "Añadir detalle" (PRODUCT.md §4.2 fields): the one optional value a
/// report can carry — how long the line is, which carrier, which connector.
/// One tap adds it; there is no free text.
struct ReportDetailView: View {
    let receipt: ReportReceipt
    let onPick: (ReportValue) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(question)
                .textRole(.body)
                .foregroundStyle(Color(.ink))
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 0) {
                RowList(elements: choices, isInset: false) { choice in
                    Button { onPick(choice.value) } label: {
                        choice.title
                            .textRole(.headline)
                            .foregroundStyle(Color(.ink))
                            .frame(maxWidth: .infinity, minHeight: Size.reportTarget, alignment: .leading)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
            .insetGroup()
        }
    }

    private struct Choice {
        let title: Text
        let value: ReportValue
    }

    private var question: LocalizedStringResource {
        switch receipt.kind.detail {
        case .queueMinutes: LocalizedStringResource("¿Cuánto tarda la fila?", comment: "Add detail: how long the line is")
        case .carrier: LocalizedStringResource("¿Qué compañía?", comment: "Add detail: which cell carrier")
        case .connector: LocalizedStringResource("¿Qué conector?", comment: "Add detail: which charger connector")
        case nil: LocalizedStringResource("Añadir detalle", comment: "Add an optional detail to a report just sent")
        }
    }

    private var choices: [Choice] {
        switch receipt.kind.detail {
        case .queueMinutes:
            ReportDetailKind.queueChoices.map { minutes in
                Choice(title: Text("Unos \(minutes) min", comment: "Add detail: a line of about N minutes"), value: .queueMinutes(minutes))
            }
        case .carrier:
            Carrier.allCases.map { Choice(title: Text(verbatim: $0.displayName), value: .carrier($0)) }
        case .connector:
            Connector.allCases.map { Choice(title: Text(verbatim: $0.displayName), value: .connector($0)) }
        case nil:
            []
        }
    }
}
