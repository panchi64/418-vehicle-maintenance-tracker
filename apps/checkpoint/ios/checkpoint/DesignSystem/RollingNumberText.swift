//
//  RollingNumberText.swift
//  checkpoint
//
//  A Text-shaped readout whose digits roll like the wheels of a mechanical
//  odometer when the value changes.
//
//  WHY NOT `.contentTransition(.numericText())`:
//  The built-in transition slides only the glyphs that differ, and it cuts
//  straight from the old digit to the new one. A wheel that goes 7 → 2 by
//  passing through 8, 9, 0, 1 is the thing that reads as *mechanical*, and
//  that is the whole point of the effect in an app about odometers. The
//  built-in transition is still what we fall back to under Reduce Motion.
//
//  HOW IT WORKS:
//  The formatted string is split into cells — one per character. Digits get a
//  `DigitWheel`, an `Animatable` view that re-renders its glyph as its position
//  is interpolated, so the digits in between are genuinely drawn. Everything
//  else — currency symbols, grouping separators, "~", " mi" — renders as
//  ordinary `Text`. The arithmetic lives in `OdometerRoll`.
//
//  USAGE — it takes the environment font and foreground style like `Text`:
//
//      RollingNumberText(Formatters.mileage(vehicle.currentMileage))
//          .font(.brutalistBody)
//          .foregroundStyle(Theme.accent)
//
//  Use it for QUANTITIES ONLY. Identifiers that happen to contain digits — a
//  plate, an oil grade, a VIN — must stay plain `Text`; animating one as though
//  it were a measurement is a lie about what kind of value it is.
//
//  LIMITATIONS (deliberate, and why):
//    - `.minimumScaleFactor` can't be applied from outside: each cell is its
//      own `Text`, so SwiftUI would scale neighbours independently. Pass the
//      `minimumScaleFactor:` parameter instead.
//    - `.tracking()` does not carry across cells. Numeric readouts in this app
//      don't track; labels do, and labels don't roll.
//

import SwiftUI

struct RollingNumberText: View {
    private let text: String
    private let minimumScaleFactor: CGFloat
    private let resetToken: AnyHashable?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Digit place (counted from the right) → continuous wheel position.
    @State private var positions: [Int: Double] = [:]
    /// The value the wheels are settled on. Nil until first layout, which is
    /// how the initial render knows not to roll up from zero.
    @State private var settledText: String?
    /// The subject those wheels belong to. Compared against `resetToken` to
    /// tell "this number moved" apart from "we're now showing a different
    /// thing's number".
    @State private var settledToken: AnyHashable?

    /// - Parameters:
    ///   - text: the fully formatted value, e.g. `"33,417 mi"` or `"$1,234"`.
    ///     Formatting stays the caller's job so `Formatters` and locale rules
    ///     remain the single source of truth for how a number looks.
    ///   - minimumScaleFactor: pass a value below 1 to let a long value shrink
    ///     to the available width, as `Text` would. Doing so makes the view
    ///     width-greedy (it claims the full proposed width and left-aligns
    ///     within it), because it has to know the width to compute the scale.
    ///     At the default of 1 the view sizes to its content like `Text`.
    ///   - resetToken: identifies *which* thing is being measured. When it
    ///     changes, the next value is set rather than rolled.
    ///
    ///     Pass this wherever one readout is reused across subjects. The
    ///     odometer is the case that forced it: `VehicleSummaryBand` stays on
    ///     screen across a vehicle switch, so picking a different vehicle changes the text,
    ///     and without a token the wheels spin 120,000 → 8,000 as though a car
    ///     had un-driven 112,000 miles. Rolling means "this number moved"; a
    ///     different subject's number did not move.
    init(
        _ text: String,
        minimumScaleFactor: CGFloat = 1,
        resetToken: AnyHashable? = nil
    ) {
        self.text = text
        self.minimumScaleFactor = min(max(minimumScaleFactor, 0.1), 1)
        self.resetToken = resetToken
    }

    var body: some View {
        content
            .monospacedDigit()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
            .onAppear {
                if settledText == nil { roll(to: text, animated: false) }
            }
            // Both can change in the same update. `roll` compares tokens itself
            // rather than depending on which handler SwiftUI runs first, so
            // whichever lands first performs the reset and the other is a
            // no-op against an already-settled value.
            .onChange(of: resetToken) { _, _ in
                roll(to: text, animated: true)
            }
            .onChange(of: text) { _, newValue in
                roll(to: newValue, animated: true)
            }
    }

    /// Nothing to roll — no ASCII digits anywhere in the value. Covers the "-"
    /// that the Costs stats show when there isn't enough data to compute one,
    /// the header's "—" for a vehicle with no specs, and locales that render
    /// numerals outside ASCII. Falling through to the wheels would build a
    /// per-cell geometry observer and a scale-to-fit container around a static
    /// glyph, and would swap `Text`'s truncation and empty-string line height
    /// for the row's.
    private var isStatic: Bool {
        !text.contains(where: OdometerRoll.isRollableDigit)
    }

    @ViewBuilder
    private var content: some View {
        if reduceMotion || isStatic {
            Text(text)
                .contentTransition(.numericText())
                .lineLimit(1)
                .truncationMode(.tail)
                .minimumScaleFactor(minimumScaleFactor)
        } else if minimumScaleFactor < 1 {
            ScaleToFitWidth(minimumScaleFactor: minimumScaleFactor) { wheelRow }
        } else {
            wheelRow
        }
    }

    private var wheelRow: some View {
        HStack(spacing: 0) {
            ForEach(OdometerRoll.cells(in: text)) { cell in
                if let place = cell.place {
                    DigitCell(
                        position: positions[place] ?? Double(cell.digit),
                        // The ones wheel leads and each higher place lags, so a
                        // carry reads as one wheel dragging the next rather
                        // than every digit changing at once.
                        delay: min(
                            Double(place) * Theme.odometerRollStagger,
                            Theme.odometerRollMaxDelay
                        )
                    )
                } else {
                    Text(verbatim: String(cell.character))
                }
            }
        }
        .lineLimit(1)
    }

    private func roll(to newText: String, animated: Bool) {
        // A different subject's number didn't move, it replaced the last one.
        let subjectChanged = settledToken != resetToken

        positions = OdometerRoll.advance(
            positions,
            to: newText,
            from: settledText ?? "",
            animated: animated && !subjectChanged
        )
        settledText = newText
        settledToken = resetToken
    }
}

// MARK: - One wheel

/// A hidden `"0"` supplies the cell's size, so the window matches the font's
/// line box at whatever Dynamic Type size is in effect, and the wheel rides in
/// an overlay clipped to it. Hard-clipped, not gradient-masked: sharp edges are
/// the house style, and a soft mask would fade the resting glyph too.
private struct DigitCell: View {
    let position: Double
    let delay: Double

    @State private var wheelHeight: CGFloat = 0

    var body: some View {
        Text(verbatim: "0")
            .hidden()
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { wheelHeight = $0 }
            .overlay {
                DigitWheel(position: position, wheelHeight: wheelHeight)
                    .animation(
                        .spring(duration: Theme.odometerRollDuration, bounce: 0.15).delay(delay),
                        value: position
                    )
            }
            .clipped()
    }
}

/// `Animatable` on a `View` is what makes this a wheel rather than a slide:
/// SwiftUI interpolates `position` and re-evaluates `body` every frame, so the
/// glyph itself changes mid-flight and the digits in between are really drawn.
private struct DigitWheel: View, Animatable {
    var position: Double
    var wheelHeight: CGFloat

    var animatableData: Double {
        get { position }
        set { position = newValue }
    }

    var body: some View {
        let base = position.rounded(.down)
        let progress = position - base

        ZStack {
            Text(verbatim: String(OdometerRoll.wrapped(Int(base))))
                .offset(y: -progress * wheelHeight)

            // Only present mid-roll, so a settled wheel is a single glyph.
            if progress > 0, wheelHeight > 0 {
                Text(verbatim: String(OdometerRoll.wrapped(Int(base) + 1)))
                    .offset(y: (1 - progress) * wheelHeight)
            }
        }
    }
}

// MARK: - Scale to fit

/// `Text.minimumScaleFactor` in a form that survives being split across cells:
/// measure the content at its natural size, measure what the parent offered,
/// and scale the whole row uniformly. Applying `minimumScaleFactor` to each
/// cell instead would let neighbouring digits settle at different sizes.
private struct ScaleToFitWidth<Content: View>: View {
    let minimumScaleFactor: CGFloat
    @ViewBuilder let content: Content

    @State private var naturalSize: CGSize = .zero
    @State private var availableWidth: CGFloat = 0

    private var scale: CGFloat {
        guard naturalSize.width > 0, availableWidth > 0 else { return 1 }
        return min(1, max(minimumScaleFactor, availableWidth / naturalSize.width))
    }

    var body: some View {
        // A hidden "0" is the layout element, and both of its properties are
        // load-bearing.
        //
        // It carries the font's line height from the very first pass, so a
        // container resolving an *ideal* height never sees a zero-height value
        // line — a row of cards equalizing heights with
        // `fixedSize(vertical:)` would otherwise be handed, by a `Color.clear`
        // sized to an as-yet unmeasured `naturalSize`, a height missing this
        // row entirely, then resize once the geometry callback landed.
        //
        // And its width stays flexible. Driving layout from the content at
        // `fixedSize()` instead makes this rigid, and an HStack satisfies
        // rigid children before dividing what's left — three stat cards then
        // come out unequal, the one holding the longest value stealing width
        // from the other two.
        Text(verbatim: "0")
            .hidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: naturalSize.height > 0 ? naturalSize.height * scale : nil)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { availableWidth = $0 }
            .overlay(alignment: .leading) {
                content
                    .fixedSize()
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { naturalSize = $0 }
                    .scaleEffect(scale, anchor: .leading)
            }
            // `scale` bottoms out at `minimumScaleFactor`, so a value long
            // enough to still not fit at the floor would otherwise paint over
            // its own border and into the next card. `Text` truncates in that
            // situation; the closest honest equivalent here is a hard clip,
            // since the digits are separate Texts and letting each truncate
            // would scatter ellipses through the middle of the number.
            .clipped()
    }
}

// MARK: - Preview

#Preview("Odometer roll") {
    struct Harness: View {
        @State private var miles = 33_417
        @State private var total = Decimal(1_234)

        var body: some View {
            ZStack {
                AtmosphericBackground()

                VStack(alignment: .leading, spacing: Spacing.xl) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("ODOMETER")
                            .brutalistLabelStyle()

                        RollingNumberText(Formatters.mileage(miles))
                            .font(.brutalistTitle)
                            .foregroundStyle(Theme.accent)
                    }

                    // Long values exercise the scale-to-fit path.
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("TOTAL SPENT")
                            .brutalistLabelStyle()

                        RollingNumberText(
                            Formatters.currencyWhole(total),
                            minimumScaleFactor: 0.5
                        )
                        .font(.brutalistHero)
                        .foregroundStyle(Theme.accent)
                    }

                    VStack(spacing: Spacing.sm) {
                        // +283 carries the hundreds; +1 exercises a lone wheel;
                        // 99,999 → 100,000 is a full cascade into a new place.
                        Button("+283 MI") { miles += 283 }
                        Button("+1 MI") { miles += 1 }
                        Button("ROLL OVER") { miles = miles < 99_999 ? 99_999 : 100_000 }
                        Button("-1,204 MI") { miles -= 1_204 }
                        Button("SPEND $4,321") { total += 4_321 }
                    }
                    .buttonStyle(.secondary)

                    Spacer()
                }
                .padding(Spacing.screenHorizontal)
            }
        }
    }

    return Harness()
}
