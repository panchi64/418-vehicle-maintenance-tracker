import Foundation

/// A Capas row's live mini-answer (PRODUCT.md §3 "Capas answers too").
nonisolated enum LiveAnswer: Hashable, Sendable {
    case nothingNew
    /// "3 apagones cerca"
    case powerOutages(Int)
    /// "2 áreas sin agua cerca"
    case waterOutages(Int)
    /// "Aviso de hervir el agua": an active boil-water notice outranks counts.
    case boilWater
    /// "1 área sin señal cerca"
    case signalOutages(Int)
    /// One road event, said as its sentence ("Inundada la PR-52, km 14").
    case roadEvent(PlaceAnswer)
    /// "3 avisos en la carretera"
    case roadEvents(Int)
    /// "Sin reportes de problemas": never "pasable" or "despejada" (§6.6).
    case noRoadProblems
    /// "Desde $0.97/L cerca"
    case gasFrom(FuelPrice)
    /// "2 funcionan cerca"
    case chargersWorking(Int)
    /// "3 abiertos ahora"
    case openNow(Int)
}

/// One Capas row: the layer and what it says near the user right now.
nonisolated struct LayerDigest: Identifiable, Hashable, Sendable {
    let layer: Layer
    let live: LiveAnswer

    var id: Layer { layer }

    /// News is something wrong on a service layer; everyday layers inform, never alarm.
    var hasNews: Bool {
        switch live {
        case .powerOutages, .waterOutages, .boilWater, .signalOutages, .roadEvents: true
        case .roadEvent(let answer): answer.kind != .reopened
        case .nothingNew, .noRoadProblems, .gasFrom, .chargersWorking, .openNow: false
        }
    }

    /// Built from the same nearby rows as the sheet, so both say the same thing.
    /// Rows must be unfiltered by visibility: Capas answers for hidden layers too.
    static func make(rows: [NearbyRow], notices: [OfficialNotice], now: Date, defaultGrade: FuelGrade = .regular) -> [LayerDigest] {
        Layer.allCases.map { layer in
            LayerDigest(layer: layer, live: live(for: layer, rows: rows.filter { $0.layer == layer }, notices: notices, now: now, grade: defaultGrade))
        }
    }

    private static func live(for layer: Layer, rows: [NearbyRow], notices: [OfficialNotice], now: Date, grade: FuelGrade) -> LiveAnswer {
        let areaCount = rows.filter { if case .area = $0.item { true } else { false } }.count
        let answers = rows.compactMap { row -> PlaceAnswer? in
            if case .place(let answer) = row.item { answer } else { nil }
        }
        let result: LiveAnswer? = switch layer {
        case .power: areaCount > 0 ? .powerOutages(areaCount) : nil
        case .water:
            notices.contains { $0.kind == .boilWater && $0.isActive(at: now) } ? .boilWater
                : areaCount > 0 ? .waterOutages(areaCount) : nil
        case .signal: areaCount > 0 ? .signalOutages(areaCount) : nil
        case .roads:
            roadAnswer(answers) ?? .noRoadProblems
        case .gas:
            answers.compactMap(\.price).filter { $0.grade == grade }.min { $0.centsPerLitre < $1.centsPerLitre }.map(LiveAnswer.gasFrom)
        case .chargers:
            answers.filter { $0.kind == .chargerWorks }.count.nonZero.map(LiveAnswer.chargersWorking)
        case .businesses:
            answers.filter { [.businessOpen, .businessOnGenerator].contains($0.kind) }.count.nonZero.map(LiveAnswer.openNow)
        }
        return result ?? .nothingNew
    }

    /// Problems are counted; a road reported open again is said, never counted as news.
    private static func roadAnswer(_ answers: [PlaceAnswer]) -> LiveAnswer? {
        let problems = answers.filter { $0.kind != .reopened }
        switch problems.count {
        case 0: return answers.count == 1 ? .roadEvent(answers[0]) : nil
        case 1: return .roadEvent(problems[0])
        default: return .roadEvents(problems.count)
        }
    }
}

private extension Int {
    nonisolated var nonZero: Int? { self == 0 ? nil : self }
}
