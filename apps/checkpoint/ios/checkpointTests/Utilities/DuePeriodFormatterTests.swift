//
//  DuePeriodFormatterTests.swift
//  checkpointTests
//
//  Tests for the abstracted month-period due descriptor used by Next Up cards.
//  Labels assert the English (source-language) output; the catalog supplies the
//  localized variants. Overdue is asserted via `isOverdue`, not the label, since
//  that flag is what callers branch on across locales.
//

import XCTest
@testable import checkpoint

final class DuePeriodFormatterTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    func test_pastDate_isOverdue() {
        let now = date(2026, 5, 20)
        let period = DuePeriodFormatter.describe(date(2026, 5, 10), relativeTo: now, calendar: calendar)
        XCTAssertTrue(period.isOverdue)
        XCTAssertEqual(period.label, "Overdue")
    }

    func test_withinSevenDays_isThisWeek() {
        let now = date(2026, 5, 20)
        XCTAssertEqual(DuePeriodFormatter.describe(now, relativeTo: now, calendar: calendar).label, "This week")
        XCTAssertEqual(DuePeriodFormatter.describe(date(2026, 5, 27), relativeTo: now, calendar: calendar).label, "This week")
    }

    func test_buckets_earlyMidLate() {
        let now = date(2026, 5, 1)
        // Day 8 is within a week of May 1 → this week; use a far month for buckets.
        XCTAssertEqual(DuePeriodFormatter.describe(date(2026, 8, 5), relativeTo: now, calendar: calendar).label, "Early Aug")
        XCTAssertEqual(DuePeriodFormatter.describe(date(2026, 8, 15), relativeTo: now, calendar: calendar).label, "Mid Aug")
        XCTAssertEqual(DuePeriodFormatter.describe(date(2026, 8, 25), relativeTo: now, calendar: calendar).label, "Late Aug")
    }

    func test_bucketBoundaries() {
        let now = date(2026, 5, 1)
        XCTAssertEqual(DuePeriodFormatter.describe(date(2026, 8, 10), relativeTo: now, calendar: calendar).label, "Early Aug")
        XCTAssertEqual(DuePeriodFormatter.describe(date(2026, 8, 11), relativeTo: now, calendar: calendar).label, "Mid Aug")
        XCTAssertEqual(DuePeriodFormatter.describe(date(2026, 8, 20), relativeTo: now, calendar: calendar).label, "Mid Aug")
        XCTAssertEqual(DuePeriodFormatter.describe(date(2026, 8, 21), relativeTo: now, calendar: calendar).label, "Late Aug")
    }

    func test_differentYear_appendsYear() {
        let now = date(2026, 5, 1)
        XCTAssertEqual(DuePeriodFormatter.describe(date(2027, 8, 5), relativeTo: now, calendar: calendar).label, "Early Aug 2027")
    }

    func test_sameYear_omitsYear() {
        let now = date(2026, 1, 1)
        XCTAssertEqual(DuePeriodFormatter.describe(date(2026, 12, 25), relativeTo: now, calendar: calendar).label, "Late Dec")
    }
}
