@testable import Biombo
import Foundation
import Testing

@Suite("Filing a report and its sent state")
struct ReportFilingTests {
    private let now = SampleData.now

    private func report(_ kind: ReportKind, at placeID: Place.ID = SampleData.ID.bairoa, minutesAgo: Double = 0, value: ReportValue? = nil) -> Report {
        Report(kind: kind, value: value, placeID: placeID, capturedAt: now.addingTimeInterval(-.minutes(minutesAgo)))
    }

    @Test("A repeat within 15 minutes confirms the standing report; later, it's new")
    func repeats() {
        let standing = report(.noPower, minutesAgo: 10)
        let new = report(.noPower)
        #expect(ReportFiling.file(new, among: [standing], ownReports: []) == .confirmation(of: standing))
        let old = report(.noPower, minutesAgo: 20)
        #expect(ReportFiling.file(new, among: [old], ownReports: []) == .new(new))
        let reversal = report(.powerBack)
        #expect(ReportFiling.file(reversal, among: [standing], ownReports: []) == .new(reversal))
    }

    @Test("A repeat of your own says so and sends nothing")
    func yours() {
        let mine = report(.noPower, minutesAgo: 2)
        #expect(ReportFiling.file(report(.noPower), among: [mine], ownReports: [mine.id]) == .repeatOfYours(mine))
    }

    @Test("Prices repeat only in the same grade within ±1¢/L")
    func prices() {
        let standing = report(.price, at: SampleData.ID.pumaLosFiltros, minutesAgo: 5, value: .price(FuelPrice(grade: .regular, centsPerLitre: 99)))
        let close = report(.price, at: SampleData.ID.pumaLosFiltros, value: .price(FuelPrice(grade: .regular, centsPerLitre: 99.6)))
        let far = report(.price, at: SampleData.ID.pumaLosFiltros, value: .price(FuelPrice(grade: .regular, centsPerLitre: 102)))
        let diesel = report(.price, at: SampleData.ID.pumaLosFiltros, value: .price(FuelPrice(grade: .diesel, centsPerLitre: 99)))
        #expect(ReportFiling.file(close, among: [standing], ownReports: []) == .confirmation(of: standing))
        #expect(ReportFiling.file(far, among: [standing], ownReports: []) == .new(far))
        #expect(ReportFiling.file(diesel, among: [standing], ownReports: []) == .new(diesel))
    }

    @Test("Luz and agua say the utility isn't told; hazards add 911 and stay until closed")
    func handOffs() {
        let power = ReportReceipt(reportID: UUID(), kind: .noPower, placeName: "Bairoa", delivery: .sent)
        let water = ReportReceipt(reportID: UUID(), kind: .brokenPipe, placeName: "Bairoa", delivery: .sent)
        let flood = ReportReceipt(reportID: UUID(), kind: .flooded, placeName: "PR-52", delivery: .sent)
        let gas = ReportReceipt(reportID: UUID(), kind: .queue, placeName: "Gulf", delivery: .queued)
        #expect(power.handOff == .luma)
        #expect(water.handOff == .aaa)
        #expect(flood.handOff == nil && flood.showsSafetyLine && flood.staysUntilClosed)
        #expect(gas.handOff == nil && !gas.showsSafetyLine && !gas.staysUntilClosed)
        #expect(gas.detail == .queueMinutes)
        // "Volvió" needs nothing from the utility (§4.2).
        let back = ReportReceipt(reportID: UUID(), kind: .waterBack, placeName: "Bairoa", delivery: .sent)
        #expect(back.handOff == nil && !back.staysUntilClosed)
        #expect(Agency.aaa.reportsByPhone && !Agency.luma.reportsByPhone)
    }

    @Test("Añadir detalle only where the kind has a value and something went out")
    func detail() {
        #expect(ReportKind.noSignal.detail == .carrier)
        #expect(ReportKind.chargerBroken.detail == .connector)
        #expect(ReportKind.noPower.detail == nil)
        let confirmed = ReportReceipt(reportID: UUID(), kind: .queue, placeName: "Gulf", delivery: .confirmed(neighbours: 3))
        #expect(confirmed.detail == nil)
        let said = ReportReceipt(reportID: UUID(), kind: .queue, placeName: "Gulf", delivery: .alreadySaid)
        #expect(!said.canUndo)
    }

    @MainActor
    @Test("Sent sentences name the report and the place, in both languages")
    func sentences() {
        let es = Locale(identifier: "es")
        let receipt = ReportReceipt(reportID: UUID(), kind: .noPower, placeName: "Bairoa", delivery: .sent)
        let sent = String(localized: receipt.sentence(unit: .litre, locale: es))
        #expect(sent.contains("Bairoa"))
        let queued = ReportReceipt(reportID: UUID(), kind: .noPower, placeName: "Bairoa", delivery: .queued)
        #expect(String(localized: queued.sentence(unit: .litre, locale: es)) != sent)
        let price = ReportReceipt(reportID: UUID(), kind: .price, placeName: "Puma", delivery: .sent, price: FuelPrice(grade: .regular, centsPerLitre: 95))
        #expect(String(localized: price.sentence(unit: .litre, locale: es)).contains("95"))
    }
}
