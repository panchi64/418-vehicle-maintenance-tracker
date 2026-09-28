@testable import Biombo
import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@MainActor
@Suite("Sending: the right door, the outbox, prices and photos")
struct ReportSendingTests {
    private let now = SampleData.now

    private func sender(connection status: ConnectionStatus = .online, contributions: ContributionStore, device: DeviceStore) -> ReportSender {
        ReportSender(
            contributions: contributions, device: device, snapshot: SampleData.snapshot(), areas: [],
            connection: ConnectionState(status: status, lastSyncedAt: now, now: now)
        )
    }

    private func target(_ id: Place.ID) throws -> ReportTarget {
        let place = try #require(SampleData.snapshot().places.first { $0.id == id })
        return ReportTarget(place: place, distance: 20, isInReach: true)
    }

    @Test("Online, a report joins the map and Tu aporte; Deshacer takes it back from both")
    func sendAndUndo() throws {
        let contributions = ContributionStore()
        let device = DeviceStore(outbox: Outbox())
        let sender = sender(contributions: contributions, device: device)
        let receipt = sender.send(.noPower, to: try target(SampleData.ID.puebloViejo))
        #expect(receipt.delivery == .sent)
        #expect(receipt.isAloneForNow)
        #expect(contributions.sent.count == 1)
        #expect(contributions.history.first?.outcome == .waiting)
        sender.undo(receipt)
        #expect(contributions.sent.isEmpty && contributions.history.isEmpty)
    }

    @Test("Offline, it waits in the outbox; the replay sends it and Añadir detalle travels with it")
    func offline() throws {
        let contributions = ContributionStore()
        let device = DeviceStore(connection: .offline, outbox: Outbox())
        let receipt = sender(connection: .offline, contributions: contributions, device: device)
            .send(.queue, to: try target(SampleData.ID.gulfBairoa))
        #expect(receipt.delivery == .queued)
        #expect(contributions.sent.isEmpty)
        #expect(device.outbox.pending(now: now).map(\.id) == [receipt.reportID])
        sender(connection: .offline, contributions: contributions, device: device).addDetail(.queueMinutes(20), to: receipt)

        let replayed = device.takeReplayable(now: now)
        #expect(device.outbox.isEmpty)
        let report = try #require(replayed.first?.report)
        #expect(report.value == .queueMinutes(20))
        contributions.delivered(report)
        #expect(contributions.sent.map(\.id) == [receipt.reportID])
    }

    @Test("The replay leaves reports older than a day to be asked about, unless approved")
    func replayOverdue() {
        var outbox = SampleData.outbox
        let leaving = outbox.takeReplayable(now: now)
        #expect(leaving.count == 2)
        #expect(leaving.map(\.capturedAt) == leaving.map(\.capturedAt).sorted())
        #expect(outbox.items.count == 1)
        outbox.send(outbox.items[0].id)
        #expect(outbox.takeReplayable(now: now).count == 1)
        #expect(outbox.isEmpty)
    }

    @Test("The outbox survives a relaunch")
    func outboxStorage() throws {
        let suite = "biombo.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let storage = DeviceStorage.outbox(defaults)
        #expect(storage.load() == nil)
        var outbox = SampleData.outbox
        outbox.enqueue(QueuedReport(Report(kind: .closed, placeID: SampleData.ID.pr52Caguas, capturedAt: now), placeName: "PR-52"))
        storage.save(outbox)
        #expect(storage.load() == outbox)
    }

    @Test("Retries back off, with jitter, up to a cap")
    func backoff() {
        #expect(ReplaySchedule.delay(attempt: 0, jitter: 0) == ReplaySchedule.base / 2)
        #expect(ReplaySchedule.delay(attempt: 0, jitter: 1) == ReplaySchedule.base)
        #expect(ReplaySchedule.delay(attempt: 3, jitter: 1) == ReplaySchedule.base * 8)
        #expect(ReplaySchedule.delay(attempt: 30, jitter: 1) == ReplaySchedule.cap)
    }

    @Test("A repeat within 15 minutes counts as Sigue igual on the neighbour's report, counted as the detail counts it")
    func repeatConfirms() throws {
        let contributions = ContributionStore()
        let sender = sender(contributions: contributions, device: DeviceStore())
        let receipt = sender.send(.queue, to: try target(SampleData.ID.gulfBairoa))
        #expect(contributions.sent.isEmpty)
        let standingID = SampleData.fixtureID(11)
        #expect(contributions.votes.vote(on: .report(standingID))?.agrees == true)
        // The toast's count is the one the place detail shows once the vote is folded in.
        let folded = contributions.local(now: now).applied(to: SampleData.snapshot())
        let standing = try #require(folded.reports.first { $0.id == standingID })
        #expect(receipt.delivery == .confirmed(neighbours: VerificationRules.confirmingNeighbours(standing.votes)))
        sender.undo(receipt)
        #expect(contributions.votes.vote(on: .report(standingID)) == nil)
    }

    @Test("A repeat you'd already confirmed doesn't count you twice, and Deshacer keeps that vote")
    func repeatAfterVote() throws {
        let contributions = ContributionStore()
        let standingID = SampleData.fixtureID(11)
        try contributions.vote(true, on: .report(standingID), at: now)
        let folded = contributions.local(now: now).applied(to: SampleData.snapshot())
        let sender = ReportSender(
            contributions: contributions, device: DeviceStore(), snapshot: folded, areas: [],
            connection: ConnectionState(status: .online, lastSyncedAt: now, now: now)
        )
        let receipt = sender.send(.queue, to: try target(SampleData.ID.gulfBairoa))
        let standing = try #require(folded.reports.first { $0.id == standingID })
        #expect(receipt.delivery == .confirmed(neighbours: standing.votes.confirmCount))
        sender.undo(receipt)
        #expect(contributions.votes.vote(on: .report(standingID))?.agrees == true)
    }

    @Test("A replayed outbox goes through the same doors: an outlier price stays held, a repeat confirms")
    func replayFiles() throws {
        let contributions = ContributionStore()
        let device = DeviceStore(connection: .offline, outbox: Outbox())
        let offline = sender(connection: .offline, contributions: contributions, device: device)
        let held = offline.send(.price, value: .price(FuelPrice(grade: .regular, centsPerLitre: 160)), to: try target(SampleData.ID.pumaLosFiltros))
        let repeated = offline.send(.queue, to: try target(SampleData.ID.gulfBairoa))
        let fresh = offline.send(.closed, to: try target(SampleData.ID.pr52Caguas))
        #expect(contributions.history.count == 3)

        sender(contributions: contributions, device: device).replay(device.takeReplayable(now: now))
        #expect(contributions.sent.map(\.id) == [fresh.reportID])
        #expect(contributions.history.contains { $0.id == held.reportID })
        #expect(!contributions.history.contains { $0.id == repeated.reportID })
        #expect(contributions.votes.vote(on: .report(SampleData.fixtureID(11)))?.agrees == true)
    }

    @Test("Typed prices read in the user's unit and are stored per litre", arguments: [
        ("0.99", PriceUnit.litre, 99.0), ("0,99", .litre, 99), ("$1", .litre, 100), ("99", .litre, 99), ("3.75", .gallon, 375 / 3.78541),
    ])
    func parse(text: String, unit: PriceUnit, perLitre: Double) throws {
        let price = try #require(PriceEntry.parse(text, grade: .regular, unit: unit))
        #expect(abs(price.centsPerLitre - perLitre) < 0.01)
        #expect(PriceEntry.parse("abc", grade: .regular, unit: unit) == nil)
    }

    @Test("A price far outside DACO's range is held; a typo isn't a price at all")
    func priceChecks() throws {
        let references = SampleData.dacoReferences
        #expect(PriceEntry.check(FuelPrice(grade: .regular, centsPerLitre: 99), references: references, now: now) == .ok)
        #expect(PriceEntry.check(FuelPrice(grade: .regular, centsPerLitre: 160), references: references, now: now) == .heldForReview)
        #expect(PriceEntry.check(FuelPrice(grade: .regular, centsPerLitre: 999), references: references, now: now) == .implausible)
        let contributions = ContributionStore()
        let receipt = sender(contributions: contributions, device: DeviceStore())
            .send(.price, value: .price(FuelPrice(grade: .regular, centsPerLitre: 160)), to: try target(SampleData.ID.pumaLosFiltros))
        #expect(receipt.delivery == .heldForReview)
        #expect(contributions.sent.isEmpty)
        #expect(contributions.history.count == 1)
    }

    @Test("A sign photo leaves with no GPS or EXIF")
    func strippedPhoto() async throws {
        let original = try #require(Self.jpegWithGPS())
        let before = try #require(CGImageSourceCreateWithData(original as CFData, nil))
        #expect((CGImageSourceCopyPropertiesAtIndex(before, 0, nil) as? [CFString: Any])?[kCGImagePropertyGPSDictionary] != nil)
        let clean = try #require(await PriceSignPhoto.stripped(original))
        let after = try #require(CGImageSourceCreateWithData(clean as CFData, nil))
        let properties = CGImageSourceCopyPropertiesAtIndex(after, 0, nil) as? [CFString: Any] ?? [:]
        #expect(properties[kCGImagePropertyGPSDictionary] == nil)
        #expect((properties[kCGImagePropertyExifDictionary] as? [CFString: Any])?[kCGImagePropertyExifUserComment] == nil)
    }

    private static func jpegWithGPS() -> Data? {
        let space = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil, width: 8, height: 8, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let image = context.makeImage() else { return nil }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        let metadata: [CFString: Any] = [
            kCGImagePropertyGPSDictionary: [kCGImagePropertyGPSLatitude: 18.4, kCGImagePropertyGPSLongitude: 66.1],
            kCGImagePropertyExifDictionary: [kCGImagePropertyExifUserComment: "secret"],
        ]
        CGImageDestinationAddImage(destination, image, metadata as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
