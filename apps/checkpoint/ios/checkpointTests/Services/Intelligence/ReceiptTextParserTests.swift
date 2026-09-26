//
//  ReceiptTextParserTests.swift
//  checkpointTests
//
//  The rule-based receipt reader over real-looking transcripts
//  (`ReceiptFixtures`): the whole reader on devices without Apple
//  Intelligence, and the cross-check for the model everywhere else.
//

import XCTest
@testable import checkpoint

final class ReceiptTextParserTests: XCTestCase {

    private func read(_ transcript: String, context: ReceiptContext = ReceiptFixtures.context()) -> ServiceReceiptDraft {
        let draft = ReceiptTextParser.parse(ReceiptFixtures.scan(transcript), context: context)
        return ReceiptDraftValidator.validate(draft, context: context)
    }

    // MARK: - Whole receipts

    func test_usChainReceipt_readsEveryField() {
        let draft = read(ReceiptFixtures.firestone)

        XCTAssertEqual(draft.shopName, "FIRESTONE COMPLETE AUTO CARE #0421")
        XCTAssertEqual(draft.date, ReceiptFixtures.date(2026, 3, 14))
        XCTAssertEqual(draft.confidence.date, .high, "Printed on a DATE line")
        XCTAssertEqual(draft.total, Decimal(string: "109.08"))
        XCTAssertEqual(draft.confidence.total, .high)
        XCTAssertEqual(draft.tax, Decimal(string: "6.66"), "The 6.5% rate is not an amount")
        XCTAssertEqual(draft.odometer, 45_210, "MILEAGE IN, not the next-service mileage")
        XCTAssertEqual(draft.lineItems.count, 5)
        XCTAssertEqual(draft.lineItems.last?.kind, .tax)
        XCTAssertEqual(draft.lineItems.first(where: { $0.label == "TIRE ROTATION" })?.kind, .labor)
        XCTAssertEqual(draft.serviceNames, ["Oil Change", "Tire Rotation"])
        XCTAssertTrue(draft.issues.isEmpty)
        XCTAssertEqual(draft.source, .rules)
    }

    func test_puertoRicoTaller_readsSpanishAndSumsBothIVULines() {
        let draft = read(ReceiptFixtures.tallerRivera)

        XCTAssertEqual(draft.shopName, "TALLER HERMANOS RIVERA")
        XCTAssertEqual(draft.date, ReceiptFixtures.date(2026, 3, 14), "14/03 can only be day-first")
        XCTAssertEqual(draft.total, Decimal(string: "114.21"), "TOTAL A PAGAR, not the ATH Móvil line")
        XCTAssertEqual(draft.tax, Decimal(string: "11.78"), "State 10.76 + municipal 1.02")
        XCTAssertEqual(draft.odometer, 45_210)
        XCTAssertEqual(draft.lineItems.count, 6)
        XCTAssertEqual(draft.lineItems.first?.kind, .labor, "Cambio de aceite is the job, not change given back")
        XCTAssertEqual(draft.serviceNames, ["Oil Change", "Tire Rotation"])
        XCTAssertEqual(draft.confidence.total, .high, "Items and IVU add up to the total")
    }

    func test_dealerRepairOrder_readsMonthNameDateDiscountAndQuantities() {
        let draft = read(ReceiptFixtures.dealer)

        XCTAssertEqual(draft.shopName, "Toyota de Puerto Rico - Service")
        XCTAssertEqual(draft.date, ReceiptFixtures.date(2026, 3, 3))
        XCTAssertEqual(draft.total, Decimal(string: "74.84"))
        XCTAssertEqual(draft.odometer, 44_980, "Mileage in, never the recommended next-service mileage")
        let wipers = draft.lineItems.first { $0.label == "WIPER BLADE" }
        XCTAssertEqual(wipers?.amount, 25, "The extended price, not the unit price")
        XCTAssertEqual(draft.lineItems.first { $0.label == "LOYALTY DISCOUNT" }?.kind, .discount)
        XCTAssertEqual(draft.lineItems.first { $0.label == "SHOP SUPPLIES" }?.kind, .supplies)
        XCTAssertEqual(draft.lineItemSum, Decimal(string: "74.84"), "The discount subtracts")
        XCTAssertEqual(draft.serviceNames, ["Oil Change", "Wiper Blades"])
    }

    func test_noTotalLabel_fallsBackToLargestAmount_thenItemsVouchForIt() {
        let parsed = ReceiptTextParser.parse(ReceiptFixtures.scan(ReceiptFixtures.partsCounter), context: ReceiptFixtures.context())
        XCTAssertEqual(parsed.total, Decimal(string: "184.49"))
        XCTAssertEqual(parsed.confidence.total, .low, "A guess until checked")

        let validated = ReceiptDraftValidator.validate(parsed, context: ReceiptFixtures.context())
        XCTAssertEqual(validated.confidence.total, .high, "The items add up to it")
        XCTAssertEqual(validated.date, ReceiptFixtures.date(2026, 9, 20))
        XCTAssertEqual(validated.confidence.date, .medium, "No date label")
        XCTAssertNil(validated.odometer)
        XCTAssertEqual(validated.serviceNames, ["Battery Check"])
    }

    func test_spanishLongDate_andDecimalComma() {
        let draft = read(ReceiptFixtures.spanishLongDate)
        XCTAssertEqual(draft.date, ReceiptFixtures.date(2026, 3, 14))
        XCTAssertEqual(draft.total, 45)
        XCTAssertEqual(draft.lineItems.first?.kind, .labor)
    }

    func test_garbledText_isEmpty() {
        let draft = read(ReceiptFixtures.garbled)
        XCTAssertTrue(draft.isEmpty)
        XCTAssertNil(draft.shopName, "\"thank you\" is not a shop")
    }

    // MARK: - Pieces

    func test_amounts_readUSAndEuropeanSeparators_neverPercentagesOrOdometers() {
        XCTAssertEqual(ReceiptTextParser.amounts(in: "TOTAL $1,234.56"), [Decimal(string: "1234.56")!])
        XCTAssertEqual(ReceiptTextParser.amounts(in: "Total 1.234,56"), [Decimal(string: "1234.56")!])
        XCTAssertEqual(ReceiptTextParser.amounts(in: "IVU 11.5% 9.48"), [Decimal(string: "9.48")!])
        XCTAssertEqual(ReceiptTextParser.amounts(in: "Mileage 45,210"), [])
        XCTAssertEqual(ReceiptTextParser.amounts(in: "Date 03.14.2026"), [], "A dotted date is not money")
        XCTAssertTrue(ReceiptTextParser.amountIsNegative(in: "Coupon (5.00)"))
        XCTAssertTrue(ReceiptTextParser.amountIsNegative(in: "Discount 5.00-"))
        XCTAssertFalse(ReceiptTextParser.amountIsNegative(in: "Oil filter 9.99"))
    }

    func test_dates_inEveryPrintedForm() {
        let calendar = Calendar.current
        let march14 = ReceiptFixtures.date(2026, 3, 14)
        XCTAssertEqual(ReceiptTextParser.date(in: "2026-03-14", calendar: calendar), march14)
        XCTAssertEqual(ReceiptTextParser.date(in: "03/14/26", calendar: calendar), march14)
        XCTAssertEqual(ReceiptTextParser.date(in: "14-MAR-2026", calendar: calendar), march14)
        XCTAssertEqual(ReceiptTextParser.date(in: "March 14, 2026", calendar: calendar), march14)
        XCTAssertEqual(ReceiptTextParser.date(in: "14 de marzo del 2026", calendar: calendar), march14)
        XCTAssertNil(ReceiptTextParser.date(in: "02/30/2026", calendar: calendar), "No such day")
        XCTAssertNil(ReceiptTextParser.date(in: "Tel 787-555-0199", calendar: calendar))
    }

    func test_nextServiceDates_areNeverTheReceiptDate() {
        let transcript = """
            Quick Lube
            Next oil change due 12/14/2026
            Service date 09/01/2026
            TOTAL 45.00
            """
        let draft = read(transcript)
        XCTAssertEqual(draft.date, ReceiptFixtures.date(2026, 9, 1))
    }

    func test_odometer_inKilometres_isStoredInMiles() {
        XCTAssertEqual(ReceiptTextParser.odometer(in: ["Kilometraje: 100,000 km"]), 62_137)
    }

    func test_oilChangeLine_isNotAPaymentLine() {
        XCTAssertFalse(ReceiptTextParser.isPaymentLine("OIL CHANGE 39.99"))
        XCTAssertFalse(ReceiptTextParser.isPaymentLine("Cambio de aceite 39.99"))
        XCTAssertTrue(ReceiptTextParser.isPaymentLine("CAMBIO 5.79"))
        XCTAssertTrue(ReceiptTextParser.isPaymentLine("VISA 109.08"))
    }

    func test_totalScore_skipsLinesThatOnlyLookLikeTotals() {
        XCTAssertEqual(ReceiptTextParser.totalScore("SUBTOTAL 102.42"), 0)
        XCTAssertEqual(ReceiptTextParser.totalScore("Sub Total 102.42"), 0)
        XCTAssertEqual(ReceiptTextParser.totalScore("TOTAL ITEMS 4"), 0)
        XCTAssertEqual(ReceiptTextParser.totalScore("Total tax 6.66"), 0)
        XCTAssertEqual(ReceiptTextParser.totalScore("TOTAL 109.08"), 2)
        XCTAssertEqual(ReceiptTextParser.totalScore("Balance due 109.08"), 3)
    }
}

final class ServiceNameMatcherTests: XCTestCase {

    private let matcher = ServiceNameMatcher(candidates: ["Oil & Filter Change", "Oil Change", "Tire Rotation",
                                                          "Air Filter", "Cabin Air Filter", "Wiper Blades"])

    func test_prefersTheVehiclesOwnName() {
        XCTAssertEqual(matcher.match("LOF synthetic"), "Oil & Filter Change")
        XCTAssertEqual(matcher.match("Cambio de aceite"), "Oil & Filter Change")
    }

    func test_spanishAndPuertoRicanWording() {
        XCTAssertEqual(matcher.match("ROTACIÓN DE GOMAS"), "Tire Rotation")
        XCTAssertEqual(matcher.match("Plumas delanteras"), "Wiper Blades")
    }

    func test_longestNameWins() {
        XCTAssertEqual(matcher.match("Cabin air filter replacement"), "Cabin Air Filter")
        XCTAssertEqual(matcher.match("Engine air filter"), "Air Filter")
    }

    func test_wholeWordsOnly() {
        XCTAssertNil(matcher.match("Mechanic gloves"), "\"lof\" inside a word is not LOF")
        XCTAssertNil(matcher.match("Coffee"))
    }

    func test_catalogNameWhenTheVehicleHasNone() {
        let presetsOnly = ServiceNameMatcher(candidates: ["Oil Change"])
        XCTAssertEqual(presetsOnly.match("Batería nueva"), "Battery Check", "The catalog's own name")
    }

    func test_toolAnswer_namesTheMatch() {
        XCTAssertEqual(ServiceNameTool.answer(for: "LOF", matcher: matcher), "Use the service name \"Oil & Filter Change\".")
        XCTAssertTrue(ServiceNameTool.answer(for: "Detail", matcher: matcher).hasPrefix("No saved service"))
    }
}
