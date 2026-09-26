//
//  SystemSchemaTests.swift
//  checkpointTests
//
//  In-app search (`.system.search` / `.system.searchInApp`), the routes the
//  open intents hand the app, how the app applies the new search routes,
//  and the entity tags on reminder notifications.
//

import XCTest
import AppIntents
import SwiftData
import UserNotifications
@testable import checkpoint

final class SystemSchemaTests: IntentTestCase {

    // MARK: - Search

    func test_search_opensServices_whenAServiceMatches() throws {
        addService("Brake Pads")
        try context.save()
        XCTAssertEqual(
            try InAppSearch.route(for: " brake ", in: context),
            .searchServices(vehicleID: vehicle.id, term: "brake")
        )
    }

    func test_search_opensDocuments_whenOnlyADocumentMatches() throws {
        addService("Oil Change")
        let card = Document(fileName: "insurance_card.jpg", mimeType: "image/jpeg", vehicles: [vehicle])
        card.extractedText = "POLICY 0000-SYNTHETIC"
        context.insert(card)
        try context.save()

        XCTAssertEqual(
            try InAppSearch.route(for: "policy", in: context),
            .searchDocuments(vehicleID: vehicle.id, term: "policy")
        )
    }

    func test_search_withNoMatch_opensServices() throws {
        XCTAssertEqual(
            try InAppSearch.route(for: "tint", in: context),
            .searchServices(vehicleID: vehicle.id, term: "tint")
        )
    }

    func test_searchIntent_handsTheRouteToTheApp() async throws {
        PendingRouteStore.shared.route = nil
        let intent = wired(SearchCheckpointIntent())
        intent.criteria = StringSearchCriteria(term: "oil")

        _ = try await intent.perform()

        XCTAssertEqual(PendingRouteStore.shared.take(), .searchServices(vehicleID: vehicle.id, term: "oil"))
    }

    func test_applyingSearchRoutes_fillsTheRightSearchField() {
        let state = AppState()

        state.apply(.searchServices(vehicleID: vehicle.id, term: "brake"), vehicles: [vehicle])
        XCTAssertEqual(state.selectedTab, .services)
        XCTAssertEqual(state.servicesTab.searchText, "brake")

        state.apply(.searchDocuments(vehicleID: vehicle.id, term: "policy"), vehicles: [vehicle])
        XCTAssertEqual(state.selectedTab, .home)
        XCTAssertEqual(state.paths[.home], [.documents(vehicle)])
        XCTAssertEqual(state.documentsSearchSeed, "policy")
    }

    // MARK: - Open routes

    func test_openRoutes_landOnEachRecord() throws {
        let oil = addService("Oil Change")
        let log = addLog(for: oil, daysAgo: 10)
        try context.save()

        XCTAssertEqual(try EntityRoutes.vehicle(vehicle.id, in: context), .vehicle(vehicleID: vehicle.id))
        XCTAssertEqual(try EntityRoutes.service(oil.id, in: context), .service(vehicleID: vehicle.id, serviceID: oil.id))
        XCTAssertEqual(try EntityRoutes.serviceLog(log.id, in: context), .serviceLog(vehicleID: vehicle.id, logID: log.id))
        XCTAssertThrowsError(try EntityRoutes.visit(UUID(), in: context)) {
            XCTAssertEqual($0 as? IntentError, .visitNotFound)
        }
        XCTAssertThrowsError(try EntityRoutes.service(UUID(), in: context)) {
            XCTAssertEqual($0 as? IntentError, .serviceNotFound)
        }
    }

    // MARK: - Notification entity tags

    func test_entityTags_nameEachServiceThenTheVehicle() {
        let serviceID = UUID()
        let identifiers = NotificationEntityTags.identifiers(serviceIDs: [serviceID], vehicleID: vehicle.id)

        XCTAssertEqual(identifiers.first, EntityIdentifier(for: ServiceEntity.self, identifier: serviceID))
        XCTAssertEqual(identifiers.last, EntityIdentifier(for: VehicleEntity.self, identifier: vehicle.id))
        if #available(iOS 27, *) {
            XCTAssertTrue(identifiers.contains(EntityIdentifier(for: ServiceReminderEntity.self, identifier: serviceID)))
            XCTAssertEqual(identifiers.count, 3)
        } else {
            XCTAssertEqual(identifiers.count, 2)
        }
        XCTAssertEqual(
            NotificationEntityTags.identifiers(serviceIDs: [], vehicleID: vehicle.id),
            [EntityIdentifier(for: VehicleEntity.self, identifier: vehicle.id)]
        )
    }

    func test_reminderRequests_areTagged() throws {
        guard #available(iOS 27, *) else { throw XCTSkip("Notification entity tags are iOS 27") }
        let oil = addService("Oil Change")
        let vehicleOnly = [EntityIdentifier(for: VehicleEntity.self, identifier: vehicle.id)]

        let snooze = ServiceNotificationScheduler.snoozeRequest(for: oil, vehicle: vehicle)
        XCTAssertEqual(
            tags(snooze),
            NotificationEntityTags.identifiers(serviceIDs: [oil.id], vehicleID: vehicle.id),
            "SERVICE_DUE"
        )

        let mileage = MileageReminderScheduler.buildMileageReminderRequest(
            vehicleName: vehicle.displayName, vehicleID: vehicle.id, reminderDate: .now
        )
        XCTAssertEqual(tags(mileage), vehicleOnly, "MILEAGE_REMINDER")

        let marbete = MarbeteNotificationScheduler.buildMarbeteNotificationRequest(
            vehicleName: vehicle.displayName, vehicleID: vehicle.id, notificationDate: .now, daysBeforeDue: 30
        )
        XCTAssertEqual(tags(marbete), vehicleOnly, "MARBETE_DUE")

        let roundup = YearlyRoundupScheduler.buildYearlyRoundupRequest(
            vehicleName: vehicle.displayName, vehicleID: vehicle.id, year: 2025, totalCost: 100, notificationDate: .now
        )
        XCTAssertEqual(tags(roundup), vehicleOnly, "YEARLY_ROUNDUP")
    }

    @available(iOS 27, *)
    private func tags(_ request: UNNotificationRequest) -> [EntityIdentifier]? {
        (request.content.mutableCopy() as? UNMutableNotificationContent)?.appEntityIdentifiers
    }
}
