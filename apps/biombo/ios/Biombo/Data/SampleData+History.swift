import Foundation

/// SAMPLE DATA — invented history behind the per-station trends and charger
/// reliability. Nobody made these reports; they only feed trends (§6.1, §6.7).
nonisolated extension SampleData {
    /// Puma Los Filtros drifts down from $1.03 over 30 days, with gaps on days
    /// nobody reported; Gulf Bairoa holds steady for three weeks.
    nonisolated static let history: [Report] = {
        let puma: [(days: Int, cents: Double)] = [
            (30, 103), (28, 103), (27, 102.6), (25, 102.4), (23, 102), (21, 101.8), (20, 101.5),
            (18, 101.4), (16, 101), (14, 100.8), (13, 100.4), (11, 100.2), (9, 100), (7, 99.8),
            (6, 99.6), (4, 99.4), (3, 99.2), (2, 99.1),
        ]
        let gulf: [(days: Int, cents: Double)] = [
            (21, 97.2), (18, 97), (15, 97.4), (12, 97), (9, 96.8), (6, 97.1), (3, 97),
        ]
        func reports(_ series: [(days: Int, cents: Double)], place: Place.ID, firstID: Int) -> [Report] {
            series.enumerated().map { index, point in
                Report(
                    id: fixtureID(firstID + index),
                    kind: .price,
                    value: .price(FuelPrice(grade: .regular, centsPerLitre: point.cents)),
                    placeID: place,
                    capturedAt: now.addingTimeInterval(-.days(Double(point.days)) - .hours(3)),
                    votes: .confirmed(by: 2)
                )
            }
        }
        return reports(puma, place: ID.pumaLosFiltros, firstID: 900) + reports(gulf, place: ID.gulfBairoa, firstID: 950)
    }()

    /// 90-day charger records, as the backend would tally them.
    nonisolated static let chargerTallies: [ChargerTally] = [
        ChargerTally(placeID: ID.chargerPlazaAmericas, reports: 10, devices: 6, works: 9, weightedWorksShare: 0.9),
        ChargerTally(placeID: ID.chargerCaguasCentro, reports: 7, devices: 4, works: 3, weightedWorksShare: 0.38),
        ChargerTally(placeID: ID.chargerMayaguezMall, reports: 3, devices: 2, works: 2, weightedWorksShare: 0.66),
    ]
}
