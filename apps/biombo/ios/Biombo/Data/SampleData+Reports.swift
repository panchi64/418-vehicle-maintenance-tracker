import Foundation

/// SAMPLE DATA — invented reports. Nobody made these. The mix is deliberate:
/// fresh, aging and stale reports; confirmed, unverified and disputed ones;
/// owner posts; and every layer in at least two regions.
nonisolated extension SampleData {
    nonisolated static let reports: [Report] = gasReports + utilityReports + roadReports + chargerReports + businessReports

    nonisolated static let gasReports: [Report] = [
        report(1, .price, ID.pumaLosFiltros, minutesAgo: 12, value: price(.regular, 99), votes: .confirmed(by: 3)),
        report(2, .price, ID.totalSanturce, minutesAgo: 95, value: price(.regular, 102), votes: .confirmed(by: 2)),
        report(3, .price, ID.shellRioPiedras, minutesAgo: 30 * 60, value: price(.regular, 104)),
        report(4, .price, ID.gulfBairoa, minutesAgo: 40, value: price(.regular, 97), votes: .confirmed(by: 4)),
        report(5, .price, ID.gulfBairoa, minutesAgo: 40, value: price(.diesel, 108), votes: .confirmed(by: 2)),
        report(6, .price, ID.pumaCayey, minutesAgo: 3 * 24 * 60, value: price(.regular, 101)), // stale: behind "Ver reportes anteriores"
        report(7, .price, ID.texacoMayaguez, minutesAgo: 25, value: price(.regular, 98)),
        report(8, .price, ID.shellAguadilla, minutesAgo: 6 * 60, value: price(.premium, 112), votes: .confirmed(by: 2)),
        report(9, .price, ID.totalCaboRojo, minutesAgo: 20, value: price(.regular, 100),
               votes: Votes(confirmWeight: 2, disputeWeight: 1, confirmCount: 2, disputeCount: 1)), // confirmed, then disputed
        report(10, .hasGas, ID.gulfBairoa, minutesAgo: 15, votes: .confirmed(by: 2)),
        report(11, .queue, ID.gulfBairoa, minutesAgo: 15, value: .queueMinutes(20)),
        report(12, .noGas, ID.pumaCayey, minutesAgo: 50),
        report(13, .cashOnly, ID.texacoMayaguez, minutesAgo: 3 * 60, votes: .confirmed(by: 2)),
        // Shell Cidra: nothing current, three older prices behind "Ver reportes anteriores".
        report(14, .price, ID.shellCidra, minutesAgo: 3 * 24 * 60 + 80, value: price(.regular, 103)),
        report(15, .price, ID.shellCidra, minutesAgo: 3 * 24 * 60 + 360, value: price(.diesel, 111)),
        report(16, .price, ID.shellCidra, minutesAgo: 4 * 24 * 60 + 200, value: price(.regular, 105)),
        report(17, .price, ID.losPaseos, minutesAgo: 2 * 60, value: price(.regular, 101)),
    ]

    nonisolated static let utilityReports: [Report] = [
        report(20, .noPower, ID.bairoa, minutesAgo: 140, votes: .confirmed(by: 6)),
        report(21, .noPower, ID.bairoa, minutesAgo: 35),
        report(22, .powerBack, ID.miradero, minutesAgo: 20, votes: .confirmed(by: 2)),
        report(23, .lineDown, ID.bairoa, minutesAgo: 90, votes: .confirmed(by: 3)),
        report(24, .unstablePower, ID.rioPiedras, minutesAgo: 150), // aging
        report(25, .noWater, ID.rioPiedras, minutesAgo: 5 * 60, votes: .confirmed(by: 2)),
        report(26, .lowPressure, ID.miradero, minutesAgo: 60),
        report(27, .waterPoint, ID.bairoa, minutesAgo: 3 * 60, votes: .confirmed(by: 2)),
        report(28, .noSignal, ID.rioPiedras, minutesAgo: 45, value: .carrier(.claro)),
        report(29, .signalSpot, ID.miradero, minutesAgo: 8 * 60, value: .carrier(.liberty), votes: .confirmed(by: 2)),
        // Comerío, under AAA's boil-water notice: the card sits under this answer.
        report(30, .cloudyWater, ID.comerioPueblo, minutesAgo: 70, votes: .confirmed(by: 2)),
        report(31, .sawBoilNotice, ID.comerioPueblo, minutesAgo: 3 * 60),
    ]

    nonisolated static let roadReports: [Report] = [
        report(40, .flooded, ID.pr52Caguas, minutesAgo: 25, votes: .confirmed(by: 3)),
        report(41, .landslide, ID.pr156Comerio, minutesAgo: 5 * 60, votes: .confirmed(by: 3)),
        report(42, .oneLane, ID.pr2Mayaguez, minutesAgo: 2 * 60),
        report(43, .reopened, ID.pr115Rincon, minutesAgo: 2 * 60, votes: .confirmed(by: 2)),
        report(44, .treeOrPole, ID.pr115Rincon, minutesAgo: 20 * 60), // stale: the tree is gone
    ]

    nonisolated static let chargerReports: [Report] = [
        report(60, .chargerWorks, ID.chargerPlazaAmericas, minutesAgo: 40, value: .connector(.ccs1), votes: .confirmed(by: 2)),
        report(61, .chargerBroken, ID.chargerCaguasCentro, minutesAgo: 70),
        report(62, .chargerBusy, ID.chargerMayaguezMall, minutesAgo: 10),
        report(63, .connectorDamaged, ID.chargerMayaguezMall, minutesAgo: 30 * 60, value: .connector(.chademo)),
    ]

    nonisolated static let businessReports: [Report] = [
        report(80, .businessOnGenerator, ID.panaderiaLaCeiba, minutesAgo: 90, source: .owner,
               statedEnd: now.addingTimeInterval(.hours(2.5))), // "Abierto con planta hasta las 8 p. m."
        report(81, .productAvailable, ID.panaderiaLaCeiba, minutesAgo: 90, value: .ownerText("Hielo"), source: .owner),
        report(82, .businessOpen, ID.farmaciaDelPueblo, minutesAgo: 60, votes: .confirmed(by: 2)),
        report(83, .businessOpen, ID.colmadoDonaCarmen, minutesAgo: 3 * 60, source: .owner),
        report(84, .businessClosed, ID.colmadoDonaCarmen, minutesAgo: 30), // one unverified negative never flips the answer
        report(85, .event, ID.panaderiaLaCeiba, minutesAgo: 20 * 60, value: .event(bombaNight), source: .owner, statedEnd: bombaNight.end),
    ]

    /// Saturday 3 October, 8 to 11 p.m.
    nonisolated static let bombaNight = OwnerEvent(
        title: "Noche de bomba y plena",
        start: now.addingTimeInterval(.days(6) + .hours(2.5)),
        end: now.addingTimeInterval(.days(6) + .hours(5.5))
    )

    // MARK: - Builders

    private static func report(
        _ number: Int,
        _ kind: ReportKind,
        _ placeID: Place.ID,
        minutesAgo: Double,
        value: ReportValue? = nil,
        source: Source = .community,
        votes: Votes = Votes(),
        statedEnd: Date? = nil
    ) -> Report {
        Report(
            id: fixtureID(number),
            kind: kind,
            value: value,
            placeID: placeID,
            capturedAt: ago(minutes: minutesAgo),
            source: source,
            votes: votes,
            statedEnd: statedEnd
        )
    }

    private static func price(_ grade: FuelGrade, _ centsPerLitre: Double) -> ReportValue {
        .price(FuelPrice(grade: grade, centsPerLitre: centsPerLitre))
    }
}

nonisolated extension Votes {
    /// `count` independent neighbours at full weight, as sample data uses.
    static func confirmed(by count: Int) -> Votes {
        Votes(confirmWeight: Double(count), confirmCount: count)
    }
}
