@testable import Biombo
import Foundation
import Testing
import UserNotifications

@MainActor
@Suite("Ajustes, visitors and on-device summaries")
struct SettingsTests {
    @Test("Borrar mis datos empties the watch list, the outbox, Tu aporte and every choice")
    func eraseEverything() throws {
        let defaults = try #require(UserDefaults(suiteName: "biombo.tests.erase"))
        let shared = try #require(UserDefaults(suiteName: "biombo.tests.erase.shared"))
        for key in Preferences.erasable { defaults.set("x", forKey: key) }
        defaults.set("keep", forKey: "unrelated")
        WidgetSnapshot(writtenAt: .now, isCrisis: false, gas: nil, watched: []).save(to: shared)

        let watches = WatchStore(places: SampleData.watchedPlaces)
        let device = DeviceStore(outbox: SampleData.outbox)
        let contributions = ContributionStore(history: SampleData.myReports, votes: SampleData.myVotes, ownedPlaces: SampleData.ownedPlaces)
        DataEraser(watches: watches, device: device, contributions: contributions, defaults: defaults, shared: shared).eraseStoredData()

        #expect(watches.places.isEmpty)
        #expect(device.outbox.isEmpty)
        #expect(contributions.history.isEmpty)
        #expect(contributions.ledger.ownedPlaces.isEmpty)
        #expect(contributions.local(now: SampleData.now).reports.isEmpty)
        #expect(Preferences.erasable.allSatisfy { defaults.object(forKey: $0) == nil })
        #expect(defaults.string(forKey: "unrelated") == "keep")
        #expect(WidgetSnapshot.load(from: shared) == nil)
        #expect(Preferences.erasable.contains(Preferences.hasOnboarded), "The first run shows again")
    }

    @Test("Notification permission reads in three states")
    func notificationAccess() {
        #expect(NotificationAccess(.notDetermined) == .notAsked)
        #expect(NotificationAccess(.authorized) == .allowed)
        #expect(NotificationAccess(.provisional) == .allowed)
        #expect(NotificationAccess(.denied) == .off)
    }

    @Test("A visitor reads Biombo in English and sees the guide on a station past peek, on ordinary days")
    func visitorGuide() {
        let english = Locale(identifier: "en_US")
        let spanish = Locale(identifier: "es_PR")
        #expect(VisitorGuide.isVisitor(english))
        #expect(!VisitorGuide.isVisitor(spanish))
        #expect(VisitorGuide.shows(on: .station, tier: .summary, locale: english, isCrisis: false, isDismissed: false))
        #expect(!VisitorGuide.shows(on: .station, tier: .peek, locale: english, isCrisis: false, isDismissed: false))
        #expect(!VisitorGuide.shows(on: .business, tier: .full, locale: english, isCrisis: false, isDismissed: false))
        #expect(!VisitorGuide.shows(on: .station, tier: .full, locale: english, isCrisis: true, isDismissed: false))
        #expect(!VisitorGuide.shows(on: .station, tier: .full, locale: english, isCrisis: false, isDismissed: true))
        #expect(!VisitorGuide.shows(on: .station, tier: .full, locale: spanish, isCrisis: false, isDismissed: false))
        #expect(VisitorGuide.showsPumpPrice(in: .gallon))
        #expect(!VisitorGuide.showsPumpPrice(in: .litre))
        #expect(PriceUnit.regionDefault(english.region) == .gallon)
    }

    @Test("A station's detail carries DACO's range for the visitor's card; an area's doesn't")
    func dacoRangeOnDetail() throws {
        let snapshot = SampleData.snapshot()
        let digest = HomeDigest(snapshot: snapshot, vantage: snapshot.vantage, visibleLayers: Layer.defaultVisible(inCrisis: false))
        let station = try #require(snapshot.places.first { $0.kind == .station })
        let detail = try #require(PlaceDetailBuilder().detail(for: .place(station.id, .gas), snapshot: snapshot, areas: digest.areas))
        #expect(detail.dacoRange == DacoRange(snapshot.dacoReferences, grade: .regular, now: snapshot.generatedAt))
        let area = try #require(digest.areas.first)
        let areaDetail = try #require(PlaceDetailBuilder().detail(for: .area(area.id, area.layer), snapshot: snapshot, areas: digest.areas))
        #expect(areaDetail.dacoRange == nil)
    }

    @Test("On-device summaries only where the model runs, over enough changes, never in crisis")
    func summaryGate() {
        #expect(SummaryGate.shouldSummarize(factCount: 2, isModelAvailable: true, isCrisis: false))
        #expect(!SummaryGate.shouldSummarize(factCount: 1, isModelAvailable: true, isCrisis: false))
        #expect(!SummaryGate.shouldSummarize(factCount: 5, isModelAvailable: false, isCrisis: false))
        #expect(!SummaryGate.shouldSummarize(factCount: 5, isModelAvailable: true, isCrisis: true))
    }

    @Test("Quiet hours run overnight in the device's own zone")
    func quietHours() {
        #expect(QuietHours.start > QuietHours.end)
        #expect((0...23).contains(QuietHours.start) && (0...23).contains(QuietHours.end))
    }
}
