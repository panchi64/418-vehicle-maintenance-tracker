import Foundation

/// One charger port and what the newest current report about that connector
/// says (PRODUCT.md §6.7 "Full: connectors, per-connector status").
nonisolated struct PortStatus: Hashable, Sendable {
    let port: ChargerPort
    /// nil when nobody reported this connector recently.
    let status: ReportKind?

    /// `evidence` is the resolver's current reports on the place, newest first,
    /// so the ports agree with the answer on what is current.
    static func statuses(for place: Place, evidence: [PlaceAnswer]) -> [PortStatus] {
        place.ports.map { port in
            PortStatus(port: port, status: evidence.first { $0.lead.connector == port.connector }?.kind)
        }
    }
}
