//
//  ReceiptScan.swift
//  checkpoint
//
//  What Vision reads off a receipt photo, as plain typed values: the lines in
//  reading order, any tables, and the amounts and dates Vision's data
//  detectors found. Everything downstream (`ReceiptTextParser`, the
//  on-device model) reads this, never Vision's observation types — so the
//  readers are testable with a transcript typed into a test.
//
//  Untrusted input (Security Posture): nothing here reaches the model layer
//  until a reader has parsed it into typed fields.
//

import Foundation

nonisolated struct ReceiptScan: Equatable, Sendable {

    /// A value Vision's data detectors recognized, with the transcript line
    /// it sits on (nil when the line can't be told).
    nonisolated enum DetectedValue: Equatable, Sendable {
        case money(Decimal, line: Int?)
        case date(Date, line: Int?)
    }

    /// The text, top to bottom.
    var lines: [String]
    /// Table rows, each a list of cell texts. Receipts print their items as
    /// one; the model reads it as a grid rather than as loose lines.
    var tableRows: [[String]] = []
    var detected: [DetectedValue] = []

    init(lines: [String], tableRows: [[String]] = [], detected: [DetectedValue] = []) {
        self.lines = lines
        self.tableRows = tableRows
        self.detected = detected
    }

    /// A transcript split into lines, blank ones dropped.
    init(transcript: String, detected: [DetectedValue] = []) {
        self.init(
            lines: transcript
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty },
            detected: detected
        )
    }

    var transcript: String { lines.joined(separator: "\n") }

    var isEmpty: Bool { lines.isEmpty }
}
