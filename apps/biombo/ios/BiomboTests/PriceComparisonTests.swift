@testable import Biombo
import Foundation
import Testing

@MainActor
@Suite("DACO price ladder and per-station trend")
struct PriceComparisonTests {
    let now = SampleData.now

    private func regular(_ cents: Double) -> FuelPrice {
        FuelPrice(grade: .regular, centsPerLitre: cents)
    }

    private func reference(_ brand: String, _ cents: Double, daysAgo: Double = 0.4) -> DacoReference {
        DacoReference(brand: brand, price: regular(cents), publishedOn: now.addingTimeInterval(-.days(daysAgo)))
    }

    // MARK: - Ladder

    @Test("Same brand and grade: direction and size, never a violation")
    func brandVerdict() throws {
        let refs = [reference("Puma", 102), reference("Shell", 104)]
        let below = try #require(PriceLadder(this: regular(99), brand: "Puma", references: refs, nearby: [], now: now))
        #expect(below.verdict(in: .litre) == .below(centsPerLitre: 3))
        #expect(below.headline(unit: .litre) != nil)
        let above = try #require(PriceLadder(this: regular(106), brand: "Puma", references: refs, nearby: [], now: now))
        #expect(above.verdict(in: .litre) == .above(centsPerLitre: 4))
        let same = try #require(PriceLadder(this: regular(102.8), brand: "Puma", references: refs, nearby: [], now: now))
        #expect(same.verdict(in: .litre) == .same)
    }

    @Test("\"The same\" is judged in the unit shown: 1¢/L apart reads as 4¢/gal, not the same")
    func sameInGallons() throws {
        let refs = [reference("Puma", 101)]
        let ladder = try #require(PriceLadder(this: regular(102), brand: "Puma", references: refs, nearby: [], now: now))
        #expect(ladder.verdict(in: .litre) == .same)
        #expect(ladder.verdict(in: .gallon) == .above(centsPerLitre: 1))
        let close = try #require(PriceLadder(this: regular(101.2), brand: "Puma", references: refs, nearby: [], now: now))
        #expect(close.verdict(in: .gallon) == .same)
    }

    @Test("Off DACO's brand list: compared against the island range")
    func offBrandRange() throws {
        let refs = [reference("Puma", 100), reference("Shell", 104)]
        #expect(PriceLadder(this: regular(101), brand: nil, references: refs, nearby: [], now: now)?.verdict(in: .litre) == .withinRange)
        #expect(PriceLadder(this: regular(98), brand: "Esso", references: refs, nearby: [], now: now)?.verdict(in: .litre) == .belowRange)
        #expect(PriceLadder(this: regular(106), brand: nil, references: refs, nearby: [], now: now)?.verdict(in: .litre) == .aboveRange)
    }

    @Test("A reference older than 3 days drops out; with no one nearby there is no ladder")
    func staleReference() {
        let old = [reference("Puma", 102, daysAgo: 3.5)]
        #expect(PriceLadder(this: regular(99), brand: "Puma", references: old, nearby: [], now: now) == nil)
        let ladder = PriceLadder(this: regular(99), brand: "Puma", references: old, nearby: [(regular(101), 500)], now: now)
        #expect(ladder?.verdict(in: .litre) == PriceLadder.Verdict.none)
    }

    @Test("At most 5 nearest same-grade stations within reach join; cheapest is said")
    func nearbyCap() throws {
        let nearby: [(price: FuelPrice, distance: Double)] = (1...8).map { (regular(100 + Double($0)), Double($0) * 1000) }
            + [(FuelPrice(grade: .diesel, centsPerLitre: 90), 100), (regular(90), 50_000)]
        let ladder = try #require(PriceLadder(this: regular(99), brand: "Puma", references: [], nearby: nearby, now: now))
        #expect(ladder.others.map(\.centsPerLitre) == [101, 102, 103, 104, 105])
        #expect(ladder.isCheapest)
        #expect(ladder.stationCount == 6)
        #expect((0...1).contains(ladder.position(99)))
    }

    @Test("Differences convert before rounding: 3¢/L is 11¢/gal")
    func differenceUnits() {
        #expect(GlanceNumbers.difference(centsPerLitre: 3, unit: .litre) == 3)
        #expect(GlanceNumbers.difference(centsPerLitre: 3, unit: .gallon) == 11)
        #expect(GlanceNumbers.difference(centsPerLitre: -4, unit: .litre) == 4)
    }

    // MARK: - Trend

    private func report(_ number: Int, cents: Double, daysAgo: Double, source: Source = .community) -> Report {
        Report(id: SampleData.fixtureID(5000 + number), kind: .price, value: .price(regular(cents)), placeID: "p",
               capturedAt: now.addingTimeInterval(-.days(daysAgo)), source: source)
    }

    @Test("A trend needs 3 report-days spanning 7 days")
    func trendGate() {
        let short = [report(1, cents: 100, daysAgo: 1), report(2, cents: 101, daysAgo: 2), report(3, cents: 102, daysAgo: 3)]
        #expect(PriceTrend(reports: short, placeID: "p", grade: .regular, now: now) == nil)
        let two = [report(1, cents: 100, daysAgo: 1), report(2, cents: 102, daysAgo: 12)]
        #expect(PriceTrend(reports: two, placeID: "p", grade: .regular, now: now) == nil)
        let enough = two + [report(3, cents: 101, daysAgo: 6)]
        #expect(PriceTrend(reports: enough, placeID: "p", grade: .regular, now: now)?.change == -2)
    }

    @Test("One point per day (the median once 3 agree), gaps left open, only community, only 30 days")
    func trendPoints() throws {
        let reports = [
            report(1, cents: 100, daysAgo: 1), report(2, cents: 104, daysAgo: 1.01), report(3, cents: 101, daysAgo: 1.02),
            report(4, cents: 106, daysAgo: 10), report(5, cents: 105, daysAgo: 20),
            report(6, cents: 80, daysAgo: 5, source: .owner), report(7, cents: 70, daysAgo: 40),
        ]
        let trend = try #require(PriceTrend(reports: reports, placeID: "p", grade: .regular, now: now))
        #expect(trend.points.map(\.centsPerLitre) == [105, 106, 101])
        #expect(trend.change == -4)
    }

    @Test("Sample: Puma Los Filtros fell from $1.03, Gulf Bairoa held")
    func sampleTrends() throws {
        let snapshot = SampleData.snapshot()
        let reports = snapshot.history + snapshot.reports
        let puma = try #require(PriceTrend(reports: reports, placeID: SampleData.ID.pumaLosFiltros, grade: .regular, now: now))
        #expect(puma.change == -4)
        let gulf = try #require(PriceTrend(reports: reports, placeID: SampleData.ID.gulfBairoa, grade: .regular, now: now))
        #expect(GlanceNumbers.difference(centsPerLitre: gulf.change, unit: .litre) == 0)
        #expect(PriceTrend(reports: reports, placeID: SampleData.ID.totalSanturce, grade: .regular, now: now) == nil)
    }
}
