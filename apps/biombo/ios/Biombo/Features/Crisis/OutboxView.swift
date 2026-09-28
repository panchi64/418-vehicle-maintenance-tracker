import SwiftUI

/// "Sin conexión" / "Señal débil" (PRODUCT.md §4.6, Crisis-Offline): how old
/// the data on screen is, then the reports waiting for signal. Reports older
/// than a day ask before they go: send anyway, or discard.
struct OutboxView: View {
    let connection: ConnectionState

    @Environment(DeviceStore.self) private var device
    @Environment(ContributionStore.self) private var contributions
    @Environment(\.locale) private var locale

    var body: some View {
        let pending = device.outbox.pending(now: connection.now)
        let overdue = device.outbox.overdue(now: connection.now)
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s8) {
                Text(connection.lastSeenSentence(locale: locale))
                    .textRole(.answerSmall)
                    .foregroundStyle(Color(.ink))
                    .fixedSize(horizontal: false, vertical: true)
                if pending.isEmpty && overdue.isEmpty {
                    Text("No tienes reportes esperando.", comment: "Outbox: nothing queued")
                        .textRole(.body)
                        .foregroundStyle(Color(.ink2))
                }
                if !pending.isEmpty {
                    SectionGroup(
                        title: LocalizedStringResource("Tus reportes en cola", comment: "Outbox section: reports waiting for signal"),
                        aside: connection.status == .weak
                            ? LocalizedStringResource("Enviando", comment: "Outbox aside: reports are being sent")
                            : LocalizedStringResource("Se enviarán cuando haya señal", comment: "Outbox aside: reports go out when signal returns")
                    ) {
                        RowList(elements: pending) { item in
                            row(item, status: Text("En cola", comment: "Outbox row: the report is queued"))
                        }
                    }
                }
                if !overdue.isEmpty {
                    SectionGroup(
                        title: LocalizedStringResource("Llevan más de un día", comment: "Outbox section: queued reports older than a day"),
                        aside: LocalizedStringResource("¿Enviarlos?", comment: "Outbox aside: ask whether to send old reports")
                    ) {
                        RowList(elements: overdue) { item in
                            VStack(alignment: .leading, spacing: Spacing.s2) {
                                row(item, status: nil)
                                HStack(spacing: Spacing.s2) {
                                    Button { device.send(item.id) } label: {
                                        Text("Enviar igual", comment: "Outbox: send an old report anyway").frame(maxWidth: .infinity, minHeight: Size.target)
                                    }
                                    .buttonStyle(.bordered)
                                    Button(role: .destructive) { discard(item) } label: {
                                        Text("Descartar", comment: "Outbox: discard an old report").frame(maxWidth: .infinity, minHeight: Size.target)
                                    }
                                    .buttonStyle(.bordered)
                                }
                                .textRole(.subheadline)
                            }
                            .padding(.bottom, Spacing.s2)
                        }
                    }
                    Text("Se juzgan por la hora en que los hiciste: si ya pasó su tiempo, solo quedan en el historial.", comment: "Outbox footer: late reports are judged by capture time")
                        .textRole(.footnote)
                        .foregroundStyle(Color(.ink3))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, Spacing.gutter)
            .padding(.vertical, Spacing.s4)
        }
        .navigationTitle(Text(connection.title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    /// Descartar: gone from the outbox and from Tu aporte, as if never made.
    private func discard(_ item: QueuedReport) {
        device.discard(item.id)
        contributions.undo(item.id)
    }

    private func row(_ item: QueuedReport, status: Text?) -> some View {
        HStack(spacing: Spacing.s3) {
            LayerPin(layer: item.kind.layer, glyph: item.kind.glyph, size: Size.listPin)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.kind.word).textRole(.body).foregroundStyle(Color(.ink))
                Text(item.whereAndWhen(now: connection.now, locale: locale)).textRole(.footnote).foregroundStyle(Color(.ink2))
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Spacing.s2)
            if let status {
                Label { status } icon: { Image(systemName: "tray.and.arrow.up").accessibilityHidden(true) }
                    .textRole(.footnote)
                    .foregroundStyle(Color(.ink3))
            }
        }
        .padding(.vertical, Spacing.s2)
        .frame(minHeight: Size.target)
        .accessibilityElement(children: .combine)
    }
}
