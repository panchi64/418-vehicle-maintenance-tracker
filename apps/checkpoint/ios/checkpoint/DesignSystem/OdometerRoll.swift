//
//  OdometerRoll.swift
//  checkpoint
//
//  The arithmetic behind `RollingNumberText`, kept out of the view so it can be
//  tested. Everything here is a pure function of strings and numbers; nothing
//  in this file knows about SwiftUI.
//
//  The one idea worth holding onto: a digit wheel's state is an *unbounded,
//  accumulating position*, not a 0–9 value. That is what lets 9 → 0 continue
//  forward instead of spinning nine places backwards, and it is why the
//  functions below deal in deltas rather than absolute digits.
//

import Foundation

enum OdometerRoll {

    // MARK: - Cells

    /// One character of the formatted string.
    struct Cell: Identifiable, Equatable {
        let id: String
        let character: Character
        /// Digit place counted from the right (`0` is the ones place).
        /// Nil for anything that isn't a rollable digit.
        let place: Int?
        let digit: Int
    }

    /// Splits a formatted value into per-character cells with stable identities.
    ///
    /// Identity matters more than it looks: `ForEach` uses it to decide what
    /// survives an update, and a wheel that loses identity loses its
    /// accumulated position and pops instead of rolling.
    ///
    /// Digits key off their place from the right, so the ones wheel stays the
    /// ones wheel when a value gains or loses a digit. Separators key off
    /// whichever end anchors them — a leading `"$"` by its offset from the
    /// left, a trailing `" mi"` by its offset from the right, and a grouping
    /// separator by how many digits follow it, which is exactly the thing that
    /// holds it in place across `999 → 1,000`.
    static func cells(in text: String) -> [Cell] {
        let characters = Array(text)
        let totalDigits = characters.count(where: isRollableDigit)

        var digitsPassed = 0
        return characters.enumerated().map { index, character in
            if isRollableDigit(character) {
                let place = totalDigits - digitsPassed - 1
                digitsPassed += 1
                return Cell(
                    id: "digit-\(place)",
                    character: character,
                    place: place,
                    digit: character.wholeNumberValue ?? 0
                )
            }

            let id: String
            if digitsPassed == 0 {
                id = "lead-\(index)-\(character)"
            } else if digitsPassed == totalDigits {
                id = "trail-\(characters.count - index)-\(character)"
            } else {
                id = "sep-\(totalDigits - digitsPassed)-\(character)"
            }
            return Cell(id: id, character: character, place: nil, digit: 0)
        }
    }

    // MARK: - Advancing the wheels

    /// The new wheel positions for `newText`, given where the wheels are now.
    ///
    /// - Parameters:
    ///   - positions: current positions, keyed by place from the right. These
    ///     are *targets* rather than in-flight values, so an update that lands
    ///     mid-roll chains from where the wheel was headed instead of fighting
    ///     the animation.
    ///   - newText / oldText: formatted values, used for the digits and for
    ///     which way the whole readout moved.
    ///   - animated: when false, every wheel is set outright. Used for the
    ///     first render — a card scrolling into view should show its number,
    ///     not perform for having been looked at.
    static func advance(
        _ positions: [Int: Double],
        to newText: String,
        from oldText: String,
        animated: Bool
    ) -> [Int: Double] {
        let digits = digitsByPlace(in: newText)
        let heading = direction(from: oldText, to: newText)

        var next: [Int: Double] = [:]
        for (place, digit) in digits {
            // A place with no history — first render, or a digit the value just
            // grew into — is set rather than rolled. Rolling it would mean
            // inventing a previous digit for it.
            guard animated, let current = positions[place] else {
                next[place] = Double(digit)
                continue
            }

            var delta = digit - wrapped(Int(current.rounded()))
            // Push the move onto the side the value went, so every wheel turns
            // the same way. Without this, 39,999 → 40,000 would have four
            // wheels spinning backwards while one advanced.
            if delta != 0 {
                if heading >= 0, delta < 0 { delta += 10 }
                if heading < 0, delta > 0 { delta -= 10 }
            }
            next[place] = current + Double(delta)
        }

        // Places the new value dropped are discarded, so a number that shrinks
        // and grows again starts that wheel fresh rather than from a stale one.
        return next
    }

    /// `1` to roll forward, `-1` to roll back.
    ///
    /// Compared as digit strings rather than parsed numbers: a seven-figure
    /// total or a mileage with decimals shouldn't be able to overflow or lose
    /// precision on the way to a yes/no answer.
    static func direction(from old: String, to new: String) -> Int {
        let before = significantDigits(of: old)
        let after = significantDigits(of: new)
        if before.count != after.count { return before.count < after.count ? 1 : -1 }
        // Equal magnitude with different formatting — a unit switch, an
        // estimate marker appearing — rolls forward. Standing still would read
        // as the effect being broken.
        return before <= after ? 1 : -1
    }

    // MARK: - Digits

    /// Only ASCII digits roll. A locale rendering Arabic-Indic numerals falls
    /// through to the static path rather than rolling the wrong glyphs.
    static func isRollableDigit(_ character: Character) -> Bool {
        character.isASCII && character.isNumber
    }

    static func digitsByPlace(in text: String) -> [Int: Int] {
        text.filter(isRollableDigit)
            .reversed()
            .enumerated()
            .reduce(into: [:]) { result, pair in
                result[pair.offset] = pair.element.wholeNumberValue ?? 0
            }
    }

    /// The glyph a position shows, for positions that have accumulated well
    /// past 9 or dropped below 0.
    static func wrapped(_ value: Int) -> Int {
        ((value % 10) + 10) % 10
    }

    private static func significantDigits(of text: String) -> String {
        String(text.filter(isRollableDigit).drop(while: { $0 == "0" }))
    }
}
