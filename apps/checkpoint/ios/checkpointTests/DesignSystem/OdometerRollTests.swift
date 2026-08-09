//
//  OdometerRollTests.swift
//  checkpointTests
//
//  The arithmetic behind RollingNumberText. Everything here is about the two
//  properties that make the effect read as mechanical rather than as digits
//  being swapped: every wheel turns the same way, and a wheel keeps its
//  identity across a change in the number of digits.
//

import XCTest
@testable import checkpoint

final class OdometerRollTests: XCTestCase {

    // MARK: - Cells

    func testDigitsArePlacedFromTheRight() {
        let cells = OdometerRoll.cells(in: "1,205")

        XCTAssertEqual(cells.map(\.character), ["1", ",", "2", "0", "5"])
        XCTAssertEqual(cells.map(\.place), [3, nil, 2, 1, 0])
        XCTAssertEqual(cells.compactMap { $0.place != nil ? $0.digit : nil }, [1, 2, 0, 5])
    }

    func testOnesWheelKeepsItsIdentityWhenTheValueGainsADigit() {
        let before = OdometerRoll.cells(in: "999 mi")
        let after = OdometerRoll.cells(in: "1,000 mi")

        // Place 0 is the ones wheel in both, so ForEach reuses it and it rolls
        // rather than being torn down and popped in.
        XCTAssertEqual(before.first(where: { $0.place == 0 })?.id, "digit-0")
        XCTAssertEqual(after.first(where: { $0.place == 0 })?.id, "digit-0")
    }

    func testTrailingUnitKeepsItsIdentityAcrossADigitGain() {
        let before = OdometerRoll.cells(in: "999 mi")
        let after = OdometerRoll.cells(in: "1,000 mi")

        let unitIDs = { (cells: [OdometerRoll.Cell]) in
            cells.filter { $0.place == nil }.map(\.id).suffix(3)
        }
        XCTAssertEqual(Array(unitIDs(before)), Array(unitIDs(after)))
    }

    func testGroupingSeparatorIsKeyedByTheDigitsThatFollowIt() {
        // The thousands separator always has three digits to its right, so it
        // stays the same cell whether the value is five digits or six.
        let five = OdometerRoll.cells(in: "18,200").first { $0.character == "," }
        let six = OdometerRoll.cells(in: "118,200").first { $0.character == "," }

        XCTAssertEqual(five?.id, "sep-3-,")
        XCTAssertEqual(six?.id, "sep-3-,")
    }

    func testNonASCIIDigitsAreNotRolled() {
        // Arabic-Indic numerals fall through to the static path rather than
        // rolling ASCII glyphs in their place.
        let cells = OdometerRoll.cells(in: "٤٢")

        XCTAssertTrue(cells.allSatisfy { $0.place == nil })
    }

    // MARK: - Direction

    func testDirectionFollowsMagnitude() {
        XCTAssertEqual(OdometerRoll.direction(from: "18,200", to: "19,487"), 1)
        XCTAssertEqual(OdometerRoll.direction(from: "19,487", to: "18,200"), -1)
    }

    func testDirectionUsesDigitCountBeforeComparingDigits() {
        // "1000" sorts before "999" lexicographically; it must still read as up.
        XCTAssertEqual(OdometerRoll.direction(from: "999", to: "1,000"), 1)
        XCTAssertEqual(OdometerRoll.direction(from: "1,000", to: "999"), -1)
    }

    func testEqualMagnitudeRollsForward() {
        // A formatting-only change — a unit switch, an estimate marker
        // appearing — should still turn the wheels rather than sit still.
        XCTAssertEqual(OdometerRoll.direction(from: "500 mi", to: "500 km"), 1)
    }

    // MARK: - Advancing

    func testFirstRenderSetsWheelsWithoutRolling() {
        let positions = OdometerRoll.advance([:], to: "418", from: "", animated: false)

        XCTAssertEqual(positions, [2: 4, 1: 1, 0: 8])
    }

    func testWheelsAdvanceByTheirDelta() {
        let start = OdometerRoll.advance([:], to: "120", from: "", animated: false)
        let next = OdometerRoll.advance(start, to: "123", from: "120", animated: true)

        XCTAssertEqual(next[0], 3, "ones wheel rolls 0 → 3")
        XCTAssertEqual(next[1], 2, "unchanged wheels stay put")
        XCTAssertEqual(next[2], 1)
    }

    func testCarryRollsForwardPastNineRatherThanBackwards() {
        let start = OdometerRoll.advance([:], to: "199", from: "", animated: false)
        let next = OdometerRoll.advance(start, to: "201", from: "199", animated: true)

        // 9 → 1 the short way is -8. Going up, both nines must instead continue
        // forward through 0, which is +2 and +1 on an accumulating position.
        XCTAssertEqual(next[0], 11, "ones wheel passes through 0")
        XCTAssertEqual(next[1], 10, "tens wheel passes through 0")
        XCTAssertEqual(next[2], 2)
    }

    func testEveryWheelTurnsTheSameWayOnACascade() {
        let start = OdometerRoll.advance([:], to: "39,999", from: "", animated: false)
        let next = OdometerRoll.advance(start, to: "40,000", from: "39,999", animated: true)

        // The four nines each advance by one rather than spinning back nine
        // places while the ten-thousands wheel advances.
        for place in 0...3 {
            XCTAssertEqual(next[place], 10, "wheel \(place) should roll forward through 0")
        }
        XCTAssertEqual(next[4], 4)
    }

    func testDecreasingValuesRollBackwardsPastZero() {
        let start = OdometerRoll.advance([:], to: "201", from: "", animated: false)
        let next = OdometerRoll.advance(start, to: "199", from: "201", animated: true)

        // Both wheels go negative rather than spinning forward eight or nine
        // places, and a negative position still resolves to the right glyph.
        XCTAssertEqual(next[0], -1, "ones wheel rolls back through 0")
        XCTAssertEqual(next[1], -1, "tens wheel rolls back through 0")
        XCTAssertEqual(next[2], 1)
        XCTAssertEqual(OdometerRoll.wrapped(Int(next[0]!)), 9)
        XCTAssertEqual(OdometerRoll.wrapped(Int(next[1]!)), 9)
    }

    func testAccumulatedPositionsChainAcrossRepeatedUpdates() {
        var positions = OdometerRoll.advance([:], to: "8", from: "", animated: false)
        positions = OdometerRoll.advance(positions, to: "13", from: "8", animated: true)
        positions = OdometerRoll.advance(positions, to: "18", from: "13", animated: true)

        // 8 → 13 → 18 on an unbounded position: the wheel never resets, so the
        // glyph it shows is the position modulo ten and each roll continues
        // from where the last one landed.
        XCTAssertEqual(positions[0], 18)
        XCTAssertEqual(OdometerRoll.wrapped(Int(positions[0]!)), 8)
    }

    func testNewlyGainedPlaceIsSetRatherThanRolled() {
        let start = OdometerRoll.advance([:], to: "999", from: "", animated: false)
        let next = OdometerRoll.advance(start, to: "1,000", from: "999", animated: true)

        // The thousands wheel has no history, so it appears showing 1 instead
        // of rolling from a digit it never displayed.
        XCTAssertEqual(next[3], 1)
        XCTAssertEqual(next.count, 4)
    }

    func testDroppedPlacesAreDiscarded() {
        let start = OdometerRoll.advance([:], to: "1,000", from: "", animated: false)
        let next = OdometerRoll.advance(start, to: "999", from: "1,000", animated: true)

        XCTAssertNil(next[3], "the thousands wheel is gone, not left stale")
        XCTAssertEqual(next.count, 3)
    }

    func testSeparatorsDoNotOccupyWheels() {
        let positions = OdometerRoll.advance([:], to: "$1,234.56", from: "", animated: false)

        XCTAssertEqual(positions.count, 6, "six digits, six wheels")
        XCTAssertEqual(positions[0], 6, "the cents ones place is wheel 0")
    }

    // MARK: - Wrapping

    func testWrappedHandlesAccumulatedAndNegativePositions() {
        XCTAssertEqual(OdometerRoll.wrapped(0), 0)
        XCTAssertEqual(OdometerRoll.wrapped(7), 7)
        XCTAssertEqual(OdometerRoll.wrapped(13), 3)
        XCTAssertEqual(OdometerRoll.wrapped(-1), 9)
        XCTAssertEqual(OdometerRoll.wrapped(-12), 8)
    }
}
