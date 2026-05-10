//
//  RecallAlertCardTests.swift
//  checkpointTests
//
//  Tests for the compact RecallAlertCard label logic and the worst-severity
//  computation that drives its appearance.
//

import XCTest
@testable import checkpoint

final class RecallAlertCardTests: XCTestCase {

    private func makeRecall(
        campaignNumber: String = "24V123",
        parkIt: Bool = false,
        parkOutside: Bool = false
    ) -> RecallInfo {
        RecallInfo(
            campaignNumber: campaignNumber,
            component: "TEST",
            summary: "",
            consequence: "",
            remedy: "",
            reportDate: "",
            parkIt: parkIt,
            parkOutside: parkOutside
        )
    }

    // MARK: - Worst Severity

    func test_worstSeverity_emptySet_returnsOpen() {
        XCTAssertEqual([RecallInfo]().worstSeverity, .open)
    }

    func test_worstSeverity_openOnly_returnsOpen() {
        let recalls = [makeRecall()]
        XCTAssertEqual(recalls.worstSeverity, .open)
    }

    func test_worstSeverity_parkOutsidePresent_returnsParkOutside() {
        let recalls = [makeRecall(parkOutside: true), makeRecall(campaignNumber: "X")]
        XCTAssertEqual(recalls.worstSeverity, .parkOutside)
    }

    func test_worstSeverity_parkItPresent_dominatesEverything() {
        let recalls = [
            makeRecall(parkOutside: true),
            makeRecall(campaignNumber: "X", parkIt: true, parkOutside: true)
        ]
        XCTAssertEqual(recalls.worstSeverity, .parkIt)
    }

    // MARK: - Severity → label mapping (mirrors RecallAlertCard.severityLabel)

    func test_severityLabel_doNotDrive_whenParkIt() {
        let label = labelFor([makeRecall(parkIt: true)])
        XCTAssertEqual(label, L10n.recallSeverityDoNotDrive.uppercased())
    }

    func test_severityLabel_parkOutside_whenOnlyParkOutside() {
        let label = labelFor([makeRecall(parkOutside: true)])
        XCTAssertEqual(label, L10n.recallSeverityParkOutside.uppercased())
    }

    func test_severityLabel_open_whenNeitherFlag() {
        let label = labelFor([makeRecall()])
        XCTAssertEqual(label, L10n.recallSeverityOpen.uppercased())
    }

    private func labelFor(_ recalls: [RecallInfo]) -> String {
        switch recalls.worstSeverity {
        case .parkIt: return L10n.recallSeverityDoNotDrive.uppercased()
        case .parkOutside: return L10n.recallSeverityParkOutside.uppercased()
        case .open: return L10n.recallSeverityOpen.uppercased()
        }
    }
}
