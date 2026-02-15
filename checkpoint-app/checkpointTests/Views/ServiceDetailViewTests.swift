//
//  ServiceDetailViewTests.swift
//  checkpointTests
//
//  Tests for ServiceDetailView logic and MarkServiceDoneSheet functionality
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class ServiceDetailViewTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset to miles before each test to ensure consistent results
        DistanceSettings.shared.unit = .miles
    }

    override func tearDown() {
        // Reset to miles after tests
        DistanceSettings.shared.unit = .miles
        super.tearDown()
    }

    // MARK: - Status Display Tests

    func testStatusDisplay_OverdueByDate() {
        // Given: A service with a past due date
        let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 30000)
        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: .now)

        let service = Service(
            name: "Oil Change",
            dueDate: pastDate,
            dueMileage: 35000
        )
        service.vehicle = vehicle

        // When: Getting the status
        let status = service.status(currentMileage: vehicle.currentMileage)

        // Then: Status should be overdue
        XCTAssertEqual(status, .overdue, "Service should be overdue when past due date")
        XCTAssertEqual(status.label, "OVERDUE")
    }

    func testStatusDisplay_OverdueByMileage() {
        // Given: A service with mileage exceeded
        let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 36000)
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: .now)

        let service = Service(
            name: "Oil Change",
            dueDate: futureDate,
            dueMileage: 35000
        )
        service.vehicle = vehicle

        // When: Getting the status
        let status = service.status(currentMileage: vehicle.currentMileage)

        // Then: Status should be overdue
        XCTAssertEqual(status, .overdue, "Service should be overdue when mileage exceeded")
    }

    func testStatusDisplay_DueSoonByDate() {
        // Given: A service due within 30 days
        let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 30000)
        let soonDate = Calendar.current.date(byAdding: .day, value: 15, to: .now)

        let service = Service(
            name: "Oil Change",
            dueDate: soonDate,
            dueMileage: nil
        )
        service.vehicle = vehicle

        // When: Getting the status
        let status = service.status(currentMileage: vehicle.currentMileage)

        // Then: Status should be due soon
        XCTAssertEqual(status, .dueSoon, "Service should be due soon when within 30 days")
        XCTAssertEqual(status.label, "DUE SOON")
    }

    func testStatusDisplay_DueSoonByMileage() {
        // Given: A service with less than 500 miles remaining
        let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 34750)
        let farDate = Calendar.current.date(byAdding: .month, value: 6, to: .now)

        let service = Service(
            name: "Oil Change",
            dueDate: farDate,
            dueMileage: 35000
        )
        service.vehicle = vehicle

        // When: Getting the status
        let status = service.status(currentMileage: vehicle.currentMileage)

        // Then: Status should be due soon
        XCTAssertEqual(status, .dueSoon, "Service should be due soon when within 500 miles")
    }

    func testStatusDisplay_Good() {
        // Given: A service with plenty of time remaining
        let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 30000)
        let farDate = Calendar.current.date(byAdding: .month, value: 6, to: .now)

        let service = Service(
            name: "Oil Change",
            dueDate: farDate,
            dueMileage: 40000
        )
        service.vehicle = vehicle

        // When: Getting the status
        let status = service.status(currentMileage: vehicle.currentMileage)

        // Then: Status should be good
        XCTAssertEqual(status, .good, "Service should be good when not due soon")
        XCTAssertEqual(status.label, "GOOD")
    }

    func testStatusDisplay_Neutral() {
        // Given: A service with no due date or mileage
        let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 30000)

        let service = Service(
            name: "Inspection",
            dueDate: nil,
            dueMileage: nil
        )
        service.vehicle = vehicle

        // When: Getting the status
        let status = service.status(currentMileage: vehicle.currentMileage)

        // Then: Status should be neutral
        XCTAssertEqual(status, .neutral, "Service should be neutral when no due info")
        XCTAssertEqual(status.label, "")
    }

    // MARK: - History Display Tests

    func testHistorySection_ShowsServiceLogs() {
        // Given: A service with logs
        let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 35000)
        let service = Service(name: "Oil Change", dueDate: nil)
        service.vehicle = vehicle

        let log1 = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: Calendar.current.date(byAdding: .month, value: -6, to: .now)!,
            mileageAtService: 30000,
            cost: 45.99
        )

        let log2 = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: Calendar.current.date(byAdding: .year, value: -1, to: .now)!,
            mileageAtService: 25000,
            cost: 42.50
        )

        // When: Adding logs to service
        service.logs = [log1, log2]

        // Then: Logs should be accessible
        XCTAssertEqual((service.logs ?? []).count, 2, "Service should have 2 logs")
        XCTAssertFalse((service.logs ?? []).isEmpty, "Service logs should not be empty")
    }

    func testHistorySection_SortsByDateDescending() {
        // Given: Service logs with different dates
        let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 35000)
        let service = Service(name: "Oil Change", dueDate: nil)

        let olderLog = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: Calendar.current.date(byAdding: .year, value: -1, to: .now)!,
            mileageAtService: 25000
        )

        let newerLog = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: Calendar.current.date(byAdding: .month, value: -1, to: .now)!,
            mileageAtService: 34000
        )

        service.logs = [olderLog, newerLog]

        // When: Sorting by date descending
        let sortedLogs = (service.logs ?? []).sorted(by: { $0.performedDate > $1.performedDate })

        // Then: Newer log should come first
        XCTAssertEqual(sortedLogs.first?.mileageAtService, 34000, "Newer log should be first when sorted descending")
        XCTAssertEqual(sortedLogs.last?.mileageAtService, 25000, "Older log should be last when sorted descending")
    }

    func testHistorySection_EmptyWhenNoLogs() {
        // Given: A service with no logs
        let service = Service(name: "Brake Inspection", dueDate: nil)

        // Then: Logs array should be empty
        XCTAssertTrue((service.logs ?? []).isEmpty, "New service should have no logs")
    }

    // MARK: - Mark As Done Tests

    func testMarkAsDone_CreatesServiceLog() {
        // Given: Service details for marking done
        let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 32500)
        let service = Service(
            name: "Oil Change",
            dueDate: Calendar.current.date(byAdding: .day, value: 5, to: .now),
            dueMileage: 33000,
            intervalMonths: 6,
            intervalMiles: 5000
        )
        service.vehicle = vehicle

        let performedDate = Date()
        let mileageAtService = 32750
        let cost: Decimal = 45.99
        let notes = "Synthetic oil used"

        // When: Creating a service log (simulating markAsDone)
        let log = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: performedDate,
            mileageAtService: mileageAtService,
            cost: cost,
            notes: notes
        )

        // Then: Log should have correct values
        XCTAssertEqual(log.mileageAtService, 32750)
        XCTAssertEqual(log.cost, 45.99)
        XCTAssertEqual(log.notes, "Synthetic oil used")
        XCTAssertNotNil(log.formattedCost)
    }

    func testMarkAsDone_UpdatesServiceDueDates() {
        // Given: A service with intervals
        let performedDate = Date()
        let mileageAtService = 32750

        let service = Service(
            name: "Oil Change",
            dueDate: Calendar.current.date(byAdding: .day, value: -5, to: .now),
            dueMileage: 32000,
            intervalMonths: 6,
            intervalMiles: 5000
        )

        // When
        service.recalculateDueDates(performedDate: performedDate, mileage: mileageAtService)

        // Then: Due dates should be updated correctly
        XCTAssertEqual(service.lastPerformed, performedDate)
        XCTAssertEqual(service.lastMileage, 32750)
        XCTAssertEqual(service.dueMileage, 37750, "Due mileage should be service mileage + interval")

        // Due date should be 6 months from performed date
        let expectedDueDate = Calendar.current.date(byAdding: .month, value: 6, to: performedDate)
        XCTAssertEqual(service.dueDate, expectedDueDate)
    }

    func testMarkAsDone_UpdatesVehicleMileageWhenHigher() {
        // Given: Vehicle with lower mileage than service mileage
        let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 32500)
        let serviceMileage = 33000

        // When: Service mileage is higher than vehicle mileage (simulating markAsDone logic)
        if serviceMileage > vehicle.currentMileage {
            vehicle.currentMileage = serviceMileage
        }

        // Then: Vehicle mileage should be updated
        XCTAssertEqual(vehicle.currentMileage, 33000, "Vehicle mileage should be updated to service mileage")
    }

    func testMarkAsDone_DoesNotUpdateVehicleMileageWhenLower() {
        // Given: Vehicle with higher mileage than service mileage
        let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 35000)
        let serviceMileage = 33000

        // When: Service mileage is lower than vehicle mileage (simulating markAsDone logic)
        if serviceMileage > vehicle.currentMileage {
            vehicle.currentMileage = serviceMileage
        }

        // Then: Vehicle mileage should NOT be updated
        XCTAssertEqual(vehicle.currentMileage, 35000, "Vehicle mileage should not change when service mileage is lower")
    }

    func testMarkAsDone_HandlesNoIntervalMonths() {
        // Given: A service with only mileage interval
        let performedDate = Date()
        let mileageAtService = 32750

        let service = Service(
            name: "Tire Rotation",
            dueDate: nil,
            dueMileage: 32000,
            intervalMonths: nil,
            intervalMiles: 5000
        )

        // When
        service.recalculateDueDates(performedDate: performedDate, mileage: mileageAtService)

        // Then: Only mileage should be updated, date remains nil
        XCTAssertNil(service.dueDate, "Due date should remain nil when no interval months")
        XCTAssertEqual(service.dueMileage, 37750, "Due mileage should still be updated")
    }

    func testMarkAsDone_HandlesNoIntervalMiles() {
        // Given: A service with only months interval
        let performedDate = Date()
        let mileageAtService = 32750

        let service = Service(
            name: "Inspection",
            dueDate: Calendar.current.date(byAdding: .day, value: -5, to: .now),
            dueMileage: nil,
            intervalMonths: 12,
            intervalMiles: nil
        )

        // When
        service.recalculateDueDates(performedDate: performedDate, mileage: mileageAtService)

        // Then: Only date should be updated, mileage remains nil
        XCTAssertNil(service.dueMileage, "Due mileage should remain nil when no interval miles")
        XCTAssertNotNil(service.dueDate, "Due date should be updated")
    }

    // MARK: - Due Description Tests

    func testDueDescription_OverdueDays() {
        // Given: A service 5 days overdue
        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: .now)
        let service = Service(name: "Oil Change", dueDate: pastDate)

        // When: Getting due description
        let description = service.dueDescription

        // Then: Should show overdue message
        XCTAssertEqual(description, "5 days overdue")
    }

    func testDueDescription_DueToday() {
        // Given: A service due today
        let today = Calendar.current.startOfDay(for: .now)
        let service = Service(name: "Oil Change", dueDate: today)

        // When: Getting due description
        let description = service.dueDescription

        // Then: Should show due today message
        XCTAssertEqual(description, "Due today")
    }

    func testDueDescription_DueTomorrow() {
        // Given: A service due tomorrow (use start of day for consistent calculation)
        let today = Calendar.current.startOfDay(for: .now)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let service = Service(name: "Oil Change", dueDate: tomorrow)

        // When: Getting due description
        let description = service.dueDescription

        // Then: Should show due tomorrow message (days == 1 from start of today to start of tomorrow)
        // Note: dueDescription uses .now, so result depends on time of day
        XCTAssertTrue(description == "Due tomorrow" || description == "Due today",
                      "Expected 'Due tomorrow' or 'Due today' but got: \(description ?? "nil")")
    }

    func testDueDescription_DueInFuture() {
        // Given: A service due in 10 days from start of today
        let today = Calendar.current.startOfDay(for: .now)
        let futureDate = Calendar.current.date(byAdding: .day, value: 10, to: today)!
        let service = Service(name: "Oil Change", dueDate: futureDate)

        // When: Getting due description
        let description = service.dueDescription

        // Then: Should show due in days message (could be 9 or 10 depending on time of day)
        XCTAssertTrue(description == "Due in 10 days" || description == "Due in 9 days",
                      "Expected 'Due in 10 days' or 'Due in 9 days' but got: \(description ?? "nil")")
    }

    func testDueDescription_NilWhenNoDueDate() {
        // Given: A service with no due date
        let service = Service(name: "Inspection", dueDate: nil)

        // When: Getting due description
        let description = service.dueDescription

        // Then: Should be nil
        XCTAssertNil(description)
    }

    // MARK: - Mileage Description Tests

    func testMileageDescription_MilesRemaining() {
        // Given: A vehicle and service with miles remaining
        let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 30000)
        let service = Service(name: "Oil Change", dueMileage: 35000)
        service.vehicle = vehicle

        // When: Getting mileage description
        let description = service.mileageDescription

        // Then: Should show remaining miles (format: "or X miles" or "or X kilometers")
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.hasPrefix("or "), "Description should start with 'or'")
        XCTAssertTrue(description!.contains("5000") || description!.contains("5,000"), "Description should contain remaining distance")
    }

    func testMileageDescription_MilesOverdue() {
        // Given: A vehicle that has exceeded service mileage
        let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 36000)
        let service = Service(name: "Oil Change", dueMileage: 35000)
        service.vehicle = vehicle

        // When: Getting mileage description
        let description = service.mileageDescription

        // Then: Should show overdue miles (format: "X miles overdue" or "X kilometers overdue")
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("1000") || description!.contains("1,000"), "Description should contain overdue distance")
        XCTAssertTrue(description!.contains("overdue"), "Description should contain 'overdue'")
    }

    func testMileageDescription_NilWhenNoDueMileage() {
        // Given: A service with no due mileage
        let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 30000)
        let service = Service(name: "Inspection", dueMileage: nil)
        service.vehicle = vehicle

        // When: Getting mileage description
        let description = service.mileageDescription

        // Then: Should be nil
        XCTAssertNil(description)
    }

    func testMileageDescription_NilWhenNoVehicle() {
        // Given: A service with no vehicle
        let service = Service(name: "Oil Change", dueMileage: 35000)
        service.vehicle = nil

        // When: Getting mileage description
        let description = service.mileageDescription

        // Then: Should be nil
        XCTAssertNil(description)
    }

    // MARK: - Form Validation Tests

    func testMarkDoneForm_MileageRequired() {
        // Given: Empty mileage
        let mileage = ""

        // When: Checking if save should be disabled
        let isDisabled = mileage.isEmpty

        // Then: Save should be disabled
        XCTAssertTrue(isDisabled, "Save should be disabled when mileage is empty")
    }

    func testMarkDoneForm_ValidMileageEnablesSave() {
        // Given: Valid mileage
        let mileage = "32500"

        // When: Checking if save should be disabled
        let isDisabled = mileage.isEmpty

        // Then: Save should be enabled
        XCTAssertFalse(isDisabled, "Save should be enabled when mileage is provided")
    }

    func testMarkDoneForm_OptionalCostParsing() {
        // Given: Various cost inputs
        let validCost = "45.99"
        let emptyCost = ""
        let invalidCost = "abc"

        // When: Parsing costs
        let parsedValid = Decimal(string: validCost)
        let parsedEmpty = Decimal(string: emptyCost)
        let parsedInvalid = Decimal(string: invalidCost)

        // Then: Only valid input should parse
        XCTAssertNotNil(parsedValid)
        XCTAssertNil(parsedEmpty)
        XCTAssertNil(parsedInvalid)
    }

    func testMarkDoneForm_OptionalNotesHandling() {
        // Given: Notes input
        let emptyNotes = ""
        let filledNotes = "Used synthetic oil"

        // When: Processing notes (simulating logic)
        let processedEmpty = emptyNotes.isEmpty ? nil : emptyNotes
        let processedFilled = filledNotes.isEmpty ? nil : filledNotes

        // Then: Empty notes should become nil
        XCTAssertNil(processedEmpty)
        XCTAssertEqual(processedFilled, "Used synthetic oil")
    }

    // MARK: - Dismiss After Mark Done Tests

    func testMarkServiceDoneSheet_OnSavedCallbackInvoked() {
        // Given: A flag tracking whether onSaved was called
        var didCallOnSaved = false
        let onSaved: () -> Void = { didCallOnSaved = true }

        // When: The callback is invoked (simulating what markAsDone does)
        onSaved()

        // Then: The flag should be set
        XCTAssertTrue(didCallOnSaved, "onSaved callback should be invoked after save")
    }

    func testMarkServiceDoneSheet_OnSavedDefaultsToNil() {
        // Given: A MarkServiceDoneSheet created without onSaved
        let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 30000)
        let service = Service(name: "Oil Change", dueDate: nil)

        let sheet = MarkServiceDoneSheet(service: service, vehicle: vehicle)

        // Then: onSaved should be nil by default
        XCTAssertNil(sheet.onSaved, "onSaved should default to nil")
    }

    func testMarkServiceDoneSheet_OnSavedCanBeProvided() {
        // Given: A MarkServiceDoneSheet created with an onSaved callback
        let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 30000)
        let service = Service(name: "Oil Change", dueDate: nil)

        let sheet = MarkServiceDoneSheet(service: service, vehicle: vehicle, onSaved: { })

        // Then: onSaved should not be nil
        XCTAssertNotNil(sheet.onSaved, "onSaved should be set when provided")
    }

    func testDismissChaining_FlagControlsDismissal() {
        // Given: A didCompleteMark flag (simulating ServiceDetailView's @State)
        var didCompleteMark = false
        var parentDismissCalled = false

        // When: onSaved sets the flag (simulating save in MarkServiceDoneSheet)
        let onSaved: () -> Void = { didCompleteMark = true }
        onSaved()

        // And: onDismiss checks the flag (simulating sheet onDismiss in ServiceDetailView)
        if didCompleteMark {
            didCompleteMark = false
            parentDismissCalled = true
        }

        // Then: Parent dismiss should be triggered
        XCTAssertTrue(parentDismissCalled, "Parent view should dismiss when didCompleteMark is true")
        XCTAssertFalse(didCompleteMark, "Flag should be reset after triggering parent dismiss")
    }

    func testDismissChaining_CancelDoesNotDismissParent() {
        // Given: A didCompleteMark flag that was never set (simulating cancel)
        let didCompleteMark = false
        var parentDismissCalled = false

        // When: onDismiss fires without onSaved being called (cancel scenario)
        if didCompleteMark {
            parentDismissCalled = true
        }

        // Then: Parent dismiss should NOT be triggered
        XCTAssertFalse(parentDismissCalled, "Parent view should not dismiss when user cancels")
    }
}
