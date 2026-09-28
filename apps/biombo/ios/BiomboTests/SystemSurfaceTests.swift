@testable import Biombo
import Foundation
import Testing

@MainActor
@Suite("Widgets and Controls: the gas pick, the snapshot, freshness and routes")
struct SystemSurfaceTests {
    private let spanish = Locale(identifier: "es_PR")

    private func digest(crisis: Bool = false) -> HomeDigest {
        let snapshot = SampleData.snapshot(crisis: crisis)
        return HomeDigest(snapshot: snapshot, vantage: snapshot.vantage, visibleLayers: Layer.defaultVisible(inCrisis: crisis))
    }

    @Test("Gasolina cerca is the same cheapest station Cerca de ti answers with")
    func gasPickMatchesNearby() throws {
        let digest = digest()
        let pick = try #require(GasPick.make(from: digest))
        guard case .cheapestGas(let cheapest) = digest.nearby.facts.last else {
            Issue.record("Expected the cheapest gas in the answer")
            return
        }
        #expect(pick.answer.place.id == cheapest.place.id)
        #expect(!pick.isAvailability)
        #expect(pick.answer.freshness.isCurrent)
        let until = try #require(pick.currentUntil)
        #expect(until > digest.now, "A current answer still has time left")
    }

    @Test("Out of reach, or with nothing current, there is no pick")
    func gasPickNeedsCurrentPrices() {
        #expect(GasPick.make(from: digest(), radius: 1) == nil)
        var snapshot = SampleData.snapshot()
        snapshot = snapshot.aged(to: snapshot.generatedAt.addingTimeInterval(.days(3)))
        let aged = HomeDigest(snapshot: snapshot, vantage: snapshot.vantage, visibleLayers: Layer.defaultVisible(inCrisis: false))
        #expect(GasPick.make(from: aged) == nil, "Stale prices are never shown as current")
    }

    @Test("In crisis the pick is the nearest station with gas, and it says so, not a price")
    func gasPickInCrisis() throws {
        let digest = digest(crisis: true)
        let pick = try #require(GasPick.make(from: digest))
        #expect(pick.isAvailability)
        #expect(pick.answer.place.id == digest.availability.gasoline.lead?.place.id)
        let glance = try #require(WidgetSnapshotMaker(unit: .litre, locale: spanish).make(digest: digest, overview: WatchOverview(sharedWarnings: [], statuses: []), gas: pick, writtenAt: .now).gas)
        #expect(glance.unit == nil)
        #expect(glance.value == "Hay gasolina")
    }

    @Test("The snapshot carries each watched place's news, or its normal line")
    func watchedGlances() throws {
        let digest = digest()
        let overview = WatchStatusBuilder().overview(for: SampleData.watchedPlaces, digest: digest)
        let written = Date(timeIntervalSince1970: 2_000_000_000)
        let snapshot = WidgetSnapshotMaker(unit: .gallon, locale: spanish).make(digest: digest, overview: overview, gas: GasPick.make(from: digest), writtenAt: written)
        #expect(snapshot.watched.map(\.name) == SampleData.watchedPlaces.map(\.name))
        let mama = try #require(snapshot.watched.first { $0.name == "Casa de Mamá" })
        #expect(!mama.lines.isEmpty)
        #expect(mama.lines.count <= WidgetSnapshotMaker.lineCap)
        let quiet = try #require(snapshot.watched.first { $0.name == "Casa de Abuela" })
        #expect(quiet.lines.isEmpty)
        #expect(quiet.normalLine == "Todo normal")
        #expect(quiet.freshUntil == written.addingTimeInterval(WidgetSnapshotMaker.watchHold))
        #expect(snapshot.gas?.unit == "/gal")
    }

    @Test("Freshness moves onto the device's clock: the time left, counted from the write")
    func wallClock() {
        let now = SampleData.now
        let written = Date(timeIntervalSince1970: 2_000_000_000)
        let later = WidgetSnapshotMaker.wallClock(now.addingTimeInterval(600), now: now, writtenAt: written, hold: 7200)
        #expect(later == written.addingTimeInterval(600))
        #expect(WidgetSnapshotMaker.wallClock(now.addingTimeInterval(-60), now: now, writtenAt: written, hold: 7200) == written)
        #expect(WidgetSnapshotMaker.wallClock(nil, now: now, writtenAt: written, hold: 7200) == written.addingTimeInterval(7200))
    }

    @Test("A widget turns to Sin reportes recientes at each glance's expiry, not before")
    func expiries() {
        let start = Date(timeIntervalSince1970: 1_000)
        let gas = GasGlance(value: "$0.99", unit: "/L", compact: "$0.99/L", station: "Puma", whereLine: "", asOfClock: "", spoken: "", freshUntil: start.addingTimeInterval(300))
        let watch = WatchGlance(id: UUID(), name: "Casa", whereLine: "", lines: [], normalLine: "", freshUntil: start.addingTimeInterval(900))
        let old = WatchGlance(id: UUID(), name: "Vieja", whereLine: "", lines: [], normalLine: "", freshUntil: start.addingTimeInterval(-5))
        let snapshot = WidgetSnapshot(writtenAt: start, isCrisis: false, gas: gas, watched: [watch, old])
        #expect(snapshot.expiries(after: start) == [start.addingTimeInterval(300), start.addingTimeInterval(900)])
        #expect(gas.isFresh(at: start.addingTimeInterval(299)))
        #expect(!gas.isFresh(at: start.addingTimeInterval(300)))
        #expect(!old.isFresh(at: start))
    }

    @Test("The snapshot round-trips through the App Group, and erasing removes it")
    func storage() throws {
        let defaults = try #require(UserDefaults(suiteName: "biombo.tests.widget"))
        defaults.removePersistentDomain(forName: "biombo.tests.widget")
        let snapshot = WidgetSnapshot(writtenAt: Date(timeIntervalSince1970: 5), isCrisis: true, gas: nil, watched: [])
        snapshot.save(to: defaults)
        #expect(WidgetSnapshot.load(from: defaults) == snapshot)
        WidgetSnapshot.erase(from: defaults)
        #expect(WidgetSnapshot.load(from: defaults) == nil)
    }

    @Test("A Control's tap opens once, and only while fresh")
    func pendingScreen() throws {
        let defaults = try #require(UserDefaults(suiteName: "biombo.tests.pending"))
        defaults.removePersistentDomain(forName: "biombo.tests.pending")
        let tap = Date(timeIntervalSince1970: 10_000)
        PendingScreen.queue(.noPower, in: defaults, now: tap)
        #expect(PendingScreen.take(from: defaults, now: tap.addingTimeInterval(5)) == .noPower)
        #expect(PendingScreen.take(from: defaults, now: tap.addingTimeInterval(6)) == nil)

        PendingScreen.queue(.report, in: defaults, now: tap)
        #expect(PendingScreen.take(from: defaults, now: tap.addingTimeInterval(PendingScreen.ttl)) == nil)
    }

    @Test("Each Control's screen maps onto a home route, and the router hands it over once")
    func routes() {
        #expect(AppRoute(.report) == .report)
        #expect(AppRoute(.noPower) == .quickReport(.noPower))
        #expect(AppRoute(.powerBack) == .quickReport(.powerBack))
        #expect(AppRoute(.watchList) == .watchList)
        let router = AppRouter()
        router.open(.watchAnother)
        #expect(router.take() == .watchAnother)
        #expect(router.take() == nil)
        #expect(router.pending == nil)
    }

    @Test("A report's current window ends where its decay window does; official ones don't expire by age")
    func currentUntil() {
        let policy = FreshnessPolicy()
        let captured = SampleData.now
        let community = Report(kind: .noPower, placeID: "x", capturedAt: captured)
        #expect(policy.currentUntil(community) == captured.addingTimeInterval(ReportKind.noPower.decayWindow))
        let owner = Report(kind: .businessOpen, placeID: "x", capturedAt: captured, source: .owner)
        #expect(policy.currentUntil(owner) == captured.addingTimeInterval(ReportKind.ownerDefaultWindow))
        let official = Report(kind: .noPower, placeID: "x", capturedAt: captured, source: .official(.luma))
        #expect(policy.currentUntil(official) == nil)
    }
}
