import SwiftUI

/// What the home sheet pushes: a whole section, a selection's depth,
/// "Gasolina y planta", why crisis mode is on, or the outbox.
struct SheetDestination: View {
    let route: SheetRoute
    let digest: HomeDigest
    let snapshot: PlacesSnapshot
    let detail: PlaceDetail?
    let connection: ConnectionState
    let onPick: (NearbyItem) -> Void
    let onReport: () -> Void

    var body: some View {
        switch route {
        case .section(let kind):
            if let section = digest.nearby.section(kind) {
                SectionListView(section: section, dacoRange: digest.nearby.dacoRange, now: digest.now, onPick: onPick)
            }
        case .depth:
            if let detail {
                PlaceDepthView(detail: detail)
            }
        case .availability:
            FuelAvailabilityView(availability: digest.availability, isCrisis: digest.isCrisis, now: digest.now, onPick: onPick, onReport: onReport)
        case .crisis:
            CrisisInfoView(crisis: snapshot.crisis, now: digest.now)
        case .outbox:
            OutboxView(connection: connection)
        }
    }
}
