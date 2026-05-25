//
//  MarkdownNotesEditingTests.swift
//  checkpointTests
//
//  Pure tests for the text manipulation that backs the rich notes
//  editor's BOLD / • / 1. toolbar buttons.
//

import XCTest
@testable import checkpoint

final class MarkdownNotesEditingTests: XCTestCase {

    // MARK: - Bold

    func testApplyBold_InsertsEmptyPairAtCursorWhenNothingSelected() {
        let result = MarkdownNotesEditing.applyBold(
            to: "abc",
            selection: NSRange(location: 1, length: 0)
        )
        XCTAssertEqual(result.text, "a****bc")
        // Cursor should land between the markers.
        XCTAssertEqual(result.selection, NSRange(location: 3, length: 0))
    }

    func testApplyBold_WrapsSelection() {
        let result = MarkdownNotesEditing.applyBold(
            to: "hello world",
            selection: NSRange(location: 6, length: 5) // "world"
        )
        XCTAssertEqual(result.text, "hello **world**")
        // Selection should remain on the now-bold word.
        XCTAssertEqual(result.selection, NSRange(location: 8, length: 5))
    }

    func testApplyBold_GracefullyHandlesOutOfBoundsSelection() {
        let result = MarkdownNotesEditing.applyBold(
            to: "short",
            selection: NSRange(location: 999, length: 0)
        )
        XCTAssertEqual(result.text, "short")
        XCTAssertEqual(result.selection, NSRange(location: 999, length: 0))
    }

    // MARK: - Bullet list

    func testApplyBulletList_PrefixesSingleLineWhenNoSelection() {
        let result = MarkdownNotesEditing.applyBulletList(
            to: "Replaced filter",
            selection: NSRange(location: 5, length: 0)
        )
        XCTAssertEqual(result.text, "- Replaced filter")
    }

    func testApplyBulletList_PrefixesMultipleSelectedLines() {
        let text = "Filter\nFluids\nBrakes"
        let result = MarkdownNotesEditing.applyBulletList(
            to: text,
            selection: NSRange(location: 0, length: text.count)
        )
        XCTAssertEqual(result.text, "- Filter\n- Fluids\n- Brakes")
    }

    func testApplyBulletList_LeavesAlreadyBulletedLinesAlone() {
        let text = "- Already a bullet\nNew item"
        let result = MarkdownNotesEditing.applyBulletList(
            to: text,
            selection: NSRange(location: 0, length: text.count)
        )
        XCTAssertEqual(result.text, "- Already a bullet\n- New item")
    }

    func testApplyBulletList_LeavesEmptyLinesAlone() {
        let text = "Line one\n\nLine three"
        let result = MarkdownNotesEditing.applyBulletList(
            to: text,
            selection: NSRange(location: 0, length: text.count)
        )
        XCTAssertEqual(result.text, "- Line one\n\n- Line three")
    }

    // MARK: - Numbered list

    func testApplyNumberedList_PrefixesEachLine() {
        let text = "First\nSecond"
        let result = MarkdownNotesEditing.applyNumberedList(
            to: text,
            selection: NSRange(location: 0, length: text.count)
        )
        XCTAssertEqual(result.text, "1. First\n1. Second")
    }

    func testApplyNumberedList_LeavesAlreadyNumberedLinesAlone() {
        let text = "1. Already numbered\nNew"
        let result = MarkdownNotesEditing.applyNumberedList(
            to: text,
            selection: NSRange(location: 0, length: text.count)
        )
        XCTAssertEqual(result.text, "1. Already numbered\n1. New")
    }

    func testApplyNumberedList_MultiDigitNumberedLineIsRecognized() {
        let text = "10. Tenth"
        let result = MarkdownNotesEditing.applyNumberedList(
            to: text,
            selection: NSRange(location: 0, length: text.count)
        )
        XCTAssertEqual(result.text, "10. Tenth")
    }

    // MARK: - Markdown rendering helper

    func testBrutalistMarkdown_RendersInlineBold() {
        // Should not throw; produces a non-empty attributed string for valid input.
        let attr = "Use **synthetic** oil".brutalistMarkdownAttributed
        XCTAssertFalse(String(attr.characters).isEmpty)
    }

    func testBrutalistMarkdown_FallsBackToPlainForMalformedInput() {
        // Even garbled input should never crash.
        let attr = "**unclosed bold".brutalistMarkdownAttributed
        XCTAssertFalse(String(attr.characters).isEmpty)
    }
}
