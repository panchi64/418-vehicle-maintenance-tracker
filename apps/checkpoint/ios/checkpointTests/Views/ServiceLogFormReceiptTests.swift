//
//  ServiceLogFormReceiptTests.swift
//  checkpointTests
//
//  A read receipt in the service form: values land in their own fields,
//  stay "suggested" until edited, Clear puts the form back, and saving puts
//  the shop and line items on a visit whose total counts once. Also the
//  odometer rule the receipt flow exposed: a hand-dated entry newer than the
//  last reading is adopted, not a contradiction.
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class ServiceLogFormReceiptTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var vehicle: Vehicle!

    private let now = Date()

    override func setUp() {
        super.setUp()
        container = .inMemoryForTesting()
        context = container.mainContext
        vehicle = Vehicle(name: "Daily", make: "Toyota", model: "Camry", year: 2022, currentMileage: 45_000)
        vehicle.mileageUpdatedAt = now.addingTimeInterval(-86_400 * 7)
        context.insert(vehicle)
    }

    override func tearDown() {
        container = nil
        context = nil
        vehicle = nil
        super.tearDown()
    }

    private func draft(daysAgo: Int = 3, shop: String? = "Taller Rivera", items: [ReceiptLineItem] = []) -> ServiceReceiptDraft {
        var draft = ServiceReceiptDraft(
            shopName: shop,
            date: now.addingTimeInterval(-86_400 * Double(daysAgo)),
            total: Decimal(string: "114.21"),
            odometer: 45_210,
            lineItems: items,
            serviceNames: ["Tire Rotation"]
        )
        draft.confidence.odometer = .low
        return draft
    }

    private let items = [
        ReceiptLineItem(label: "Rotación de gomas", kind: .labor, amount: Decimal(string: "102.43")!),
        ReceiptLineItem(label: "IVU", kind: .tax, amount: Decimal(string: "11.78")!),
    ]

    // MARK: - Applying

    func test_apply_fillsEachFieldAndMarksItSuggested() {
        let model = ServiceLogFormModel(vehicle: vehicle)
        model.apply(receipt: draft(), now: now)

        XCTAssertEqual(model.serviceName, "Tire Rotation")
        XCTAssertEqual(model.timing, .earlier)
        XCTAssertTrue(Calendar.current.isDate(model.customDate, inSameDayAs: now.addingTimeInterval(-86_400 * 3)))
        XCTAssertEqual(model.mileageAtService, 45_210)
        XCTAssertEqual(model.cost, "114.21")
        XCTAssertEqual(model.shopName, "Taller Rivera")
        XCTAssertTrue(model.showsShopField)
        for field in [ServiceLogFormModel.ReceiptField.service, .date, .odometer, .cost, .shop] {
            XCTAssertTrue(model.isSuggested(field), "\(field)")
        }
        XCTAssertEqual(model.receiptConfidence(.odometer), .low)
    }

    func test_editingAField_makesItTheUsers() {
        let model = ServiceLogFormModel(vehicle: vehicle)
        model.apply(receipt: draft(), now: now)

        model.cost = "120.00"
        model.mileageAtService = 45_300

        XCTAssertFalse(model.isSuggested(.cost))
        XCTAssertFalse(model.isSuggested(.odometer))
        XCTAssertTrue(model.isSuggested(.shop))
    }

    func test_clear_putsTheFormBack() {
        let model = ServiceLogFormModel(vehicle: vehicle)
        model.cost = "10"
        model.apply(receipt: draft(), now: now)

        model.clearReceipt()

        XCTAssertNil(model.receipt)
        XCTAssertEqual(model.cost, "10")
        XCTAssertEqual(model.timing, .today)
        XCTAssertEqual(model.mileageAtService, 45_000)
        XCTAssertEqual(model.serviceName, "")
        XCTAssertEqual(model.shopName, "")
        XCTAssertFalse(model.showsShopField)
    }

    func test_markDone_keepsItsLockedService() {
        let service = Service(name: "Oil Change", dueMileage: 45_500, intervalMonths: 6, intervalMiles: 5_000, isRecurring: true)
        service.vehicle = vehicle
        context.insert(service)
        let model = ServiceLogFormModel(vehicle: vehicle, mode: .complete(service))

        model.apply(receipt: draft(), now: now)

        XCTAssertEqual(model.serviceName, "Oil Change")
        XCTAssertFalse(model.isSuggested(.service))
        XCTAssertEqual(model.cost, "114.21")
    }

    func test_receiptFromToday_staysOnToday() {
        let model = ServiceLogFormModel(vehicle: vehicle)
        model.apply(receipt: draft(daysAgo: 0), now: now)
        XCTAssertEqual(model.timing, .today)
        XCTAssertTrue(model.isSuggested(.date))
    }

    func test_costText_twoDecimalsAndADot() {
        XCTAssertEqual(ServiceLogFormModel.costText(45), "45.00")
        XCTAssertEqual(ServiceLogFormModel.costText(Decimal(string: "114.205")!), "114.21")
    }

    // MARK: - Saving

    func test_save_putsShopAndLinesOnAVisit_andTheTotalCountsOnce() throws {
        let model = ServiceLogFormModel(vehicle: vehicle)
        model.apply(receipt: draft(items: items), now: now)

        let undo = LoggedServiceWriter.save(model, completing: nil, in: context)
        try context.save()

        let visit = try XCTUnwrap(undo.visit)
        XCTAssertEqual(visit.totalCost, Decimal(string: "114.21"))
        XCTAssertEqual(visit.shopName, "Taller Rivera")
        XCTAssertEqual(visit.lineItems?.count, 2)
        XCTAssertFalse(visit.isItemized)
        XCTAssertNil(undo.log.cost, "The cost moved to the visit")
        XCTAssertEqual(undo.log.visit?.id, visit.id)
        XCTAssertEqual(
            CostAnalyticsService.totalSpent(on: vehicle.serviceLogs ?? []),
            Decimal(string: "114.21")
        )

        undo.perform(in: context)
        try context.save()
        XCTAssertTrue(try context.fetch(FetchDescriptor<ServiceVisit>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<VisitLineItem>()).isEmpty)
    }

    func test_save_withoutShopOrLines_staysAStandaloneLog() throws {
        let model = ServiceLogFormModel(vehicle: vehicle)
        model.apply(receipt: draft(shop: nil), now: now)

        let undo = LoggedServiceWriter.save(model, completing: nil, in: context)

        XCTAssertNil(undo.visit)
        XCTAssertEqual(undo.log.cost, Decimal(string: "114.21"))
    }

    // MARK: - Odometer rule

    func test_datedEntryNewerThanTheLastReading_adoptsRatherThanContradicts() {
        let model = ServiceLogFormModel(vehicle: vehicle)
        model.customServiceName = "Tire Rotation"
        model.timing = .earlier
        model.customDate = now.addingTimeInterval(-86_400 * 3)
        model.mileageAtService = 45_210

        XCTAssertFalse(model.hasUnresolvedMileageContradiction)
        XCTAssertTrue(model.wouldAdoptMileage)
        XCTAssertNil(model.blocker)
    }

    func test_datedEntryOlderThanTheLastReading_isStillAContradiction() {
        let model = ServiceLogFormModel(vehicle: vehicle)
        model.customServiceName = "Tire Rotation"
        model.timing = .earlier
        model.customDate = now.addingTimeInterval(-86_400 * 30)
        model.mileageAtService = 45_210

        XCTAssertTrue(model.hasUnresolvedMileageContradiction)
    }
}
