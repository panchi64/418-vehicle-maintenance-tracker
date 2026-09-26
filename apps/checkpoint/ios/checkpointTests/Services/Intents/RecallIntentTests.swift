//
//  RecallIntentTests.swift
//  checkpointTests
//
//  Check Recalls: what Home would show (resolved and snoozed hidden,
//  park-it always), what Siri says, and "add as planned service".
//

import XCTest
import SwiftData
@testable import checkpoint

extension CheckRecallsIntent: StoreBackedIntent {}

final class RecallIntentTests: IntentTestCase {

    private func recall(_ campaign: String, _ component: String, parkIt: Bool = false, reported: String = "01/15/2026") -> RecallInfo {
        RecallInfo(
            campaignNumber: campaign,
            component: component,
            summary: "Summary",
            consequence: "Consequence",
            remedy: "Remedy",
            reportDate: reported,
            parkIt: parkIt,
            parkOutside: false
        )
    }

    private func client(_ recalls: [RecallInfo]) -> StubNHTSA {
        StubNHTSA(recalls: .success(recalls))
    }

    func test_openRecalls_hidesResolvedAndSnoozed_keepsParkIt() async throws {
        let store = RecallAckStore(context: context)
        store.setStatus(.resolved, vehicleID: vehicle.id, campaignNumber: "R1")
        store.setStatus(.resolved, vehicleID: vehicle.id, campaignNumber: "P1")
        let recalls = [recall("R1", "AIR BAGS"), recall("O1", "FUEL PUMP"), recall("P1", "BRAKES", parkIt: true)]

        let open = try await CheckRecallsIntent.openRecalls(for: vehicle, in: context, using: client(recalls))

        XCTAssertEqual(Set(open.map(\.campaignNumber)), ["O1", "P1"])
    }

    func test_openRecalls_needsMakeModelAndYear() async {
        vehicle.year = 0
        do {
            _ = try await CheckRecallsIntent.openRecalls(for: vehicle, in: context, using: client([]))
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? IntentError, .recallsNeedIdentity)
        }
    }

    func test_openRecalls_offline_saysSo() async {
        do {
            _ = try await CheckRecallsIntent.openRecalls(for: vehicle, in: context, using: StubNHTSA(recalls: .failure(.networkUnavailable)))
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? IntentError, .recallsUnavailable)
        }
    }

    func test_summary_countsAndWarnsForParkIt() {
        let name = vehicle.displayName
        XCTAssertEqual(CheckRecallsIntent.summary([], vehicle: name), L10n.siriRecallsNone(vehicle: name))
        XCTAssertEqual(CheckRecallsIntent.summary([recall("A", "AIR BAGS")], vehicle: name),
                       L10n.siriRecallsOne(vehicle: name, component: "Air Bags"))
        let parkIt = CheckRecallsIntent.summary([recall("A", "AIR BAGS"), recall("B", "BRAKES", parkIt: true)], vehicle: name)
        XCTAssertEqual(parkIt, L10n.siriRecallsParkIt(L10n.siriRecallsMany(vehicle: name, count: 2, list: SpokenValue.list(["Air Bags", "Brakes"]))))
    }

    func test_plan_addsOneOffServices_andMarksThemScheduled() throws {
        let now = Date()
        let recalls = [recall("A", "AIR BAGS"), recall("B", "FUEL PUMP")]

        let added = try CheckRecallsIntent.plan(recalls, on: vehicle, in: context, now: now)

        XCTAssertEqual(added, 2)
        let planned = services.filter { $0.name == recalls[0].plannedServiceName }
        XCTAssertEqual(planned.count, 1)
        XCTAssertFalse(planned[0].isRecurring)
        XCTAssertEqual(planned[0].dueDate.map { Calendar.current.startOfDay(for: $0) },
                       Calendar.current.startOfDay(for: recalls[0].plannedServiceDueDate(from: now)))
        XCTAssertTrue(CheckRecallsIntent.unplanned(recalls, for: vehicle, in: context).isEmpty)
        XCTAssertFalse(context.hasChanges)
    }

    func test_plan_twice_addsNothingTheSecondTime() throws {
        let recalls = [recall("A", "AIR BAGS")]
        try CheckRecallsIntent.plan(recalls, on: vehicle, in: context)

        XCTAssertEqual(try CheckRecallsIntent.plan(recalls, on: vehicle, in: context), 0)
        XCTAssertEqual(services.count, 1)
    }

    func test_perform_withNoRecalls_answersWithoutAsking() async throws {
        CheckRecallsIntent.nhtsa = client([])
        defer { CheckRecallsIntent.nhtsa = NHTSAService.shared }

        _ = try await wired(CheckRecallsIntent()).perform()

        XCTAssertTrue(services.isEmpty)
    }
}
