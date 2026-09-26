//
//  PendingRouteTests.swift
//  checkpointTests
//
//  Where a notification (or one of its foreground buttons), a widget row, or
//  an intent takes the user. Each stores a route; `AppState.apply` turns it
//  into navigation whenever ContentView is on screen, including after a cold
//  launch.
//

import XCTest
import UserNotifications
@testable import checkpoint

@MainActor
final class PendingRouteTests: XCTestCase {

    private var appState: AppState!
    private var vehicle: Vehicle!
    private var other: Vehicle!

    override func setUp() {
        super.setUp()
        appState = AppState()
        vehicle = Vehicle(name: "My Car", make: "Toyota", model: "Camry", year: 2022)
        other = Vehicle(name: "Other", make: "Honda", model: "Civic", year: 2020)
        appState.selectedVehicle = other
    }

    override func tearDown() {
        appState = nil
        vehicle = nil
        other = nil
        super.tearDown()
    }

    private func addServices(dueInDays days: [Int]) -> [Service] {
        let services = days.enumerated().map { index, offset in
            Service(name: "Service \(index)", dueDate: Calendar.current.date(byAdding: .day, value: offset, to: .now))
        }
        services.forEach { $0.vehicle = vehicle }
        vehicle.services = services
        return services
    }

    // MARK: - Vehicle selection

    func test_apply_selectsTheNotificationsVehicle() {
        appState.apply(.costs(vehicleID: vehicle.id), vehicles: [vehicle, other])

        XCTAssertEqual(appState.selectedVehicle?.id, vehicle.id)
        XCTAssertEqual(appState.selectedTab, .costs)
    }

    func test_apply_deletedVehicle_doesNothing() {
        appState.apply(.editVehicle(vehicleID: UUID()), vehicles: [vehicle, other])

        XCTAssertEqual(appState.selectedVehicle?.id, other.id)
        XCTAssertNil(appState.activeSheet)
    }

    func test_apply_otherVehicle_popsEveryStack() {
        let services = addServices(dueInDays: [3])
        appState.paths[.costs] = [.service(services[0])]

        appState.apply(.costs(vehicleID: vehicle.id), vehicles: [vehicle, other])

        XCTAssertTrue(appState.paths.values.allSatisfy(\.isEmpty))
    }

    // MARK: - Open sheets

    func test_apply_withSheetOnScreen_dismissesItBeforeNavigating() {
        appState.present(.settings)
        appState.sheetDidAppear(.settings)

        appState.apply(.costs(vehicleID: vehicle.id), vehicles: [vehicle])

        XCTAssertNil(appState.activeSheet)
        XCTAssertEqual(appState.selectedTab, .costs)
    }

    func test_apply_withSheetOnScreen_queuesTheRoutesSheetUntilItCloses() {
        appState.present(.settings)
        appState.sheetDidAppear(.settings)

        appState.apply(.editVehicle(vehicleID: vehicle.id), vehicles: [vehicle])

        // The open sheet is dismissing; the editor waits for its onDismiss.
        XCTAssertNil(appState.activeSheet)
        let dismissed = appState.sheetDidDismiss()
        XCTAssertEqual(dismissed?.id, ActiveSheet.settings.id)
        XCTAssertEqual(appState.activeSheet?.id, ActiveSheet.editVehicle.id)
    }

    // MARK: - Mileage, costs, marbete

    func test_apply_updateMileage_opensMileageSheetOnHome() {
        appState.selectedTab = .costs
        appState.apply(.updateMileage(vehicleID: vehicle.id), vehicles: [vehicle])

        XCTAssertEqual(appState.selectedTab, .home)
        XCTAssertEqual(appState.activeSheet?.id, ActiveSheet.mileageUpdate.id)
    }

    // The Log Service and Scan Receipt Controls.

    func test_apply_logService_opensTheServiceFormOnHome() {
        appState.selectedTab = .costs
        appState.apply(.logService(vehicleID: vehicle.id), vehicles: [vehicle])

        XCTAssertEqual(appState.selectedTab, .home)
        guard case .addService(_, _, let receipt, let scansReceipt) = appState.activeSheet else {
            return XCTFail("Expected the service form")
        }
        XCTAssertNil(receipt)
        XCTAssertFalse(scansReceipt)
    }

    func test_apply_scanReceipt_opensTheServiceFormWithTheScanner() {
        appState.apply(.scanReceipt(vehicleID: vehicle.id), vehicles: [vehicle])

        XCTAssertIdentical(appState.selectedVehicle, vehicle)
        guard case .addService(_, _, _, let scansReceipt) = appState.activeSheet else {
            return XCTFail("Expected the service form")
        }
        XCTAssertTrue(scansReceipt)
    }

    func test_apply_vehicle_selectsItOnHomeRoot() {
        let services = addServices(dueInDays: [3])
        appState.selectVehicle(vehicle)
        appState.selectedTab = .services
        appState.paths[.home] = [.service(services[0])]

        appState.apply(.vehicle(vehicleID: vehicle.id), vehicles: [vehicle, other])

        XCTAssertEqual(appState.selectedVehicle?.id, vehicle.id)
        XCTAssertEqual(appState.selectedTab, .home)
        XCTAssertEqual(appState.paths[.home], [])
    }

    func test_apply_editVehicle_opensVehicleEditor() {
        appState.apply(.editVehicle(vehicleID: vehicle.id), vehicles: [vehicle])

        XCTAssertEqual(appState.activeSheet?.id, ActiveSheet.editVehicle.id)
    }

    // MARK: - Service tap

    func test_apply_servicesTap_singleService_pushesItOnServices() {
        let services = addServices(dueInDays: [3])

        appState.apply(.services(vehicleID: vehicle.id, serviceIDs: [services[0].id]), vehicles: [vehicle])

        XCTAssertEqual(appState.selectedTab, .services)
        XCTAssertEqual(appState.paths[.services], [.service(services[0])])
        XCTAssertNil(appState.activeSheet)
    }

    func test_apply_servicesTap_bundle_opensServicesTab() {
        let services = addServices(dueInDays: [3, 5])
        appState.selectVehicle(vehicle)
        appState.paths[.services] = [.service(services[0])]

        appState.apply(.services(vehicleID: vehicle.id, serviceIDs: services.map(\.id)), vehicles: [vehicle])

        XCTAssertEqual(appState.selectedTab, .services)
        XCTAssertEqual(appState.paths[.services], [])
    }

    func test_serviceRoute_isASingleServiceTap() {
        let serviceID = UUID()
        XCTAssertEqual(
            PendingRoute.service(vehicleID: vehicle.id, serviceID: serviceID),
            .services(vehicleID: vehicle.id, serviceIDs: [serviceID])
        )
    }

    // MARK: - History and documents

    func test_apply_serviceLog_pushesItOnServices() {
        let log = ServiceLog(vehicle: vehicle, performedDate: .now, mileageAtService: 1_000)
        vehicle.serviceLogs = [log]

        appState.apply(.serviceLog(vehicleID: vehicle.id, logID: log.id), vehicles: [vehicle])

        XCTAssertEqual(appState.selectedTab, .services)
        XCTAssertEqual(appState.paths[.services], [.serviceLog(log)])
    }

    func test_apply_visit_pushesItOnCosts() {
        let visit = ServiceVisit(vehicle: vehicle, totalCost: 120)
        vehicle.serviceVisits = [visit]

        appState.apply(.visit(vehicleID: vehicle.id, visitID: visit.id), vehicles: [vehicle])

        XCTAssertEqual(appState.selectedTab, .costs)
        XCTAssertEqual(appState.paths[.costs], [.visit(visit)])
    }

    func test_apply_document_pushesItOverTheLibrary() {
        let document = Document(fileName: "insurance.pdf", mimeType: "application/pdf", documentType: .insurance)
        vehicle.documents = [document]

        appState.apply(.document(vehicleID: vehicle.id, documentID: document.id), vehicles: [vehicle])

        XCTAssertEqual(appState.selectedTab, .home)
        XCTAssertEqual(appState.paths[.home], [.documents(vehicle), .document(document)])
    }

    func test_apply_deletedDetail_opensItsTabRoot() {
        appState.apply(.serviceLog(vehicleID: vehicle.id, logID: UUID()), vehicles: [vehicle])
        XCTAssertEqual(appState.selectedTab, .services)
        XCTAssertEqual(appState.paths[.services], [])

        appState.apply(.visit(vehicleID: vehicle.id, visitID: UUID()), vehicles: [vehicle])
        XCTAssertEqual(appState.selectedTab, .costs)
        XCTAssertEqual(appState.paths[.costs], [])
    }

    // MARK: - Store

    func test_store_take_returnsRouteOnce() {
        let store = PendingRouteStore()
        store.route = .costs(vehicleID: vehicle.id)

        XCTAssertEqual(store.take(), .costs(vehicleID: vehicle.id))
        XCTAssertNil(store.take(), "A route navigates once")
    }

    // MARK: - Mark as Done

    private var markDoneRequest: MarkDoneRequest? {
        guard case .markDone(let request) = appState.activeSheet else { return nil }
        return request
    }

    func test_apply_markDone_requestsEveryStillDueService() {
        let services = addServices(dueInDays: [0, 4])

        appState.apply(.markDone(vehicleID: vehicle.id, serviceIDs: services.map(\.id)), vehicles: [vehicle])

        XCTAssertEqual(Set(markDoneRequest?.services.map(\.id) ?? []), Set(services.map(\.id)))
        XCTAssertEqual(markDoneRequest?.vehicle.id, vehicle.id)
    }

    func test_apply_markDone_skipsServicesAlreadyCompleted() {
        // Completed in the app since the banner arrived: due date moved months out.
        let services = addServices(dueInDays: [0, 180])

        appState.apply(.markDone(vehicleID: vehicle.id, serviceIDs: services.map(\.id)), vehicles: [vehicle])

        XCTAssertEqual(markDoneRequest?.services.map(\.id), [services[0].id])
    }

    func test_apply_markDone_allAlreadyCompleted_showsServicesInstead() {
        let services = addServices(dueInDays: [180])

        appState.apply(.markDone(vehicleID: vehicle.id, serviceIDs: services.map(\.id)), vehicles: [vehicle])

        XCTAssertNil(markDoneRequest)
        XCTAssertEqual(appState.selectedTab, .services)
    }

    // MARK: - Mileage Remind Tomorrow

    func test_mileageSnooze_replaysTheBannerUnderTheVehiclesReminderID() {
        let original = MileageReminderScheduler.buildMileageReminderRequest(
            vehicleName: "My Car", vehicleID: vehicle.id, reminderDate: .now
        )

        let snooze = MileageReminderScheduler.snoozeRequest(for: original)!

        XCTAssertEqual(snooze.identifier, MileageReminderScheduler.mileageReminderID(for: vehicle.id))
        XCTAssertEqual(snooze.content.body, original.content.body)
        let trigger = snooze.trigger as? UNCalendarNotificationTrigger
        let tomorrow = Calendar.current.dateComponents([.day], from: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
        XCTAssertEqual(trigger?.dateComponents.day, tomorrow.day)
    }
}
