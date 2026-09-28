import Foundation

/// Home's side of Quick Report: the doors that open it, the long-press
/// reports on the map control, and sending, undoing and adding detail. It
/// derives the context once per render from the snapshot on screen and
/// hands `ReportSender` the stores that record the outcome.
struct HomeReporting {
    let store: HomeStore
    let flow: ReportFlow
    /// The snapshot on screen, with this device's contributions folded in.
    let snapshot: PlacesSnapshot
    let areas: [AreaStatus]
    let connection: ConnectionState
    let contributions: ContributionStore
    let device: DeviceStore

    private var builder: ReportContextBuilder {
        ReportContextBuilder(snapshot: snapshot, areas: areas, vantage: snapshot.vantage)
    }

    private var sender: ReportSender {
        ReportSender(contributions: contributions, device: device, snapshot: snapshot, areas: areas, connection: connection)
    }

    var input: QuickReportInput {
        let builder = builder
        return QuickReportInput(
            flow: flow,
            context: builder.context(for: store.reportFocus, chosen: flow.chosen),
            candidates: builder.candidates(for:),
            reportHere: reportHere,
            reportOnSelection: reportOnSelection,
            reportPrice: { placeID in
                reportOnSelection()
                flow.show(.price(placeID))
            },
            onSend: send,
            onDetail: addDetail
        )
    }

    /// The long press on Reportar aquí: the one-tap reports in reach where
    /// you stand, and where they land.
    var quickReports: QuickReports {
        let here = builder.context(for: .whereYouAre)
        return QuickReports(kinds: here.oneTap.filter { here.target(for: $0)?.isInReach == true }, title: here.title)
    }

    func reportHere() {
        store.reportHere()
        flow.begin()
    }

    private func reportOnSelection() {
        store.reportOnSelection()
        flow.begin()
    }

    /// One tap from the long press or a Control; a price still needs typing,
    /// so it opens on "¿A cuánto está?". With nothing of that kind in reach
    /// (a Control used far from any place), Quick Report opens instead.
    func quickReport(_ kind: ReportKind) {
        guard let target = builder.context(for: .whereYouAre).target(for: kind), target.isInReach else {
            reportHere()
            return
        }
        if kind.needsTyping {
            reportHere()
            flow.show(.price(target.place.id))
        } else {
            send(kind, nil, target, nil)
        }
    }

    func send(_ kind: ReportKind, _ value: ReportValue?, _ target: ReportTarget, _ photo: Data?) {
        let receipt = sender.send(kind, value: value, to: target, photo: photo)
        store.endReport()
        store.tier = .peek
        flow.sent(receipt)
    }

    /// "Añadir detalle" on the sent state reopens Quick Report on it.
    func openDetail() {
        flow.addDetail()
        store.reportHere()
    }

    func addDetail(_ value: ReportValue, _ receipt: ReportReceipt) {
        sender.addDetail(value, to: receipt)
        store.endReport()
    }

    func undo(_ receipt: ReportReceipt) {
        sender.undo(receipt)
        flow.dismissReceipt()
    }
}
