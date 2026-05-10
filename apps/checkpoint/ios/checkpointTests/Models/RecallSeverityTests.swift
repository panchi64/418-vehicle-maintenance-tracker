//
//  RecallSeverityTests.swift
//  checkpointTests
//
//  Coverage for the severity bucketing + chronological-within-group order
//  used by RecallSheetView.
//

import XCTest
@testable import checkpoint

final class RecallSeverityTests: XCTestCase {

    private func makeRecall(
        campaignNumber: String,
        reportDate: String = "01/01/2024",
        parkIt: Bool = false,
        parkOutside: Bool = false
    ) -> RecallInfo {
        RecallInfo(
            campaignNumber: campaignNumber,
            component: "TEST",
            summary: "",
            consequence: "",
            remedy: "",
            reportDate: reportDate,
            parkIt: parkIt,
            parkOutside: parkOutside
        )
    }

    // MARK: - severity property

    func test_severity_parkIt_dominatesParkOutside() {
        let recall = makeRecall(campaignNumber: "X", parkIt: true, parkOutside: true)
        XCTAssertEqual(recall.severity, .parkIt)
    }

    func test_severity_parkOutsideOnly() {
        let recall = makeRecall(campaignNumber: "X", parkOutside: true)
        XCTAssertEqual(recall.severity, .parkOutside)
    }

    func test_severity_neitherFlag_isOpen() {
        let recall = makeRecall(campaignNumber: "X")
        XCTAssertEqual(recall.severity, .open)
    }

    // MARK: - groupedBySeverity

    func test_groupedBySeverity_orderingIsHighestFirst() {
        let recalls = [
            makeRecall(campaignNumber: "open"),
            makeRecall(campaignNumber: "parkIt", parkIt: true),
            makeRecall(campaignNumber: "outside", parkOutside: true)
        ]
        let groups = recalls.groupedBySeverity()
        XCTAssertEqual(groups.map(\.severity), [.parkIt, .parkOutside, .open])
    }

    func test_groupedBySeverity_emptyBucketsAreOmitted() {
        let recalls = [makeRecall(campaignNumber: "1"), makeRecall(campaignNumber: "2")]
        let groups = recalls.groupedBySeverity()
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.severity, .open)
    }

    func test_groupedBySeverity_withinGroupSortedNewestFirst() {
        let recalls = [
            makeRecall(campaignNumber: "old", reportDate: "01/01/2022"),
            makeRecall(campaignNumber: "new", reportDate: "12/01/2024"),
            makeRecall(campaignNumber: "mid", reportDate: "06/15/2023")
        ]
        let groups = recalls.groupedBySeverity()
        let ids = groups.first?.recalls.map(\.campaignNumber) ?? []
        XCTAssertEqual(ids, ["new", "mid", "old"])
    }

    func test_groupedBySeverity_emptyInput_returnsEmpty() {
        XCTAssertTrue([RecallInfo]().groupedBySeverity().isEmpty)
    }
}
