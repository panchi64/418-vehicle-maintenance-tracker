//
//  LogReceiptIntentTests.swift
//  checkpointTests
//
//  Log Receipt: a file in, the services it shows logged the way Log Service
//  writes them — one visit, one total, the lines as its breakdown, the
//  receipt attached — and nothing written before a yes. Vision is swapped for
//  a fixture transcript (`LogReceiptIntent.makeExtractor`); no model.
//

import XCTest
import SwiftData
import UIKit
import AppIntents
import UniformTypeIdentifiers
@testable import checkpoint

@MainActor
final class LogReceiptIntentTests: IntentTestCase {

    private var transcript = ReceiptFixtures.tallerRivera

    override func setUp() {
        super.setUp()
        LogReceiptIntent.makeExtractor = { [unowned self] in
            let scan = ReceiptFixtures.scan(self.transcript)
            return ReceiptExtractionService(session: nil) { _, _ in scan }
        }
    }

    override func tearDown() {
        LogReceiptIntent.makeExtractor = { ReceiptExtractionService() }
        super.tearDown()
    }

    private func photo() -> Data {
        UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }.pngData()!
    }

    private var visits: [ServiceVisit] { (try? context.fetch(FetchDescriptor<ServiceVisit>())) ?? [] }

    // MARK: - Reading

    func test_read_turnsTheReceiptIntoAnOccasion() async throws {
        let reading = try await LogReceiptIntent.read(photo(), for: vehicle)

        XCTAssertEqual(reading.draft.serviceNames, ["Oil Change", "Tire Rotation"])
        XCTAssertEqual(reading.occasion.totalCost, Decimal(string: "114.21"))
        XCTAssertEqual(reading.occasion.shopName, "TALLER HERMANOS RIVERA")
        XCTAssertEqual(reading.occasion.mileage, 45_210)
        XCTAssertEqual(reading.occasion.lineItems.count, 6)
        XCTAssertEqual(reading.occasion.attachments.count, 1, "The receipt itself")
        XCTAssertEqual(reading.occasion.attachments.first?.extractedText?.hasPrefix("TALLER"), true)
    }

    func test_read_rejectsFilesThatAreNotImagesOrPDFs() async {
        do {
            _ = try await LogReceiptIntent.read(Data("not a receipt".utf8), for: vehicle)
            XCTFail("Expected receiptUnreadable")
        } catch {
            XCTAssertEqual(error as? IntentError, .receiptUnreadable)
        }
    }

    func test_read_rejectsReceiptsWithNothingOnThem() async {
        transcript = ReceiptFixtures.garbled
        do {
            _ = try await LogReceiptIntent.read(photo(), for: vehicle)
            XCTFail("Expected receiptUnreadable")
        } catch {
            XCTAssertEqual(error as? IntentError, .receiptUnreadable)
        }
    }

    func test_image_rendersAPDFsFirstPage() {
        let pdf = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)).pdfData { context in
            context.beginPage()
            "RECEIPT".draw(at: CGPoint(x: 72, y: 72))
        }
        let image = LogReceiptIntent.image(from: pdf)
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image?.size.height ?? 0, image?.size.width ?? 0)
    }

    // MARK: - Writing

    func test_record_writesOneVisit_totalOnce_linesAsBreakdown_receiptAttached() async throws {
        let oil = addService("Oil Change", dueInDays: 5)
        // Last done before the receipt's date, so the receipt completes it.
        oil.lastPerformed = ReceiptFixtures.date(2025, 9, 1)
        try context.save()
        let reading = try await LogReceiptIntent.read(photo(), for: vehicle)

        let logs = try LogReceiptIntent.record(reading.draft.serviceNames, on: vehicle, occasion: reading.occasion, in: context)

        XCTAssertEqual(logs.count, 2)
        XCTAssertEqual(visits.count, 1)
        let visit = try XCTUnwrap(visits.first)
        XCTAssertEqual(visit.totalCost, Decimal(string: "114.21"))
        XCTAssertEqual(visit.shopName, "TALLER HERMANOS RIVERA")
        XCTAssertEqual(visit.lineItems?.count, 6)
        XCTAssertEqual(visit.mileageAtVisit, 45_210)
        XCTAssertTrue(logs.allSatisfy { $0.cost == nil }, "Never the total divided by N")
        XCTAssertEqual(logs.flatMap { $0.attachments ?? [] }.count, 1)
        XCTAssertEqual(
            CostAnalyticsService.totalSpent(on: vehicle.serviceLogs ?? []),
            Decimal(string: "114.21"),
            "The visit counts once; its lines are not added on top"
        )
        XCTAssertNotEqual(oil.lastMileage, 40_000, "The tracked oil change was completed, not duplicated")
        XCTAssertEqual(services.filter { $0.name == "Oil Change" && $0.hasDueTracking }.count, 1, "Its next occurrence")
    }

    // MARK: - Perform

    func test_perform_neverWritesWithoutAnAnswer() async {
        let intent = LogReceiptIntent(receipt: IntentFile(data: photo(), filename: "receipt.png", type: .png))

        await runUnanswered { _ = try await self.wired(intent).perform() }

        XCTAssertTrue(logs.isEmpty)
        XCTAssertTrue(visits.isEmpty)
    }

    func test_perform_withNoServicesOnTheReceipt_asksForThem() async {
        transcript = ReceiptFixtures.spanishLongDate
        let intent = wired(LogReceiptIntent(receipt: IntentFile(data: photo(), filename: "receipt.png", type: .png)))

        do {
            _ = try await intent.perform()
            XCTFail("Expected a request for services")
        } catch {
            XCTAssertNil(error as? IntentError, "Asked for services rather than failing to read: \(error)")
        }
        XCTAssertTrue(logs.isEmpty)
    }
}

@MainActor
final class VisualSearchTests: IntentTestCase {

    private func frame() -> CGImage {
        UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { _ in }.cgImage!
    }

    override func setUp() {
        super.setUp()
        VisualCaptureStore.shared.removeAll()
    }

    override func tearDown() {
        VisualCaptureStore.shared.removeAll()
        PendingRouteStore.shared.route = nil
        super.tearDown()
    }

    // MARK: - Classifying

    func test_kinds_receiptFromItsText() {
        let kinds = VisualCaptureClassifier.kinds(labels: ["document"], transcript: ReceiptFixtures.firestone, context: ReceiptFixtures.context())
        XCTAssertEqual(kinds, [.receipt])
    }

    func test_kinds_odometerFromTheLabels() {
        XCTAssertEqual(VisualCaptureClassifier.kinds(labels: ["Car Interior", "dashboard"], transcript: nil, context: ReceiptFixtures.context()), [.odometer])
    }

    func test_kinds_vinOnlyWhenAValidOneIsPrinted() {
        XCTAssertEqual(VisualCaptureClassifier.vin(in: "VIN: 1HGCM82633A004352"), "1HGCM82633A004352")
        XCTAssertNil(VisualCaptureClassifier.vin(in: "12345678901234567"), "Digits only: a barcode")
        XCTAssertNil(VisualCaptureClassifier.vin(in: "1HGCM82633A00435O"), "No letter O in a VIN")
        XCTAssertEqual(VisualCaptureClassifier.kinds(labels: ["text"], transcript: "VIN 1HGCM82633A004352", context: ReceiptFixtures.context()), [.vin])
    }

    func test_kinds_nothingRecognizable_offersNothing() {
        XCTAssertEqual(VisualCaptureClassifier.kinds(labels: ["tree", "sky"], transcript: "hello", context: ReceiptFixtures.context()), [])
    }

    // MARK: - Results and routes

    func test_results_listAnActionPerKind_andRouteEach() async throws {
        let readers = VisualSearch.Readers(
            text: { _ in ReceiptFixtures.firestone },
            odometer: { _, _ in 45_320 }
        )
        let entities = await VisualSearch.results(labels: ["receipt", "dashboard"], image: frame(), in: context, readers: readers)

        XCTAssertEqual(entities.map(\.kind), [.receipt, .odometer])
        XCTAssertEqual(entities[0].title, L10n.visualLogReceipt)

        XCTAssertEqual(try VisualSearch.route(for: entities[0].id), .logReceipt(vehicleID: vehicle.id, captureID: entities[0].id))
        XCTAssertEqual(try VisualSearch.route(for: entities[1].id), .mileageReading(vehicleID: vehicle.id, reading: 45_320))

        let found = try VisualSearch.entities(ids: entities.map(\.id), in: container)
        XCTAssertEqual(found.map(\.id), entities.map(\.id))
    }

    func test_results_odometerUnreadable_isNotOffered() async {
        let readers = VisualSearch.Readers(text: { _ in nil }, odometer: { _, _ in nil })
        let entities = await VisualSearch.results(labels: ["dashboard"], image: frame(), in: context, readers: readers)
        XCTAssertTrue(entities.isEmpty)
    }

    func test_openIntent_setsTheRoute() async throws {
        let readers = VisualSearch.Readers(text: { _ in "VIN 1HGCM82633A004352" }, odometer: { _, _ in nil })
        let results = await VisualSearch.results(labels: [], image: frame(), in: context, readers: readers)
        let entity = try XCTUnwrap(results.first)

        _ = try await OpenVisualCaptureIntent(target: entity).perform()

        XCTAssertEqual(PendingRouteStore.shared.route, .addVehicle(vehicleID: vehicle.id, vin: "1HGCM82633A004352"))
    }

    func test_route_forAnExpiredCapture_throws() {
        let old = VisualCapture(id: UUID(), kind: .receipt, vehicleID: vehicle.id, image: frame(), createdAt: .now.addingTimeInterval(-3_600))
        VisualCaptureStore.shared.add(old)
        XCTAssertThrowsError(try VisualSearch.route(for: old.id)) { error in
            XCTAssertEqual(error as? IntentError, .captureExpired)
        }
    }

    // MARK: - Landing

    func test_apply_routes_seedTheScreensTheyOpen() {
        let appState = AppState()
        let capture = VisualCapture(id: UUID(), kind: .receipt, vehicleID: vehicle.id, image: frame())
        VisualCaptureStore.shared.add(capture)

        appState.apply(.logReceipt(vehicleID: vehicle.id, captureID: capture.id), vehicles: [vehicle])
        XCTAssertEqual(appState.activeSheet?.id, "addService")
        if case .addService(_, _, let receipt) = appState.activeSheet {
            XCTAssertNotNil(receipt)
        } else {
            XCTFail("Expected the log form")
        }

        let mileageState = AppState()
        mileageState.apply(.mileageReading(vehicleID: vehicle.id, reading: 45_320), vehicles: [vehicle])
        XCTAssertEqual(mileageState.mileageReadingSeed, 45_320)
        XCTAssertEqual(mileageState.activeSheet?.id, ActiveSheet.mileageUpdate.id)

        let vinState = AppState()
        vinState.apply(.addVehicle(vehicleID: vehicle.id, vin: "1HGCM82633A004352"), vehicles: [vehicle])
        XCTAssertEqual(vinState.addVehicleVINSeed, "1HGCM82633A004352")
    }
}
