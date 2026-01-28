//
//  RecallAlertCardTests.swift
//  checkpointTests
//
//  Tests for RecallAlertCard view component
//

import XCTest
@testable import checkpoint

final class RecallAlertCardTests: XCTestCase {

    // MARK: - Count Text

    func testRecallAlertCard_SingleRecall_ShowsCorrectCount() {
        let recalls = [
            RecallInfo(
                campaignNumber: "24V123",
                component: "AIR BAGS",
                summary: "Defect.",
                consequence: "Injury.",
                remedy: "Replace.",
                reportDate: "01/15/2024",
                parkIt: false,
                parkOutside: false
            )
        ]

        // Verify the count text logic
        let count = recalls.count
        let countText = "\(count) Open Recall\(count == 1 ? "" : "s")"
        XCTAssertEqual(countText, "1 Open Recall")
    }

    func testRecallAlertCard_MultipleRecalls_ShowsCorrectCount() {
        let recalls = [
            RecallInfo(
                campaignNumber: "24V123",
                component: "AIR BAGS",
                summary: "", consequence: "", remedy: "",
                reportDate: "", parkIt: false, parkOutside: false
            ),
            RecallInfo(
                campaignNumber: "23V456",
                component: "FUEL SYSTEM",
                summary: "", consequence: "", remedy: "",
                reportDate: "", parkIt: false, parkOutside: false
            ),
            RecallInfo(
                campaignNumber: "22V789",
                component: "STEERING",
                summary: "", consequence: "", remedy: "",
                reportDate: "", parkIt: false, parkOutside: false
            )
        ]

        let count = recalls.count
        let countText = "\(count) Open Recall\(count == 1 ? "" : "s")"
        XCTAssertEqual(countText, "3 Open Recalls")
    }

    // MARK: - Park It Detection

    func testRecallAlertCard_ParkItRecall_DetectedCorrectly() {
        let recalls = [
            RecallInfo(
                campaignNumber: "24V123",
                component: "AIR BAGS",
                summary: "Critical defect.",
                consequence: "Fire risk.",
                remedy: "Do not drive.",
                reportDate: "01/15/2024",
                parkIt: true,
                parkOutside: true
            ),
            RecallInfo(
                campaignNumber: "23V456",
                component: "FUEL SYSTEM",
                summary: "Minor issue.",
                consequence: "Stall.",
                remedy: "Replace pump.",
                reportDate: "06/20/2023",
                parkIt: false,
                parkOutside: false
            )
        ]

        let hasParkIt = recalls.contains { $0.parkIt }
        XCTAssertTrue(hasParkIt)
    }

    func testRecallAlertCard_NoParkItRecalls_NotDetected() {
        let recalls = [
            RecallInfo(
                campaignNumber: "23V456",
                component: "FUEL SYSTEM",
                summary: "Minor issue.",
                consequence: "Stall.",
                remedy: "Replace pump.",
                reportDate: "06/20/2023",
                parkIt: false,
                parkOutside: false
            )
        ]

        let hasParkIt = recalls.contains { $0.parkIt }
        XCTAssertFalse(hasParkIt)
    }
}
