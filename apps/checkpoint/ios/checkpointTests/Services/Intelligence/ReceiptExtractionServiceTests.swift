//
//  ReceiptExtractionServiceTests.swift
//  checkpointTests
//
//  The receipt pipeline around the model: validation, scoring the model's
//  answer against the rules, and falling back when the model is missing or
//  fails. The model itself is a fake session (`FakeLanguageModelSession`),
//  so none of this needs Apple Intelligence.
//

import XCTest
import UIKit
import SwiftData
@testable import checkpoint

/// Canned model answers.
final class FakeLanguageModelSession: LanguageModelSessioning {
    var receipt: ModelReceiptReading?
    var documentType: DocumentType?
    var error: Error?
    private(set) var receiptRequests: [ReceiptModelRequest] = []
    private(set) var classifyCalls = 0

    struct Failure: Error {}

    func readReceipt(_ request: ReceiptModelRequest) async throws -> ModelReceiptReading {
        receiptRequests.append(request)
        if let error { throw error }
        return receipt ?? ModelReceiptReading()
    }

    func classifyDocument(text: String) async throws -> DocumentType? {
        classifyCalls += 1
        if let error { throw error }
        return documentType
    }
}

@MainActor
final class ReceiptExtractionServiceTests: XCTestCase {

    private let context = ReceiptFixtures.context()
    private var scan: ReceiptScan { ReceiptFixtures.scan(ReceiptFixtures.firestone) }

    // MARK: - Model path

    func test_modelAgreeingWithRules_isHighConfidence() async {
        let session = FakeLanguageModelSession()
        session.receipt = ModelReceiptReading(
            shopName: "FIRESTONE COMPLETE AUTO CARE #0421",
            date: ReceiptFixtures.date(2026, 3, 14),
            total: Decimal(string: "109.08"),
            tax: Decimal(string: "6.66"),
            odometer: 45_210,
            serviceNames: ["oil change", "Tire Rotation"]
        )
        let draft = await ReceiptExtractionService(session: session).draft(from: scan, context: context)

        XCTAssertEqual(draft.source, .onDeviceModel)
        XCTAssertEqual(draft.confidence.shop, .high)
        XCTAssertEqual(draft.confidence.date, .high)
        XCTAssertEqual(draft.confidence.total, .high)
        XCTAssertEqual(draft.confidence.odometer, .high)
        XCTAssertEqual(draft.serviceNames, ["Oil Change", "Tire Rotation"], "Mapped onto the known names")
        XCTAssertEqual(draft.confidence.services, .high)
        XCTAssertEqual(draft.lineItems.count, 5, "The rules' items fill in where the model gave none")
        XCTAssertEqual(session.receiptRequests.first?.knownServiceNames, context.knownServiceNames)
    }

    func test_modelDisagreeing_keepsModelValueAtMediumConfidence() async {
        let session = FakeLanguageModelSession()
        session.receipt = ModelReceiptReading(total: Decimal(string: "102.42"), odometer: 45_210)
        let draft = await ReceiptExtractionService(session: session).draft(from: scan, context: context)

        XCTAssertEqual(draft.total, Decimal(string: "102.42"), "The model's reading")
        XCTAssertEqual(draft.confidence.total, .medium, "The rules read 109.08, and the items don't make 102.42")
        XCTAssertTrue(draft.issues.contains(.lineItemsDontAddUp(sum: Decimal(string: "109.08")!, total: Decimal(string: "102.42")!)))
        XCTAssertEqual(draft.date, ReceiptFixtures.date(2026, 3, 14), "Missing from the model: the rules' date")
    }

    func test_modelFailure_fallsBackToRules() async {
        let session = FakeLanguageModelSession()
        session.error = FakeLanguageModelSession.Failure()
        let draft = await ReceiptExtractionService(session: session).draft(from: scan, context: context)

        XCTAssertEqual(draft.source, .rules)
        XCTAssertEqual(draft.total, Decimal(string: "109.08"))
    }

    func test_noModel_usesRules() async {
        let draft = await ReceiptExtractionService(session: nil).draft(from: scan, context: context)
        XCTAssertEqual(draft.source, .rules)
        XCTAssertEqual(draft.serviceNames, ["Oil Change", "Tire Rotation"])
    }

    func test_extract_readsTheImageThenDrafts() async throws {
        var readCount = 0
        let service = ReceiptExtractionService(session: nil) { _, _ in
            readCount += 1
            return ReceiptFixtures.scan(ReceiptFixtures.tallerRivera)
        }
        let image = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { _ in }
        let result = try await service.extract(from: image, context: context)

        XCTAssertEqual(readCount, 1)
        XCTAssertEqual(result.draft.total, Decimal(string: "114.21"))
        XCTAssertTrue(result.scan.transcript.hasPrefix("TALLER HERMANOS RIVERA"))
    }

    func test_extract_passesVisionErrorsThrough() async {
        let service = ReceiptExtractionService(session: nil) { _, _ in throw ReceiptOCRService.OCRError.tooBlurry }
        let image = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { _ in }
        do {
            _ = try await service.extract(from: image, context: context)
            XCTFail("A blurred receipt must not produce a draft")
        } catch ReceiptOCRService.OCRError.tooBlurry {
            // expected
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    // MARK: - Validation

    func test_validate_dropsFutureAndAncientDates() {
        var draft = ServiceReceiptDraft(date: ReceiptFixtures.date(2026, 12, 1), total: 10)
        XCTAssertNil(ReceiptDraftValidator.validate(draft, context: context).date)
        draft.date = ReceiptFixtures.date(2010, 1, 1)
        let old = ReceiptDraftValidator.validate(draft, context: context)
        XCTAssertNil(old.date)
        XCTAssertEqual(old.issues, [.implausibleDate])
    }

    func test_validate_odometerBelowLastReading_isLowConfidence() {
        let draft = ReceiptDraftValidator.validate(ServiceReceiptDraft(odometer: 39_000), context: context)
        XCTAssertEqual(draft.odometer, 39_000, "Kept: it may be an old receipt")
        XCTAssertEqual(draft.confidence.odometer, .low)
        XCTAssertEqual(draft.issues, [.odometerBelowLastReading(lastReading: 40_000)])
    }

    func test_validate_odometerFarBeyondReach_isDropped() {
        let draft = ReceiptDraftValidator.validate(ServiceReceiptDraft(odometer: 4_521_000), context: context)
        XCTAssertNil(draft.odometer)
        XCTAssertEqual(draft.issues, [.implausibleOdometer])
    }

    func test_validate_itemsWithoutATotal_becomeALowConfidenceTotal() {
        let items = [ReceiptLineItem(label: "Filter", kind: .parts, amount: 12), ReceiptLineItem(label: "Labor", kind: .labor, amount: 30)]
        let draft = ReceiptDraftValidator.validate(ServiceReceiptDraft(lineItems: items), context: context)
        XCTAssertEqual(draft.total, 42)
        XCTAssertEqual(draft.confidence.total, .low)
    }

    func test_validate_itemsExcludingTax_stillAddUpWithIt() {
        let items = [ReceiptLineItem(label: "Filter", kind: .parts, amount: 10)]
        let draft = ReceiptDraftValidator.validate(ServiceReceiptDraft(total: Decimal(string: "10.70"), tax: Decimal(string: "0.70"), lineItems: items), context: context)
        XCTAssertEqual(draft.confidence.total, .high)
        XCTAssertTrue(draft.issues.isEmpty)
    }

    func test_validate_taxAboveTotal_isDropped() {
        let draft = ReceiptDraftValidator.validate(ServiceReceiptDraft(total: 5, tax: 50), context: context)
        XCTAssertNil(draft.tax)
    }

    // MARK: - Context

    func test_context_listsTheVehiclesServicesBeforePresets_withoutDuplicates() throws {
        let container = ModelContainer.inMemoryForTesting()
        let vehicle = Vehicle(name: "Daily", make: "Honda", model: "Civic", year: 2020, currentMileage: 45_000)
        container.mainContext.insert(vehicle)
        let service = Service(name: "Oil & Filter Change")
        service.vehicle = vehicle
        container.mainContext.insert(service)
        let duplicate = Service(name: "oil change")
        duplicate.vehicle = vehicle
        container.mainContext.insert(duplicate)

        let presets = [PresetData(name: "Oil Change", category: "maintenance", defaultIntervalMonths: 6, defaultIntervalMiles: 5_000)]
        let context = ReceiptExtractionService.context(for: vehicle, presets: presets)

        XCTAssertEqual(context.knownServiceNames.first, "Oil & Filter Change")
        XCTAssertEqual(context.knownServiceNames.filter { $0.lowercased() == "oil change" }.count, 1)
        XCTAssertEqual(context.lastOdometer, 45_000)
    }
}

@MainActor
final class DocumentClassifierTests: XCTestCase {

    private let insuranceText = """
        ACME Insurance Company — Declarations Page
        Policy Number PA-4432-1190 · Named insured: Ana Rivera
        Coverage: Liability, Collision · Premium $812.00 for six months
        """

    func test_keywords_typeEnglishAndSpanishDocuments() {
        XCTAssertEqual(DocumentClassifier.type(inText: insuranceText), .insurance)
        XCTAssertEqual(DocumentClassifier.type(inText: "DTOP · Marbete 2026 · Tablilla IWK-482"), .registration)
        XCTAssertEqual(DocumentClassifier.type(inText: "Certificado de título · Gravamen"), .title)
        XCTAssertEqual(DocumentClassifier.type(inText: "FACTURA · Mano de obra 40.00 · IVU 4.60 · Total 44.60"), .receipt)
        XCTAssertEqual(DocumentClassifier.type(inText: "Extended warranty service contract"), .warranty)
        XCTAssertNil(DocumentClassifier.type(inText: "hello"))
    }

    func test_keywordType_fallsBackToTheFileName() {
        XCTAssertEqual(DocumentClassifier.keywordType(for: "", fileName: "seguro_2026.jpg"), .insurance)
        XCTAssertEqual(DocumentClassifier.keywordType(for: "", fileName: "IMG_0001.jpg"), .other)
    }

    func test_modelAnswer_winsWhenTheTextIsLongEnough() async {
        let session = FakeLanguageModelSession()
        session.documentType = .inspection
        let type = await DocumentClassifier(session: session).classify(text: insuranceText, fileName: "scan.jpg")
        XCTAssertEqual(type, .inspection)
        XCTAssertEqual(session.classifyCalls, 1)
    }

    func test_modelUnsureOrFailing_fallsBackToKeywords() async {
        let unsure = FakeLanguageModelSession()
        let unsureType = await DocumentClassifier(session: unsure).classify(text: insuranceText, fileName: "scan.jpg")
        XCTAssertEqual(unsureType, .insurance)

        let failing = FakeLanguageModelSession()
        failing.error = FakeLanguageModelSession.Failure()
        let failingType = await DocumentClassifier(session: failing).classify(text: insuranceText, fileName: "scan.jpg")
        XCTAssertEqual(failingType, .insurance)
    }

    func test_shortText_neverAsksTheModel() async {
        let session = FakeLanguageModelSession()
        session.documentType = .manual
        let type = await DocumentClassifier(session: session).classify(text: "SYNTHETIC TEXT", fileName: "insurance_card.png")
        XCTAssertEqual(type, .insurance, "The filename decides")
        XCTAssertEqual(session.classifyCalls, 0)
    }
}
