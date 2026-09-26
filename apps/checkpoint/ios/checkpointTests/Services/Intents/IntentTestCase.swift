//
//  IntentTestCase.swift
//  checkpointTests
//
//  Shared setup for App Intent tests: an in-memory store registered as the
//  intents' `@Dependency` container — the same registration the app makes at
//  launch — one selected vehicle, and miles as the distance unit.
//
//  Intents whose `perform()` asks Siri for confirmation can't run to the end
//  in a unit test (there is no Siri to answer), so their writes are exposed
//  as static functions and tested directly; `perform()` itself is run for
//  the intents that never ask.
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
class IntentTestCase: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var vehicle: Vehicle!

    private var savedSelection: String?
    private var savedUnit: DistanceUnit!

    private let selectionKey = AppGroupConstants.appSelectedVehicleIDKey

    override func setUp() {
        super.setUp()
        container = .inMemoryForTesting()
        context = container.mainContext
        IntentDependencies.register(container)

        savedSelection = UserDefaults.standard.string(forKey: selectionKey)
        savedUnit = DistanceSettings.shared.unit
        DistanceSettings.shared.unit = .miles

        vehicle = Vehicle(name: "Daily", make: "Honda", model: "Civic", year: 2020, currentMileage: 45_000)
        vehicle.mileageUpdatedAt = Date(timeIntervalSinceNow: -86_400 * 3)
        context.insert(vehicle)
        try! context.save()
        UserDefaults.standard.set(vehicle.id.uuidString, forKey: selectionKey)
    }

    override func tearDown() {
        if let savedSelection {
            UserDefaults.standard.set(savedSelection, forKey: selectionKey)
        } else {
            UserDefaults.standard.removeObject(forKey: selectionKey)
        }
        DistanceSettings.shared.unit = savedUnit
        container = nil
        context = nil
        vehicle = nil
        super.tearDown()
    }

    // MARK: - Fixtures

    @discardableResult
    func addService(
        _ name: String = "Oil Change",
        to vehicle: Vehicle? = nil,
        dueInDays days: Int? = 30,
        dueMileage: Int? = nil,
        intervalMonths: Int? = 6,
        intervalMiles: Int? = 5_000,
        isRecurring: Bool = true
    ) -> Service {
        let service = Service(
            name: name,
            dueDate: days.map { Calendar.current.date(byAdding: .day, value: $0, to: .now)! },
            dueMileage: dueMileage,
            lastPerformed: Calendar.current.date(byAdding: .month, value: -5, to: .now),
            lastMileage: 40_000,
            intervalMonths: intervalMonths,
            intervalMiles: intervalMiles,
            isRecurring: isRecurring
        )
        service.vehicle = vehicle ?? self.vehicle
        context.insert(service)
        return service
    }

    @discardableResult
    func addLog(
        for service: Service,
        daysAgo: Int,
        mileage: Int = 40_000,
        cost: Decimal? = nil
    ) -> ServiceLog {
        let log = ServiceLog(
            service: service,
            vehicle: service.vehicle,
            performedDate: Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!,
            mileageAtService: mileage,
            cost: cost,
            costCategory: cost == nil ? nil : .maintenance
        )
        context.insert(log)
        return log
    }

    var services: [Service] {
        (try? context.fetch(FetchDescriptor<Service>())) ?? []
    }

    var logs: [ServiceLog] {
        (try? context.fetch(FetchDescriptor<ServiceLog>())) ?? []
    }
}

/// Intents that read the store through `@Dependency var container`. Outside
/// the system's perform flow the dependency isn't looked up in
/// `AppDependencyManager` ("can only be accessed inside of the intent perform
/// flow … unless the value … is manually set"), so a test hands it in.
protocol StoreBackedIntent {
    var container: ModelContainer { get nonmutating set }
}

extension UpdateMileageIntent: StoreBackedIntent {}
extension GetMileageIntent: StoreBackedIntent {}
extension MarkServiceDoneIntent: StoreBackedIntent {}
extension MarkDoneFromSnippetIntent: StoreBackedIntent {}
extension LogServiceIntent: StoreBackedIntent {}
extension DeleteServiceLogIntent: StoreBackedIntent {}
extension AddServiceIntent: StoreBackedIntent {}
extension EditServiceIntent: StoreBackedIntent {}
extension SnoozeServiceIntent: StoreBackedIntent {}
extension StopTrackingServiceIntent: StoreBackedIntent {}
extension DeleteServiceIntent: StoreBackedIntent {}
extension CheckNextDueIntent: StoreBackedIntent {}
extension ListOverdueIntent: StoreBackedIntent {}
extension LastServiceQueryIntent: StoreBackedIntent {}
extension SpendingSummaryIntent: StoreBackedIntent {}
extension SearchCheckpointIntent: StoreBackedIntent {}
extension OpenDocumentFileIntent: StoreBackedIntent {}
@available(iOS 27, *) extension UpdateServiceReminderIntent: StoreBackedIntent {}
@available(iOS 27, *) extension DeleteServiceRemindersIntent: StoreBackedIntent {}

extension IntentTestCase {
    /// `intent`, reading and writing this test's store.
    func wired<Intent: StoreBackedIntent>(_ intent: Intent) -> Intent {
        intent.container = container
        return intent
    }

    /// Run an intent that asks Siri before writing, with no one to answer.
    /// The ask either fails at once or waits; after `seconds` the wait is
    /// cancelled. Either way nothing behind the ask may have been written —
    /// which is what callers assert.
    @MainActor
    func runUnanswered(seconds: Double = 1, _ work: @escaping @MainActor () async throws -> Void) async {
        let task = Task { @MainActor in try? await work() }
        let timeout = Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            task.cancel()
        }
        await task.value
        timeout.cancel()
    }
}
