//
//  AppEntityTests.swift
//  checkpointTests
//
//  The app-side App Entities: each snapshots its model faithfully, fetches by
//  ID through one path, and matches spoken names. Also pins the AppEnum raw
//  values App Intents persists in saved shortcuts.
//

import XCTest
import SwiftData
import AppIntents
@testable import checkpoint

@MainActor
final class AppEntityTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var vehicle: Vehicle!

    override func setUp() {
        super.setUp()
        modelContainer = .inMemoryForTesting()
        modelContext = modelContainer.mainContext
        vehicle = Vehicle(
            name: "Daily", make: "Honda", model: "Civic", year: 2020, currentMileage: 45_000,
            vin: "1HGBH41JXMN109186", licensePlate: "ABC123", tireSize: "215/55R16", oilType: "0W-20",
            marbeteExpirationMonth: 6, marbeteExpirationYear: 2030
        )
        modelContext.insert(vehicle)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        vehicle = nil
        super.tearDown()
    }

    // MARK: - Vehicle

    func test_vehicleEntity_carriesReferenceFacts() {
        let entity = VehicleEntity(model: vehicle)

        XCTAssertEqual(entity.id, vehicle.id)
        XCTAssertEqual(entity.name, "Daily")
        XCTAssertEqual(entity.identityLine, "2020 Honda Civic")
        XCTAssertEqual(entity.year, 2020)
        XCTAssertEqual(entity.recordedMileage, 45_000)
        XCTAssertNil(entity.estimatedMileage, "No pace history, no projection")
        XCTAssertEqual(entity.licensePlate, "ABC123")
        XCTAssertEqual(entity.vin, "1HGBH41JXMN109186")
        XCTAssertEqual(entity.tireSize, "215/55R16")
        XCTAssertEqual(entity.oilType, "0W-20")
        XCTAssertEqual(entity.marbeteExpiration, vehicle.marbeteExpirationDate)
    }

    func test_vehicleEntity_unknownYear_isNil() {
        let noYear = Vehicle(make: "Ford", model: "Focus", year: 0)
        XCTAssertNil(VehicleEntity(model: noYear).year)
    }

    func test_entitiesByID_returnsOnlyThoseRequested() throws {
        let other = Vehicle(name: "Weekend", make: "Mazda", model: "MX-5", year: 2019)
        modelContext.insert(other)
        try modelContext.save()

        let found = try VehicleEntity.entities(ids: [other.id], in: modelContext)

        XCTAssertEqual(found.map(\.id), [other.id])
        XCTAssertEqual(try VehicleEntity.entities(in: modelContext).count, 2)
    }

    func test_entitiesMatching_findsByMakeOrPlate_ignoringCase() throws {
        modelContext.insert(Vehicle(name: "Weekend", make: "Mazda", model: "MX-5", year: 2019))
        try modelContext.save()

        XCTAssertEqual(try VehicleEntity.entities(matching: "civic", in: modelContext).map(\.id), [vehicle.id])
        XCTAssertEqual(try VehicleEntity.entities(matching: "abc", in: modelContext).map(\.id), [vehicle.id])
        XCTAssertTrue(try VehicleEntity.entities(matching: "tesla", in: modelContext).isEmpty)
    }

    // MARK: - Service

    func test_serviceEntity_snapshotsScheduleAndStatus() {
        let service = Service(name: "Oil Change", dueMileage: 44_000, intervalMonths: 6, intervalMiles: 0)
        service.vehicle = vehicle
        modelContext.insert(service)

        let entity = ServiceEntity(model: service)

        XCTAssertEqual(entity.name, "Oil Change")
        XCTAssertEqual(entity.vehicleName, "Daily")
        XCTAssertEqual(entity.vehicleID, vehicle.id)
        XCTAssertEqual(entity.status, .overdue, "Past its due mileage")
        XCTAssertEqual(entity.dueMileage, 44_000)
        XCTAssertEqual(entity.intervalMonths, 6)
        XCTAssertNil(entity.intervalMiles, "A zero interval is no policy")
    }

    // MARK: - Logs and visits

    func test_serviceLogEntity_standaloneLog_carriesItsCost() {
        let service = Service(name: "Tire Rotation")
        service.vehicle = vehicle
        let log = ServiceLog(service: service, vehicle: vehicle, performedDate: .now,
                             mileageAtService: 44_000, cost: 35, costCategory: .maintenance)
        modelContext.insert(log)

        let entity = ServiceLogEntity(model: log)

        XCTAssertEqual(entity.serviceName, "Tire Rotation")
        XCTAssertEqual(entity.cost?.amount, 35)
        XCTAssertEqual(entity.cost?.currencyCode, "USD")
        XCTAssertEqual(entity.category, .maintenance)
        XCTAssertNil(entity.visitID)
    }

    func test_serviceLogEntity_unitemizedVisitLog_leavesCostToTheVisit() {
        let visit = ServiceVisit(vehicle: vehicle, totalCost: 300, costCategory: .repair)
        modelContext.insert(visit)
        let log = ServiceLog(vehicle: vehicle, performedDate: .now, mileageAtService: 44_000)
        log.visit = visit
        modelContext.insert(log)

        let entity = ServiceLogEntity(model: log)

        XCTAssertNil(entity.cost)
        XCTAssertNil(entity.category)
        XCTAssertEqual(entity.visitID, visit.id)
    }

    func test_visitEntity_summarizesServicesAndLineItems() {
        let visit = ServiceVisit(vehicle: vehicle, totalCost: 120, shopName: "Firestone")
        modelContext.insert(visit)
        for name in ["Tire Rotation", "Oil Change"] {
            let service = Service(name: name)
            service.vehicle = vehicle
            let log = ServiceLog(service: service, vehicle: vehicle, performedDate: .now, mileageAtService: 45_000)
            log.visit = visit
            modelContext.insert(log)
        }
        let labor = VisitLineItem(visit: visit, label: "Labor", kind: .labor, amount: 40)
        modelContext.insert(labor)

        let entity = VisitEntity(model: visit)

        XCTAssertEqual(entity.title, "Firestone")
        XCTAssertEqual(entity.total?.amount, 120)
        XCTAssertEqual(entity.serviceNames, ["Oil Change", "Tire Rotation"])
        XCTAssertEqual(entity.lineItems, ["Labor"])
    }

    func test_visitEntity_noShop_usesVisitTitle() {
        let visit = ServiceVisit(vehicle: vehicle, totalCost: 50)
        modelContext.insert(visit)

        XCTAssertEqual(VisitEntity(model: visit).title, L10n.rowVisitTitle)
    }

    // MARK: - Documents

    func test_documentEntity_carriesTypeAndScannedText() throws {
        let document = Document(fileName: "receipt.jpg", mimeType: "image/jpeg",
                                extractedText: "FIRESTONE TOTAL 120.00", documentType: .receipt,
                                vehicles: [vehicle])
        modelContext.insert(document)
        try modelContext.save()

        let entity = DocumentEntity(model: document)

        XCTAssertEqual(entity.type, .receipt)
        XCTAssertEqual(entity.vehicleNames, ["Daily"])
        XCTAssertEqual(entity.extractedText, "FIRESTONE TOTAL 120.00")
        XCTAssertEqual(try DocumentEntity.entities(matching: "firestone", in: modelContext).map(\.id), [document.id])
    }

    // MARK: - Presets

    func test_servicePresetEntities_comeFromTheBundledCatalog() {
        let presets = ServicePresetEntity.all()

        XCTAssertEqual(presets.map(\.id), PresetDataService.shared.loadPresets().map(\.name))
    }

    // MARK: - AppEnum raw values (persisted by saved shortcuts)

    func test_appEnumRawValues_areStable() {
        XCTAssertEqual(CostPeriod.allCases.map(\.rawValue), ["Month", "YTD", "Year", "All"])
        XCTAssertEqual(CostCategory.allCases.map(\.rawValue), ["maintenance", "repair", "upgrade"])
        XCTAssertEqual(ServiceStatus.allCases.map(\.rawValue), ["overdue", "dueSoon", "good", "neutral"])
        XCTAssertEqual(Set(DocumentType.caseDisplayRepresentations.keys), Set(DocumentType.allCases))
    }
}
